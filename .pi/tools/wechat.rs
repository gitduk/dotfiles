---
[package]
# Bump this script's version whenever it changes.
version = "0.1.6"
edition = "2024"
description = "Connect this session to WeChat when the user requests it.\nThe tool submits messages from the user's phone to this session, including commands.\nEach answer returns to the phone.\n\nThe tool runs in the background until you stop its background command.\nOn first use, the background command provides a QR code for the user to scan.\nThe login persists for later use."

[package.metadata.pi]
background = true

[dependencies]
base64 = "0.22"
pulldown-cmark = { version = "0.13", default-features = false }
qrcode = { version = "0.14", default-features = false }
rand = "0.8"
reqwest = { version = "0.12", default-features = false, features = ["json", "stream", "rustls-tls"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
thiserror = "2"
tokio = { version = "1", features = ["macros", "time", "sync", "net", "io-util", "io-std", "rt"] }
tracing = "0.1"

[dev-dependencies]
tempfile = "3"
---
//! WeChat for pi: a protocol client for the Weixin iLink bot API (HTTP/JSON
//! long-poll), and the tool that bridges a session to it.
//!
//! `client`, `login` and `types` know only the wire; `bridge` owns the saved
//! state and what a message means. Verified against
//! `@tencent-weixin/openclaw-weixin` 2.4.8.
//!
//! A cargo script pi runs as a tool: copy it into `~/.pi/tools/`. Its own
//! tests run with `cargo +nightly test -Zscript --manifest-path wechat.rs`.

use std::process::ExitCode;

use client::Client;
use login::{LoginView, login as login_flow};
use types::{DEFAULT_BASE_URL, Update, text_of};

#[tokio::main(flavor = "current_thread")]
async fn main() -> ExitCode {
    match bridge::run().await {
        Ok(()) => ExitCode::SUCCESS,
        Err(why) => {
            eprintln!("{why}");
            ExitCode::FAILURE
        }
    }
}

mod bridge {
    //! wechat as a pi background command: what the person types on the phone goes up fd 3 as
    //! `input` (or `interrupt` for `/stop`). Once connected it follows, so every
    //! turn on the checkout comes back as `started`, progress, then `reply`, cut into
    //! messages and sent on to the phone — not only the ones the phone opened.
    //! Each question put there goes too, its options numbered; a reply of
    //! numbers only goes up as the `answer` to the latest one shown, one
    //! number or several.

    use std::collections::VecDeque;
    use std::os::fd::FromRawFd;
    use std::path::PathBuf;
    use std::sync::{Mutex, MutexGuard, PoisonError};
    use std::time::Duration;

    use serde_json::{Value, json};
    use tokio::io::{AsyncBufReadExt, AsyncReadExt, AsyncWriteExt, BufReader};
    use tokio::net::unix::OwnedReadHalf;
    use tokio::sync::{Notify, mpsc};

    use crate::markdown::format_markdown;
    use crate::split::split;
    use crate::{Client, Update};

    // No documented limit — a floor we chose, not a published ceiling. Bytes, not
    // chars, since server counting is unspecified and bytes are the smaller CJK budget.
    const MESSAGE_LIMIT: usize = 2000;
    // Between pieces of one reply: a burst is what a rate limiter watches for.
    const PACE: Duration = Duration::from_millis(500);

    // What persists between runs. One peer per login, so the reply address and
    // the context token are single slots.
    #[derive(Debug, Default, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
    struct State {
        token: Option<String>,
        base_url: String,
        peer: Option<String>,
        get_updates_buf: String,
        context_token: Option<String>,
    }

    // Who a reply goes to, read once under the lock.
    #[derive(Clone)]
    struct Target {
        token: String,
        peer: String,
        context_token: Option<String>,
    }

    // The state and where it lives, locked as one so a save sees what the
    // holder of the lock just wrote. Never held across an await.
    struct Kept {
        path: PathBuf,
        state: Mutex<State>,
    }

    impl Kept {
        fn lock(&self) -> MutexGuard<'_, State> {
            self.state.lock().unwrap_or_else(PoisonError::into_inner)
        }

        fn target(&self) -> Option<Target> {
            let s = self.lock();
            Some(Target {
                token: s.token.clone()?,
                peer: s.peer.clone()?,
                context_token: s.context_token.clone(),
            })
        }

        // It carries the session token: written private, then renamed in whole.
        fn save(&self, state: &State) {
            let Ok(body) = serde_json::to_vec_pretty(state) else {
                return;
            };
            let tmp = self.path.with_extension("json.pi-tmp");
            let written = std::fs::write(&tmp, body)
                .and_then(|()| {
                    use std::os::unix::fs::PermissionsExt;
                    std::fs::set_permissions(&tmp, std::fs::Permissions::from_mode(0o600))
                })
                .and_then(|()| std::fs::rename(&tmp, &self.path));
            if let Err(e) = written {
                eprintln!("wechat: the login could not be saved: {e}");
            }
        }
    }

    // The questions up on the checkout, as the phone was shown them. Never
    // held across an await.
    #[derive(Default)]
    struct Asking(Mutex<Vec<Up>>);

    impl Asking {
        fn lock(&self) -> MutexGuard<'_, Vec<Up>> {
            self.0.lock().unwrap_or_else(PoisonError::into_inner)
        }
    }

    // Where a question is with this chat.
    #[derive(Debug, Clone, Copy, PartialEq)]
    enum Stage {
        // Not sent yet: one asked while a turn runs waits for that turn's
        // reply, which it follows on from.
        Held,
        Shown,
        // Its answer went up; pi closes it soon.
        Answered,
    }

    #[derive(Debug, Clone, PartialEq)]
    struct Up {
        id: u64,
        text: String,
        options: Vec<String>,
        stage: Stage,
    }

    impl Up {
        // `{"question": {...}}` as pi tells it.
        fn of(told: &Value) -> Option<Self> {
            let q = told.get("question")?;
            let options = (q.get("options")?.as_array()?.iter())
                .map(|o| o.as_str().map(str::to_string))
                .collect::<Option<_>>()?;
            Some(Self {
                id: q.get("id")?.as_u64()?,
                text: q.get("text")?.as_str()?.to_string(),
                options,
                stage: Stage::Held,
            })
        }

        fn shown(&self) -> String {
            let options = (self.options.iter().enumerate())
                .map(|(i, o)| format!("{}. {o}", i + 1))
                .collect::<Vec<_>>()
                .join("\n");
            let how = "reply with its number, or with several such as 1 3";
            format!("? {}\n\n{options}\n\n({how})", self.text)
        }
    }

    // A line of option numbers only answers the latest question shown and not
    // yet answered, by place; anything else is the person's own words.
    fn picks_of(asking: &Asking, line: &str) -> Option<(u64, Vec<usize>)> {
        let mut up = asking.lock();
        let q = up.iter_mut().rev().find(|q| q.stage == Stage::Shown)?;
        let picks = (line.split(|c: char| c.is_whitespace() || ",，、".contains(c)))
            .filter(|w| !w.is_empty())
            .map(|w| {
                (w.parse::<usize>().ok())
                    .filter(|n| (1..=q.options.len()).contains(n))
                    .map(|n| n - 1)
            })
            .collect::<Option<std::collections::BTreeSet<_>>>()?;
        if picks.is_empty() {
            return None;
        }
        q.stage = Stage::Answered;
        Some((q.id, picks.into_iter().collect()))
    }

    // Questions not yet shown go out, after whatever went before them:
    // marked first so the other task does not send them too, and unmarked
    // again if the send failed, to go with the next.
    async fn show_held(client: &Client, to: &Target, asking: &Asking, pi: &Pi) {
        let held: Vec<Up> = (asking.lock().iter_mut())
            .filter(|q| q.stage == Stage::Held)
            .map(|q| {
                q.stage = Stage::Shown;
                q.clone()
            })
            .collect();
        for q in held {
            if !send(client, to, pi, &q.shown()).await
                && let Some(up) = asking.lock().iter_mut().find(|u| u.id == q.id)
                && up.stage == Stage::Shown
            {
                up.stage = Stage::Held;
            }
        }
    }

    // pi's end of fd 3, written by one task so a plain callback can say things.
    #[derive(Clone)]
    struct Pi(mpsc::UnboundedSender<Value>);

    impl Pi {
        fn say(&self, line: Value) {
            let _ = self.0.send(line);
        }

        fn status(&self, text: &str) {
            self.say(json!({ "status": text }));
        }
    }

    /// Run as pi's background command until the login fails or expires, or pi goes. The error
    /// is what pi reports back to the model when the background command ends.
    pub async fn run() -> Result<(), String> {
        if std::env::var("PI_EVENTS_FD").as_deref() != Ok("3") {
            return Err("wechat runs as a pi tool: there is no fd 3 here".into());
        }
        let mut args = String::new();
        let _ = tokio::io::stdin().read_to_string(&mut args).await;
        let path = state_path().ok_or("wechat: neither PI_HOME nor HOME is set")?;
        if let Some(dir) = path.parent() {
            std::fs::create_dir_all(dir).map_err(|e| format!("wechat: {}: {e}", dir.display()))?;
        }
        let state: State = std::fs::read(&path)
            .ok()
            .and_then(|b| serde_json::from_slice(&b).ok())
            .unwrap_or_default();

        // SAFETY: PI_EVENTS_FD says pi opened fd 3 for this process, and
        // nothing else here takes it.
        let fd3 = unsafe { std::os::unix::net::UnixStream::from_raw_fd(3) };
        fd3.set_nonblocking(true).map_err(|e| e.to_string())?;
        let (read, mut write) = tokio::net::UnixStream::from_std(fd3)
            .map_err(|e| e.to_string())?
            .into_split();
        let (tx, mut rx) = mpsc::unbounded_channel::<Value>();
        tokio::spawn(async move {
            while let Some(line) = rx.recv().await {
                if write
                    .write_all(format!("{line}\n").as_bytes())
                    .await
                    .is_err()
                {
                    return;
                }
            }
        });
        let pi = Pi(tx);

        let logged_in = state.token.is_some();
        pi.say(json!({ "status": if logged_in {
            "connecting to WeChat with the saved login; messages from the phone will arrive here as turns"
        } else {
            "logging in to WeChat: a QR is in this background command for the user to scan; once they do, messages from the phone arrive here as turns"
        }}));
        let mut client = Client::new(base_of(&state));
        let kept = Kept {
            path,
            state: Mutex::new(state),
        };
        if !logged_in {
            login(&mut client, &kept, &pi).await?;
        }
        pi.say(json!({ "status": "connected" }));
        pi.say(json!({ "follow": true }));
        let asking = Asking::default();
        let retry = Notify::new();
        tokio::select! {
            r = poll(&client, &kept, &asking, &pi, &retry) => r,
            () = answer(&client, &kept, &asking, &pi, read, &retry) => Ok(()),
        }
    }

    // Where pi keeps its own files, so a restart resumes without a new scan.
    fn state_path() -> Option<PathBuf> {
        std::env::var_os("PI_HOME")
            .map(PathBuf::from)
            .or_else(|| std::env::var_os("HOME").map(|h| PathBuf::from(h).join(".pi")))
            .map(|root| root.join("wechat.json"))
    }

    fn base_of(state: &State) -> String {
        if state.base_url.is_empty() {
            crate::DEFAULT_BASE_URL.to_string()
        } else {
            state.base_url.clone()
        }
    }

    // QR → confirm → credentials. The QR goes to stderr, read by opening the
    // background command; progress to its status. The model reads neither.
    async fn login(client: &mut Client, kept: &Kept, pi: &Pi) -> Result<(), String> {
        pi.say(json!({ "status": "waiting for the QR to be scanned" }));
        let note = pi.clone();
        let mut view = crate::LoginView {
            show: Box::new(|text: &str| eprintln!("{text}")),
            status: Box::new(move |text: &str| note.status(text)),
        };
        let credentials = crate::login_flow(client, &mut view)
            .await
            .map_err(|e| e.to_string())?;
        let mut s = kept.lock();
        *s = State {
            token: Some(credentials.token),
            base_url: credentials.base_url,
            ..State::default()
        };
        kept.save(&s);
        Ok(())
    }

    // Client-side timeouts are the normal empty result; real errors back off
    // (the reference's 2s/30s rhythm); a stale token ends the background command.
    async fn poll(
        client: &Client,
        kept: &Kept,
        asking: &Asking,
        pi: &Pi,
        retry: &Notify,
    ) -> Result<(), String> {
        let mut failures = 0u32;
        let mut timeout = crate::client::LONG_POLL_TIMEOUT;
        loop {
            let (token, buf) = {
                let s = kept.lock();
                (s.token.clone(), s.get_updates_buf.clone())
            };
            let token = token.ok_or("wechat: no login")?;
            let failed = match client.get_updates(&token, &buf, timeout).await {
                Ok(update) if update.is_stale_token() => {
                    let mut s = kept.lock();
                    s.token = None;
                    kept.save(&s);
                    return Err("the WeChat login expired; call wechat again for a new QR".into());
                }
                Ok(update) if update.is_error() => format!(
                    "ret={} errcode={:?} errmsg={:?}",
                    update.ret, update.errcode, update.errmsg
                ),
                Ok(update) => {
                    failures = 0;
                    if let Some(t) = update.longpolling_timeout_ms.filter(|t| *t > 0) {
                        timeout = Duration::from_millis(t);
                    }
                    let had = kept.target().is_some();
                    if heard(kept, asking, pi, update) {
                        retry.notify_one();
                    }
                    // Someone to send to at last: what was asked before shows
                    // now, since the turn it waits on may never end to bring it.
                    if let Some(to) = kept.target().filter(|_| !had) {
                        show_held(client, &to, asking, pi).await;
                    }
                    continue;
                }
                Err(e) => format!("{e:#}"),
            };
            failures += 1;
            if failures == 3 {
                pi.status(&format!(
                    "wechat getupdates failing — backing off: {failed}"
                ));
            }
            tokio::time::sleep(backoff(&mut failures)).await;
        }
    }

    // Lines go up as input, or as an answer when they only pick options;
    // `/stop` as an interrupt. The reply address moves to whoever spoke
    // last. Saved only when something changed. Returns whether text arrived.
    fn heard(kept: &Kept, asking: &Asking, pi: &Pi, update: Update) -> bool {
        let mut s = kept.lock();
        let before = s.clone();
        let mut received = false;
        if !update.get_updates_buf.is_empty() {
            s.get_updates_buf = update.get_updates_buf;
        }
        for msg in update.msgs {
            if msg.message_type != 1 {
                continue;
            }
            let text = crate::text_of(&msg);
            if text.is_empty() {
                continue;
            }
            received = true;
            if matches!(text.trim_end(), "/stop" | "/esc") {
                pi.say(json!({ "interrupt": true }));
                continue;
            }
            s.peer = Some(msg.from_user_id.clone());
            // Keep the last valid token: a tokenless message must not erase it
            // (the reference stores only when one is present).
            if let Some(token) = &msg.context_token {
                s.context_token = Some(token.clone());
            }
            match picks_of(asking, text.trim()) {
                Some((id, picks)) => pi.say(json!({ "answer": id, "picks": picks })),
                None => pi.say(json!({ "input": text })),
            }
        }
        if *s != before {
            kept.save(&s);
        }
        received
    }

    // 2s between ordinary retries, 30s once three have failed in a row (the
    // reference monitor's numbers); the counter resets on the 30s step.
    fn backoff(failures: &mut u32) -> Duration {
        if *failures >= 3 {
            *failures = 0;
            Duration::from_secs(30)
        } else {
            Duration::from_secs(2)
        }
    }

    fn reply_text(reply: &str, told: &Value) -> String {
        let notice = match told.get("status").and_then(Value::as_str) {
            Some("stopped") => {
                let reason = told
                    .get("reason")
                    .and_then(Value::as_str)
                    .unwrap_or_default();
                if reason.is_empty() {
                    "stopped".to_string()
                } else {
                    format!("stopped: {reason}")
                }
            }
            Some("failed") => {
                let error = told
                    .get("error")
                    .and_then(Value::as_str)
                    .unwrap_or_default();
                if error.is_empty() {
                    match told.get("exit_code").and_then(Value::as_i64) {
                        Some(code) => format!("failed: exit {code}"),
                        None => "failed".to_string(),
                    }
                } else {
                    format!("failed: {error}")
                }
            }
            _ => return reply.to_string(),
        };
        if reply.is_empty() {
            notice
        } else {
            format!("{reply}\n\n{notice}")
        }
    }

    // Typing while a turn the phone opened runs, then its answer, then the
    // questions it left up, in order. Ends when pi does: there is nobody
    // left to bridge to.
    async fn answer(
        client: &Client,
        kept: &Kept,
        asking: &Asking,
        pi: &Pi,
        read: OwnedReadHalf,
        retry: &Notify,
    ) {
        let mut lines = BufReader::new(read).lines();
        let mut tickets = Tickets::default();
        let mut outbox = Outbox::default();
        let mut running = std::collections::BTreeSet::new();
        let mut tick = tokio::time::interval(Duration::from_secs(4));
        tick.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);
        loop {
            let line = tokio::select! {
                line = lines.next_line() => {
                    let Ok(Some(line)) = line else { return };
                    line
                }
                _ = retry.notified() => {
                    outbox.flush(client, kept, pi).await;
                    if running.is_empty() && outbox.pending.is_empty()
                        && let Some(to) = kept.target() {
                        show_held(client, &to, asking, pi).await;
                    }
                    continue;
                }
                _ = tick.tick(), if !running.is_empty() => {
                    if let Some(to) = kept.target() {
                        tickets.typing(client, &to, true).await;
                    }
                    continue;
                }
            };
            let Ok(told) = serde_json::from_str::<Value>(&line) else {
                continue;
            };
            // Kept even with no one to send to yet: it shows once there is.
            let mut shows = false;
            if let Some(up) = Up::of(&told) {
                asking.lock().push(up);
                shows = running.is_empty();
            } else if let Some(id) = told.get("closed").and_then(Value::as_u64) {
                asking.lock().retain(|q| q.id != id);
            }
            // Not taken: it may be answered again, and the person hears why.
            let refused = told.get("refused").and_then(Value::as_u64).map(|id| {
                if let Some(q) = asking.lock().iter_mut().find(|q| q.id == id)
                    && q.stage == Stage::Answered
                {
                    q.stage = Stage::Shown;
                }
                told.get("why")
                    .and_then(Value::as_str)
                    .unwrap_or_default()
                    .to_string()
            });
            let Some(to) = kept.target() else {
                continue;
            };
            if let Some(why) = refused {
                outbox.push(&to, &format!("not taken: {why}"));
            }
            if told.get("queued").and_then(Value::as_bool) == Some(true) {
                outbox.push(&to, "queued: waiting for execution");
            } else if told.get("started").and_then(Value::as_bool) == Some(true) {
                running.insert(told.get("request").and_then(Value::as_u64));
                tickets.typing(client, &to, true).await;
            } else if let Some(reply) = told.get("reply").and_then(Value::as_str) {
                running.remove(&told.get("request").and_then(Value::as_u64));
                if running.is_empty() {
                    tickets.typing(client, &to, false).await;
                }
                outbox.push(&to, &reply_text(reply, &told));
                shows = running.is_empty();
            } else if let Some(progress) = told.get("progress").and_then(Value::as_str) {
                outbox.push(&to, progress);
            }
            if !outbox.blocked {
                outbox.flush(client, kept, pi).await;
            }
            if shows && outbox.pending.is_empty() {
                show_held(client, &to, asking, pi).await;
            }
        }
    }

    struct Pending {
        to: Target,
        pieces: VecDeque<(String, String)>,
    }

    #[derive(Default)]
    struct Outbox {
        pending: VecDeque<Pending>,
        blocked: bool,
    }

    impl Outbox {
        fn push(&mut self, to: &Target, text: &str) {
            let text = format_markdown(text);
            let pieces: VecDeque<_> = split(&text, MESSAGE_LIMIT)
                .into_iter()
                .filter(|p| !p.trim().is_empty())
                .map(|p| (p, crate::client::client_id()))
                .collect();
            if !pieces.is_empty() {
                self.pending.push_back(Pending {
                    to: to.clone(),
                    pieces,
                });
            }
        }

        async fn flush(&mut self, client: &Client, kept: &Kept, pi: &Pi) -> bool {
            self.blocked = false;
            while let Some(pending) = self.pending.front_mut() {
                // A new conversation token can repair a failed send, only for its peer.
                if let Some(to) = kept.target().filter(|to| to.peer == pending.to.peer) {
                    pending.to = to;
                }
                while let Some((text, id)) = pending.pieces.front() {
                    if let Err(e) = deliver(client, &pending.to, text, id).await {
                        self.blocked = true;
                        pi.status(&format!("wechat send failed: {e:#}; unsent messages kept until the next incoming message"));
                        return false;
                    }
                    pending.pieces.pop_front();
                    tokio::time::sleep(PACE).await;
                }
                self.pending.pop_front();
            }
            true
        }
    }

    async fn deliver(
        client: &Client,
        to: &Target,
        text: &str,
        id: &str,
    ) -> crate::client::Result<()> {
        for attempt in 0..3 {
            match client
                .send_text(
                    &to.token,
                    &to.peer,
                    to.context_token.as_deref().unwrap_or_default(),
                    text,
                    id,
                )
                .await
            {
                Ok(()) => return Ok(()),
                Err(e) => match e.retry_after().filter(|_| attempt < 2) {
                    Some(wait) => tokio::time::sleep(wait).await,
                    None => return Err(e),
                },
            }
        }
        unreachable!("the last failed attempt returns its error")
    }

    // Whether it all went: a failure is told to pi, here.
    async fn send(client: &Client, to: &Target, pi: &Pi, reply: &str) -> bool {
        let text = format_markdown(reply);
        if text.trim().is_empty() {
            return true;
        }
        let pieces = split(&text, MESSAGE_LIMIT);
        let total = pieces.len();
        for (i, piece) in pieces.iter().enumerate() {
            if i > 0 {
                tokio::time::sleep(PACE).await;
            }
            let sent = deliver(client, to, piece, &crate::client::client_id()).await;
            // A later piece without the ones before it reads as garbage, so a
            // failed send ends the message rather than skipping a hole.
            if let Err(e) = sent {
                let part = if total > 1 {
                    format!(" (piece {}/{total})", i + 1)
                } else {
                    String::new()
                };
                // Only a reply with no conversation window to ride is fixed by the phone.
                let hint = if to.context_token.is_none() {
                    " — try sending a message from the phone first"
                } else {
                    ""
                };
                pi.status(&format!("wechat send failed{part}: {e:#}{hint}"));
                return false;
            }
        }
        true
    }

    // Typing tickets, one peer's at a time: fetched once, kept until a send
    // with it fails. A peer the server gave none to is remembered as such.
    #[derive(Default)]
    struct Tickets {
        held: Option<(String, Option<String>)>,
    }

    impl Tickets {
        // Best effort: no ticket, no indicator.
        async fn typing(&mut self, client: &Client, to: &Target, on: bool) {
            let known = self.held.as_ref().filter(|(peer, _)| *peer == to.peer);
            let ticket = match known {
                Some((_, ticket)) => ticket.clone(),
                None => {
                    let fetched = fetch_ticket(client, to).await;
                    self.held = Some((to.peer.clone(), fetched.clone()));
                    fetched
                }
            };
            let Some(ticket) = ticket else {
                return;
            };
            let status = if on { 1 } else { 2 };
            if client
                .send_typing(&to.token, &to.peer, &ticket, status)
                .await
                .is_err()
            {
                self.held = None;
            }
        }
    }

    async fn fetch_ticket(client: &Client, to: &Target) -> Option<String> {
        let context_token = to.context_token.as_deref().unwrap_or_default();
        let config = client
            .get_config(&to.token, &to.peer, context_token)
            .await
            .ok()?;
        config.typing_ticket.filter(|t| !t.is_empty())
    }

    #[cfg(test)]
    mod tests {
        use super::*;

        #[test]
        fn outcome_notices_do_not_rewrite_reply_content() {
            for reply in ["", "stopped", "partial\n\n(stopped)", "(failed: timeout)"] {
                for told in [
                    json!({}),
                    json!({"status": "done"}),
                    json!({"status": "done", "exit_code": 0}),
                ] {
                    assert_eq!(reply_text(reply, &told), reply);
                }
                for (told, notice) in [
                    (json!({"status": "stopped"}), "stopped"),
                    (
                        json!({"status": "failed", "error": "connection lost"}),
                        "failed: connection lost",
                    ),
                    (
                        json!({"status": "failed", "exit_code": 3}),
                        "failed: exit 3",
                    ),
                ] {
                    let expected = if reply.is_empty() {
                        notice.to_string()
                    } else {
                        format!("{reply}\n\n{notice}")
                    };
                    assert_eq!(reply_text(reply, &told), expected);
                }
            }
            assert_eq!(
                reply_text("", &json!({"status": "stopped", "reason": "run it again"})),
                "stopped: run it again"
            );
        }

        #[tokio::test]
        async fn queued_notices_are_sent_separately_from_the_final_reply() {
            let (_dir, kept) = kept();
            {
                let mut state = kept.lock();
                state.token = Some("bot".into());
                state.peer = Some("peer".into());
                state.context_token = Some("context".into());
            }
            let (base, requests) = server(vec![(200, json!({"ret": 0})); 3]).await;
            let client = Client::new(base);
            let (tx, _rx) = mpsc::unbounded_channel();
            let (mut host, script) = tokio::net::UnixStream::pair().unwrap();
            for told in [
                json!({"request": 17, "queued": true}),
                json!({"request": 17, "reply": "queued", "status": "done"}),
            ] {
                host.write_all(format!("{told}\n").as_bytes())
                    .await
                    .unwrap();
            }
            drop(host);
            let (read, _write) = script.into_split();
            tokio::time::timeout(
                Duration::from_secs(5),
                answer(
                    &client,
                    &kept,
                    &Asking::default(),
                    &Pi(tx),
                    read,
                    &Notify::new(),
                ),
            )
            .await
            .unwrap();
            let requests = requests.await.unwrap();
            assert_eq!(
                requests[0]["msg"]["item_list"][0]["text_item"]["text"],
                "queued: waiting for execution"
            );
            assert_eq!(
                requests[2]["msg"]["item_list"][0]["text_item"]["text"],
                "queued"
            );
        }

        #[tokio::test]
        async fn failed_pieces_are_kept_and_resume_with_the_same_id_and_fresh_context() {
            let ok = (200, json!({"ret": 0}));
            let failed = (200, json!({"ret": -2, "errmsg": "prepare failed"}));
            let (base, requests) = server(vec![
                ok.clone(),
                failed.clone(),
                failed.clone(),
                failed,
                ok.clone(),
                ok,
            ])
            .await;
            let client = Client::new(base);
            let (_dir, kept) = kept();
            {
                let mut state = kept.lock();
                state.token = Some("bot".into());
                state.peer = Some("peer".into());
                state.context_token = Some("old".into());
            }
            let (tx, mut status) = mpsc::unbounded_channel();
            let pi = Pi(tx);
            let to = kept.target().unwrap();
            let mut outbox = Outbox::default();
            outbox.push(
                &to,
                &format!("{}\n\n{}", "a".repeat(MESSAGE_LIMIT), "b".repeat(20)),
            );
            assert!(!outbox.flush(&client, &kept, &pi).await);
            assert!(outbox.blocked);
            assert_eq!(outbox.pending.front().unwrap().pieces.len(), 1);
            assert!(
                status.try_recv().unwrap()["status"]
                    .as_str()
                    .unwrap()
                    .contains("kept")
            );
            outbox.push(&to, "later answer");
            kept.lock().context_token = Some("fresh".into());
            assert!(outbox.flush(&client, &kept, &pi).await);
            assert!(outbox.pending.is_empty());
            let requests = tokio::time::timeout(Duration::from_secs(5), requests)
                .await
                .unwrap()
                .unwrap();
            assert_eq!(
                requests.len(),
                6,
                "three bounded attempts at the failed piece"
            );
            for at in 2..5 {
                assert_eq!(
                    requests[at]["msg"]["client_id"],
                    requests[1]["msg"]["client_id"]
                );
                assert_eq!(
                    requests[at]["msg"]["item_list"],
                    requests[1]["msg"]["item_list"]
                );
            }
            assert_eq!(requests[4]["msg"]["context_token"], "fresh");
            assert_eq!(
                requests[5]["msg"]["item_list"][0]["text_item"]["text"],
                "later answer"
            );
        }

        async fn server(
            replies: Vec<(u16, Value)>,
        ) -> (String, tokio::task::JoinHandle<Vec<Value>>) {
            use tokio::io::{AsyncReadExt, AsyncWriteExt};
            let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
            let base = format!("http://{}", listener.local_addr().unwrap());
            let task = tokio::spawn(async move {
                let mut requests = Vec::new();
                for (status, reply) in replies {
                    let (mut socket, _) = listener.accept().await.unwrap();
                    let mut raw = Vec::new();
                    let mut buf = [0; 4096];
                    let head = loop {
                        let n = socket.read(&mut buf).await.unwrap();
                        assert!(n > 0);
                        raw.extend_from_slice(&buf[..n]);
                        if let Some(at) = raw.windows(4).position(|s| s == b"\r\n\r\n") {
                            break at + 4;
                        }
                    };
                    let len = String::from_utf8_lossy(&raw[..head])
                        .lines()
                        .find_map(|line| {
                            line.to_ascii_lowercase()
                                .strip_prefix("content-length:")
                                .map(|n| n.trim().parse::<usize>().unwrap())
                        })
                        .unwrap();
                    while raw.len() < head + len {
                        let n = socket.read(&mut buf).await.unwrap();
                        assert!(n > 0);
                        raw.extend_from_slice(&buf[..n]);
                    }
                    requests.push(serde_json::from_slice(&raw[head..head + len]).unwrap());
                    let body = reply.to_string();
                    let response = format!(
                        "HTTP/1.1 {status} Test\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
                        body.len()
                    );
                    socket.write_all(response.as_bytes()).await.unwrap();
                }
                requests
            });
            (base, task)
        }

        #[test]
        fn backoff_rests_after_three_failures() {
            // Callers count the failure first, then ask how long to wait.
            let mut n = 0u32;
            n += 1;
            assert_eq!(backoff(&mut n), Duration::from_secs(2));
            n += 1;
            assert_eq!(backoff(&mut n), Duration::from_secs(2));
            n += 1;
            assert_eq!(backoff(&mut n), Duration::from_secs(30));
            // The counter reset, so the next failure starts over at 2s.
            n += 1;
            assert_eq!(backoff(&mut n), Duration::from_secs(2));
        }

        fn update(msgs: Value, buf: &str) -> Update {
            serde_json::from_value(json!({ "ret": 0, "msgs": msgs, "get_updates_buf": buf }))
                .unwrap()
        }

        fn kept() -> (tempfile::TempDir, Kept) {
            let dir = tempfile::tempdir().unwrap();
            let path = dir.path().join("wechat.json");
            (
                dir,
                Kept {
                    path,
                    state: Mutex::new(State::default()),
                },
            )
        }

        fn msg(text: &str, ctx: Option<&str>) -> Value {
            json!({
                "from_user_id": "u1",
                "message_type": 1,
                "context_token": ctx,
                "item_list": [{ "type": 1, "text_item": { "text": text } }],
            })
        }

        // A person's line goes up as input and moves the reply address; `/stop`
        // goes up as an interrupt; the cursor and the address are saved.
        #[test]
        fn what_the_phone_says_goes_up_and_who_said_it_is_kept() {
            let (_dir, kept) = kept();
            let (tx, mut rx) = mpsc::unbounded_channel();
            heard(
                &kept,
                &Asking::default(),
                &Pi(tx),
                update(
                    json!([msg("why did it fail", Some("c1")), msg("/stop", None)]),
                    "b2",
                ),
            );
            assert_eq!(
                rx.try_recv().unwrap(),
                json!({ "input": "why did it fail" })
            );
            assert_eq!(rx.try_recv().unwrap(), json!({ "interrupt": true }));
            let saved: State = serde_json::from_slice(&std::fs::read(&kept.path).unwrap()).unwrap();
            assert_eq!(
                (
                    saved.peer.as_deref(),
                    saved.context_token.as_deref(),
                    saved.get_updates_buf.as_str()
                ),
                (Some("u1"), Some("c1"), "b2")
            );
        }

        // Numbers only answer the latest question shown, once, one or
        // several; anything else, or a number with nothing shown, is the
        // person's own words.
        #[test]
        fn a_reply_of_numbers_picks_the_latest_questions_options() {
            let asking = Asking::default();
            let told = |id: u64| {
                json!({ "question": {
                    "id": id, "text": "which?", "options": ["a", "b", "c"], "back": false,
                }})
            };
            asking.lock().push(Up::of(&told(3)).unwrap());
            assert_eq!(picks_of(&asking, "2"), None, "not shown yet");
            asking.lock()[0].stage = Stage::Shown;
            assert_eq!(picks_of(&asking, "4"), None);
            assert_eq!(picks_of(&asking, "2 please"), None);
            assert_eq!(picks_of(&asking, "3，1 3"), Some((3, vec![0, 2])));
            assert_eq!(picks_of(&asking, "2"), None, "answered once");
        }

        // A poll that changes nothing leaves the file alone.
        #[test]
        fn an_unchanged_poll_writes_nothing() {
            let (_dir, kept) = kept();
            let (tx, _rx) = mpsc::unbounded_channel();
            heard(&kept, &Asking::default(), &Pi(tx), update(json!([]), ""));
            assert!(!kept.path.exists());
        }

        #[test]
        fn the_saved_login_is_private() {
            use std::os::unix::fs::PermissionsExt;
            let (_dir, kept) = kept();
            kept.save(&State::default());
            let mode = std::fs::metadata(&kept.path).unwrap().permissions().mode();
            assert_eq!(mode & 0o777, 0o600);
        }
    }
}

mod client {
    //! The iLink protocol client: fixed headers, the six endpoints pi uses, and
    //! two long-polls that treat a client timeout as empty, not an error.
    //!
    //! Protocol only — no session, no persistence; `adapter` owns state and
    //! message meaning.

    use std::time::Duration;

    use base64::Engine;
    use base64::engine::general_purpose::STANDARD;
    use reqwest::RequestBuilder;
    use reqwest::header::{CONTENT_TYPE, HeaderMap, HeaderValue};
    use serde_json::{Value, json};

    use crate::types::{
        BOT_TYPE, CHANNEL_VERSION, Config, Credentials, ILINK_APP_CLIENT_VERSION, ILINK_APP_ID,
        QrCode, QrStatus, Update,
    };

    /// How long a long-poll request is allowed to hold before the client treats
    /// it as an empty poll. The server holds up to 35s itself; the reference
    /// client aborts at exactly the same mark.
    pub const LONG_POLL_TIMEOUT: Duration = Duration::from_millis(35_000);
    /// Regular API calls (sendMessage, getUploadUrl).
    pub const API_TIMEOUT: Duration = Duration::from_millis(15_000);
    /// Lightweight calls (getConfig, sendTyping).
    pub const CONFIG_TIMEOUT: Duration = Duration::from_millis(10_000);

    #[derive(Debug, thiserror::Error)]
    pub enum Error {
        #[error("wechat {endpoint}: ret={ret} errmsg={errmsg:?}")]
        Api {
            endpoint: String,
            ret: i64,
            errmsg: Option<String>,
        },
        #[error("wechat {endpoint}: http {status} {body}")]
        Http {
            endpoint: String,
            status: u16,
            body: String,
        },
        #[error("wechat: {0}")]
        Reqwest(#[from] reqwest::Error),
        #[error("wechat: {0}")]
        Json(#[from] serde_json::Error),
        #[error("wechat: the saved token cannot be sent as a header; log in again")]
        BadToken,
    }

    impl Error {
        pub fn retry_after(&self) -> Option<Duration> {
            match self {
                Self::Api { ret: -2, .. } => Some(Duration::from_secs(2)),
                Self::Http { status, .. } if *status == 429 || *status >= 500 => {
                    Some(Duration::from_secs(2))
                }
                Self::Reqwest(e) if e.is_connect() || e.is_timeout() => {
                    Some(Duration::from_secs(2))
                }
                _ => None,
            }
        }
    }

    pub type Result<T> = std::result::Result<T, Error>;

    /// The one request channel. Cloneable — the long-poll task and the bridge
    /// share it — and cheap: `reqwest::Client` pools connections inside.
    #[derive(Clone)]
    pub struct Client {
        http: reqwest::Client,
        base_url: String,
    }

    impl Client {
        pub fn new(base_url: impl Into<String>) -> Self {
            Self {
                http: reqwest::Client::new(),
                base_url: base_url.into(),
            }
        }

        /// Ask for a login QR. `local_tokens` are previously-known bot tokens:
        /// the server uses them to say "already bound" instead of issuing a login.
        pub async fn fetch_qrcode(&self, local_tokens: &[String]) -> Result<QrCode> {
            let body = json!({ "local_token_list": local_tokens });
            let endpoint = format!("ilink/bot/get_bot_qrcode?bot_type={BOT_TYPE}");
            let resp: Value = self.post(&endpoint, None, body, API_TIMEOUT).await?;
            Ok(serde_json::from_value(resp)?)
        }

        /// Long-poll the QR's scan status. A 35s client timeout means "nothing
        /// yet" and reads as `QrStatus::Wait`, never as an error.
        pub async fn poll_qrcode(
            &self,
            qrcode: &str,
            verify_code: Option<&str>,
        ) -> Result<QrStatus> {
            // The query rides a hand-built endpoint, so the values are encoded by
            // hand: a typed code with `&` or `#` in it would rewrite the request.
            let mut endpoint = format!("ilink/bot/get_qrcode_status?qrcode={}", urlencode(qrcode));
            if let Some(code) = verify_code {
                endpoint.push_str(&format!("&verify_code={}", urlencode(code)));
            }
            let raw = match self.get(&endpoint, LONG_POLL_TIMEOUT).await {
                Ok(raw) => raw,
                Err(Error::Reqwest(e)) if e.is_timeout() => {
                    return Ok(QrStatus::Wait);
                }
                Err(e) => return Err(e),
            };
            let v: Value = serde_json::from_str(&raw)?;
            parse_status(v)
        }

        /// Long-poll for inbound messages. A client-side timeout — the server
        /// held past our 35s without news — is the ordinary empty result.
        pub async fn get_updates(
            &self,
            token: &str,
            buf: &str,
            timeout: Duration,
        ) -> Result<Update> {
            let body = json!({
                "get_updates_buf": buf,
                "base_info": base_info(),
            });
            let resp: Value = match self
                .post("ilink/bot/getupdates", Some(token), body, timeout)
                .await
            {
                Ok(v) => v,
                Err(Error::Reqwest(e)) if e.is_timeout() => return Ok(Update::default()),
                Err(e) => return Err(e),
            };
            Ok(serde_json::from_value(resp)?)
        }

        /// Send one text message. `context_token` must be the inbound message's
        /// own token, verbatim, or the reply misses the conversation window.
        pub async fn send_text(
            &self,
            token: &str,
            to: &str,
            context_token: &str,
            text: &str,
            id: &str,
        ) -> Result<()> {
            let body = json!({
                "msg": {
                    "from_user_id": "",
                    "to_user_id": to,
                    "client_id": id,
                    "message_type": 2,
                    "message_state": 2,
                    "item_list": [ { "type": 1, "text_item": { "text": text } } ],
                    "context_token": context_token,
                },
                "base_info": base_info(),
            });
            self.post("ilink/bot/sendmessage", Some(token), body, API_TIMEOUT)
                .await
                .map(|_| ())
        }

        /// The per-user config, currently just the typing ticket. The adapter
        /// caches it per peer and fetches a new one after a failed typing send.
        pub async fn get_config(
            &self,
            token: &str,
            user: &str,
            context_token: &str,
        ) -> Result<Config> {
            let body = json!({
                "ilink_user_id": user,
                "context_token": context_token,
                "base_info": base_info(),
            });
            let resp: Value = self
                .post("ilink/bot/getconfig", Some(token), body, CONFIG_TIMEOUT)
                .await?;
            Ok(serde_json::from_value(resp)?)
        }

        /// Send the "typing…" indicator (or cancel it).
        pub async fn send_typing(
            &self,
            token: &str,
            user: &str,
            ticket: &str,
            status: i64,
        ) -> Result<()> {
            let body = json!({
                "ilink_user_id": user,
                "typing_ticket": ticket,
                "status": status,
                "base_info": base_info(),
            });
            self.post("ilink/bot/sendtyping", Some(token), body, CONFIG_TIMEOUT)
                .await
                .map(|_| ())
        }

        async fn get(&self, endpoint: &str, timeout: Duration) -> Result<String> {
            self.call(self.http.get(self.url(endpoint)), None, endpoint, timeout)
                .await
        }

        async fn post(
            &self,
            endpoint: &str,
            token: Option<&str>,
            body: Value,
            timeout: Duration,
        ) -> Result<Value> {
            let raw = self
                .call(
                    self.http.post(self.url(endpoint)).json(&body),
                    token,
                    endpoint,
                    timeout,
                )
                .await?;
            Ok(serde_json::from_str(&raw)?)
        }

        // The shared send path: headers, timeout, and the non-2xx / non-zero
        // `ret` verdicts. Everything the reference's `apiPostFetch` does.
        async fn call(
            &self,
            mut req: RequestBuilder,
            token: Option<&str>,
            endpoint: &str,
            timeout: Duration,
        ) -> Result<String> {
            req = req.headers(headers(token)?).timeout(timeout);
            let resp = req.send().await?;
            let status = resp.status().as_u16();
            let raw = resp.text().await.unwrap_or_default();
            if !(200..300).contains(&status) {
                return Err(Error::Http {
                    endpoint: endpoint.to_string(),
                    status,
                    body: raw,
                });
            }
            if let Ok(v) = serde_json::from_str::<Value>(&raw)
                && let Some(ret) = v["ret"].as_i64()
                && ret != 0
            {
                return Err(Error::Api {
                    endpoint: endpoint.to_string(),
                    ret,
                    errmsg: v["errmsg"].as_str().map(str::to_string),
                });
            }
            Ok(raw)
        }

        fn url(&self, endpoint: &str) -> String {
            format!("{}/{}", self.base_url.trim_end_matches('/'), endpoint)
        }
    }

    // Percent-encode everything a query value may not carry raw, so `&`, `#`
    // and space in it cannot change what the server reads.
    fn urlencode(value: &str) -> String {
        let mut out = String::with_capacity(value.len());
        for byte in value.bytes() {
            match byte {
                b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'.' | b'_' | b'~' => {
                    out.push(byte as char)
                }
                _ => out.push_str(&format!("%{byte:02X}")),
            }
        }
        out
    }

    fn base_info() -> Value {
        json!({
            "channel_version": CHANNEL_VERSION,
            "bot_agent": "OpenClaw",
        })
    }

    // A fresh random uint32, as its decimal string, base64 — one per request,
    // which is the replay protection the server expects.
    fn wechat_uin() -> String {
        let n = rand::random::<u32>().to_string();
        STANDARD.encode(n.as_bytes())
    }

    // The fixed request headers, mirroring the reference client: the two app
    // headers on every request; the auth trio on POSTs once a token exists.
    fn headers(token: Option<&str>) -> Result<HeaderMap> {
        let mut h = HeaderMap::new();
        h.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
        h.insert(
            "AuthorizationType",
            HeaderValue::from_static("ilink_bot_token"),
        );
        h.insert(
            "X-WECHAT-UIN",
            HeaderValue::from_str(&wechat_uin()).unwrap(),
        );
        h.insert("iLink-App-Id", HeaderValue::from_static(ILINK_APP_ID));
        h.insert(
            "iLink-App-ClientVersion",
            HeaderValue::from(ILINK_APP_CLIENT_VERSION),
        );
        if let Some(token) = token.filter(|t| !t.trim().is_empty()) {
            h.insert(
                reqwest::header::AUTHORIZATION,
                HeaderValue::from_str(&format!("Bearer {token}")).map_err(|_| Error::BadToken)?,
            );
        }
        Ok(h)
    }

    // Parse one `get_qrcode_status` body into a `QrStatus`.
    fn parse_status(v: Value) -> Result<QrStatus> {
        let status = v["status"].as_str().unwrap_or("wait");
        let q = |name: &str| v[name].as_str().map(str::to_string);
        Ok(match status {
            "wait" => QrStatus::Wait,
            "scaned" => QrStatus::Scanned,
            "need_verifycode" => QrStatus::NeedVerifyCode,
            "verify_code_blocked" => QrStatus::VerifyCodeBlocked,
            "expired" => QrStatus::Expired,
            "binded_redirect" => QrStatus::BindedRedirect,
            "scaned_but_redirect" => QrStatus::Redirect {
                host: v["redirect_host"].as_str().unwrap_or_default().to_string(),
            },
            "confirmed" => QrStatus::Confirmed(Credentials {
                token: q("bot_token").unwrap_or_default(),
                base_url: q("baseurl").unwrap_or_else(|| crate::types::DEFAULT_BASE_URL.into()),
                bot_id: q("ilink_bot_id").unwrap_or_default(),
                user_id: q("ilink_user_id").unwrap_or_default(),
            }),
            other => {
                tracing::warn!(target: "pi::wechat", status = other, "unrecognised QR status");
                QrStatus::Wait
            }
        })
    }

    // A client id the server accepts for tracing; shape mirrors the reference
    // (`prefix:timestamp-hex`).
    pub fn client_id() -> String {
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_millis())
            .unwrap_or(0);
        format!("pi-wechat:{now}-{:08x}", rand::random::<u32>())
    }

    #[cfg(test)]
    mod tests {
        use super::*;

        // The token comes from a file anyone can edit: a stray newline in it is
        // an error to report, not a panic that takes the channel down.
        #[test]
        fn a_token_that_cannot_be_a_header_is_an_error() {
            assert!(matches!(headers(Some("abc\ndef")), Err(Error::BadToken)));
            assert!(headers(Some("abc")).is_ok());
            assert!(headers(None).is_ok());
        }
    }
}

mod login {
    //! The QR login state machine, mirroring the reference's `waitForWeixinLogin`.
    //!
    //! Interaction goes through two callbacks, where the QR and progress show.
    //! Nothing here can type a verification code, so the phone asking for one
    //! ends the login honestly instead of hanging.

    use std::time::{Duration, Instant};

    use crate::client::Client;
    use crate::types::{Credentials, QrStatus};

    #[derive(Debug, thiserror::Error)]
    pub enum LoginError {
        #[error("wechat login: {0}")]
        Failed(String),
        #[error("wechat login timed out after {0:?} — call wechat again")]
        Timeout(Duration),
        #[error(
            "wechat login: the phone asked for a verification code, which this build cannot enter \
             (the account has extra verification enabled)"
        )]
        VerifyCodeUnsupported,
        #[error("wechat login: this bot is already bound to another client")]
        AlreadyBound,
    }

    pub type Result<T> = std::result::Result<T, LoginError>;

    /// How a person sees the login. `show` receives what they look up to
    /// scan: the rendered QR, and the link it holds; `status`, one-line progress.
    /// Owned boxes so the flow can run inside a spawned task.
    pub struct LoginView {
        pub show: Box<dyn FnMut(&str) + Send>,
        pub status: Box<dyn FnMut(&str) + Send>,
    }

    /// How long the whole login may take before `Timeout`.
    pub const LOGIN_TIMEOUT: Duration = Duration::from_secs(8 * 60);
    /// A QR may be refreshed this many times after expiring.
    pub const MAX_QR_REFRESH: u32 = 3;
    /// The pause between polls, as in the reference (each poll itself holds up to
    /// 35s server-side).
    pub const POLL_PAUSE: Duration = Duration::from_secs(1);

    /// Run the login until confirmed. `client` may end up on a different host
    /// after an IDC redirect; the returned credentials carry the final base URL.
    pub async fn login(client: &mut Client, view: &mut LoginView) -> Result<Credentials> {
        let mut qrcode = fetch_qrcode(client, view).await?;
        let mut refresh = 0u32;
        let deadline = Instant::now() + LOGIN_TIMEOUT;
        let mut said_scanned = false;

        loop {
            if Instant::now() >= deadline {
                return Err(LoginError::Timeout(LOGIN_TIMEOUT));
            }
            let status = client
                .poll_qrcode(&qrcode.qrcode, None)
                .await
                .map_err(|e| LoginError::Failed(e.to_string()))?;
            match status {
                QrStatus::Wait => {}
                QrStatus::Scanned => {
                    if !said_scanned {
                        (view.status)("scanned — confirm it on the phone");
                        said_scanned = true;
                    }
                }
                QrStatus::NeedVerifyCode => return Err(LoginError::VerifyCodeUnsupported),
                QrStatus::VerifyCodeBlocked => {
                    (view.status)("the verification code was refused; refreshing the QR");
                    qrcode = refresh_qrcode(client, view, &mut refresh).await?;
                    said_scanned = false;
                    continue;
                }
                QrStatus::Expired => {
                    (view.status)("the QR expired; refreshing");
                    qrcode = refresh_qrcode(client, view, &mut refresh).await?;
                    said_scanned = false;
                    continue;
                }
                QrStatus::BindedRedirect => {
                    return Err(LoginError::AlreadyBound);
                }
                QrStatus::Redirect { host } if !host.is_empty() => {
                    // The server names where to go from here; anything that is
                    // not a bare hostname would turn it into a URL it never meant.
                    let plausible = reqwest::Url::parse(&format!("https://{host}"))
                        .is_ok_and(|u| u.host_str() == Some(host.as_str()));
                    if !plausible {
                        (view.status)(&format!(
                            "the server named an implausible redirect host `{host}`; staying put"
                        ));
                        continue;
                    }
                    let base = format!("https://{host}");
                    (view.status)(&format!("redirected to {base}"));
                    *client = Client::new(base);
                }
                QrStatus::Redirect { .. } => {
                    (view.status)("the server asked to redirect but named no host; continuing");
                }
                QrStatus::Confirmed(credentials) => return Ok(credentials),
            }
            tokio::time::sleep(POLL_PAUSE).await;
        }
    }

    /// Render a URL as a text QR the terminal can show, or `None` if the URL is
    /// too large to encode. Equivalent to the reference's `qrcode-terminal`.
    pub fn render_qr(url: &str) -> Option<String> {
        use qrcode::render::unicode;
        let code = qrcode::QrCode::new(url.as_bytes()).ok()?;
        Some(code.render::<unicode::Dense1x2>().build())
    }

    async fn fetch_qrcode(client: &Client, view: &mut LoginView) -> Result<crate::types::QrCode> {
        let qr = client
            .fetch_qrcode(&[])
            .await
            .map_err(|e| LoginError::Failed(e.to_string()))?;
        (view.status)("scan the QR in this background command with WeChat to connect this session");
        if let Some(rendered) = render_qr(&qr.qrcode_img_content) {
            (view.show)(&rendered);
        }
        (view.show)(&format!(
            "if the QR does not render, open: {}",
            qr.qrcode_img_content
        ));
        Ok(qr)
    }

    async fn refresh_qrcode(
        client: &Client,
        view: &mut LoginView,
        refresh: &mut u32,
    ) -> Result<crate::types::QrCode> {
        if *refresh >= MAX_QR_REFRESH {
            return Err(LoginError::Failed(format!(
                "the QR expired {MAX_QR_REFRESH} times — give up and call wechat again"
            )));
        }
        *refresh += 1;
        let qr = client
            .fetch_qrcode(&[])
            .await
            .map_err(|e| LoginError::Failed(e.to_string()))?;
        (view.status)("the QR was refreshed — scan the new one in this background command");
        if let Some(rendered) = render_qr(&qr.qrcode_img_content) {
            (view.show)(&rendered);
        }
        Ok(qr)
    }
}

mod markdown {
    //! Markdown as the phone reads it: WeChat renders none of it, so every
    //! construct the model emits gets reduced to the plainest text that still
    //! says what it said. Nothing here touches the bridge or the socket.

    use pulldown_cmark::{CodeBlockKind, Event as MdEvent, Options, Parser, Tag, TagEnd};

    #[derive(Default)]
    struct TableState {
        headers: Vec<String>,
        rows: Vec<Vec<String>>,
        current_row: Vec<String>,
        current_cell: String,
    }

    struct ListState {
        next_num: Option<u64>,
        depth: usize,
    }

    struct LinkEntry {
        url: String,
        text: String,
    }

    #[derive(Default)]
    struct Formatter {
        out: String,
        link_stack: Vec<LinkEntry>,
        table: Option<TableState>,
        list_stack: Vec<ListState>,
        item_just_started: bool,
        in_heading: bool,
        in_code_block: bool,
        quote_depth: usize,
    }

    impl Formatter {
        fn with_capacity(capacity: usize) -> Self {
            Self {
                out: String::with_capacity(capacity),
                ..Default::default()
            }
        }

        fn push(&mut self, s: &str) {
            if let Some(entry) = self.link_stack.last_mut() {
                entry.text.push_str(s);
            } else if let Some(table) = &mut self.table {
                table.current_cell.push_str(s);
            } else {
                self.out.push_str(s);
            }
        }

        fn ensure_blank_line(&mut self) {
            if !self.out.ends_with('\n') && !self.out.is_empty() {
                self.out.push('\n');
            }
            if !self.out.ends_with("\n\n") && !self.out.is_empty() {
                self.out.push('\n');
            }
        }

        fn ensure_newline(&mut self) {
            if !self.out.ends_with('\n') {
                self.out.push('\n');
            }
        }

        fn render_table(&mut self, table: TableState) {
            let headers: Vec<&str> = table.headers.iter().map(|s| s.trim()).collect();
            let has_headers = headers.iter().any(|h| !h.is_empty());
            let cols = if has_headers {
                headers.len()
            } else {
                table.rows.iter().map(|r| r.len()).max().unwrap_or(0)
            };

            if cols == 0 {
                return;
            }

            self.ensure_blank_line();
            if has_headers {
                self.out.push_str(&format!("【{}】\n", headers.join(" | ")));
            }

            if cols == 2 {
                for row in &table.rows {
                    let c0 = row.first().map(|s| s.as_str()).unwrap_or("");
                    let c1 = row.get(1).map(|s| s.as_str()).unwrap_or("");
                    match (c0.is_empty(), c1.is_empty()) {
                        (false, false) => self.out.push_str(&format!("• {c0}: {c1}\n")),
                        (false, true) => self.out.push_str(&format!("• {c0}\n")),
                        (true, false) => self.out.push_str(&format!("• {c1}\n")),
                        (true, true) => {}
                    }
                }
            } else if cols > 2 {
                for (i, row) in table.rows.iter().enumerate() {
                    if i > 0 {
                        self.out.push('\n');
                    }
                    let mut started = false;
                    for (idx, cell) in row.iter().enumerate() {
                        if cell.is_empty() {
                            continue;
                        }
                        let h = headers.get(idx).copied().unwrap_or("");
                        if !started {
                            if idx == 0 || h.is_empty() {
                                self.out.push_str(&format!("• {cell}\n"));
                            } else {
                                self.out.push_str(&format!("• {h}: {cell}\n"));
                            }
                            started = true;
                        } else if !h.is_empty() {
                            self.out.push_str(&format!("  {h}: {cell}\n"));
                        } else {
                            self.out.push_str(&format!("  {cell}\n"));
                        }
                    }
                }
            } else {
                for row in &table.rows {
                    if let Some(c) = row.first().filter(|s| !s.is_empty()) {
                        self.out.push_str(&format!("• {c}\n"));
                    }
                }
            }
            self.out.push('\n');
        }
    }

    pub(super) fn format_markdown(input: &str) -> String {
        let mut opts = Options::empty();
        opts.insert(Options::ENABLE_TABLES);
        opts.insert(Options::ENABLE_STRIKETHROUGH);
        opts.insert(Options::ENABLE_TASKLISTS);

        let parser = Parser::new_ext(input, opts);
        let mut f = Formatter::with_capacity(input.len());

        for event in parser {
            match event {
                MdEvent::Start(tag) => match tag {
                    Tag::Heading { .. } => {
                        f.in_heading = true;
                        f.ensure_blank_line();
                        f.out.push('【');
                    }
                    Tag::Paragraph => {
                        if f.item_just_started {
                            f.item_just_started = false;
                        } else {
                            f.ensure_blank_line();
                            if f.quote_depth > 0 {
                                f.out.push_str("> ");
                            }
                        }
                    }
                    Tag::BlockQuote(_) => {
                        f.quote_depth += 1;
                    }
                    Tag::CodeBlock(kind) => {
                        f.ensure_blank_line();
                        let lang = match &kind {
                            CodeBlockKind::Fenced(l) => l.trim(),
                            CodeBlockKind::Indented => "",
                        };
                        if !lang.is_empty() {
                            f.out.push_str(&format!("─── 代码 ({lang}) ───\n"));
                        } else {
                            f.out.push_str("─── 代码 ───\n");
                        }
                        f.in_code_block = true;
                    }
                    Tag::List(start_num) => {
                        if f.list_stack.is_empty() {
                            f.ensure_blank_line();
                        }
                        let depth = f.list_stack.len() + 1;
                        f.list_stack.push(ListState {
                            next_num: start_num,
                            depth,
                        });
                    }
                    Tag::Item => {
                        f.item_just_started = true;
                        if let Some(state) = f.list_stack.last_mut() {
                            let indent = "  ".repeat(state.depth.saturating_sub(1));
                            if let Some(num) = state.next_num.as_mut() {
                                f.out.push_str(&format!("{indent}{num}. "));
                                *num += 1;
                            } else {
                                f.out.push_str(&format!("{indent}• "));
                            }
                        }
                    }
                    Tag::Table(_) => {
                        f.table = Some(TableState::default());
                    }
                    Tag::TableHead | Tag::TableRow => {
                        if let Some(t) = &mut f.table {
                            t.current_row.clear();
                        }
                    }
                    Tag::TableCell => {
                        if let Some(t) = &mut f.table {
                            t.current_cell.clear();
                        }
                    }
                    Tag::Emphasis => {}
                    Tag::Strong => {
                        if !f.in_heading {
                            f.push("「");
                        }
                    }
                    Tag::Strikethrough => {
                        f.push("~");
                    }
                    Tag::Link { dest_url, .. } | Tag::Image { dest_url, .. } => {
                        f.link_stack.push(LinkEntry {
                            url: dest_url.to_string(),
                            text: String::new(),
                        });
                    }
                    _ => {}
                },
                MdEvent::End(tag) => match tag {
                    TagEnd::Heading(_) => {
                        f.in_heading = false;
                        f.out.push_str("】\n\n");
                    }
                    TagEnd::Paragraph => {
                        f.ensure_newline();
                    }
                    TagEnd::BlockQuote(_) => {
                        f.quote_depth = f.quote_depth.saturating_sub(1);
                    }
                    TagEnd::CodeBlock => {
                        f.ensure_newline();
                        f.out.push_str("────────\n\n");
                        f.in_code_block = false;
                    }
                    TagEnd::Item => {
                        f.ensure_newline();
                        f.item_just_started = false;
                    }
                    TagEnd::List(_) => {
                        f.list_stack.pop();
                        if f.list_stack.is_empty() {
                            f.ensure_newline();
                        }
                    }
                    TagEnd::TableHead => {
                        if let Some(t) = &mut f.table {
                            t.headers = std::mem::take(&mut t.current_row);
                        }
                    }
                    TagEnd::TableRow => {
                        if let Some(t) = &mut f.table {
                            t.rows.push(std::mem::take(&mut t.current_row));
                        }
                    }
                    TagEnd::TableCell => {
                        if let Some(t) = &mut f.table {
                            let cell = std::mem::take(&mut t.current_cell).trim().to_string();
                            t.current_row.push(cell);
                        }
                    }
                    TagEnd::Table => {
                        if let Some(t) = f.table.take() {
                            f.render_table(t);
                        }
                    }
                    TagEnd::Emphasis => {}
                    TagEnd::Strong => {
                        if !f.in_heading {
                            f.push("」");
                        }
                    }
                    TagEnd::Strikethrough => {
                        f.push("~");
                    }
                    TagEnd::Link => {
                        if let Some(entry) = f.link_stack.pop() {
                            let text = entry.text.trim();
                            let url = entry.url.trim();
                            let formatted = if text.is_empty() || text == url {
                                url.to_string()
                            } else if url.is_empty() {
                                text.to_string()
                            } else {
                                format!("{text} ({url})")
                            };
                            f.push(&formatted);
                        }
                    }
                    TagEnd::Image => {
                        if let Some(entry) = f.link_stack.pop() {
                            let alt = entry.text.trim();
                            let url = entry.url.trim();
                            let formatted = match (alt.is_empty(), url.is_empty()) {
                                (false, false) => format!("[图片: {alt} ({url})]"),
                                (false, true) => format!("[图片: {alt}]"),
                                (true, false) => format!("[图片: {url}]"),
                                (true, true) => "[图片]".to_string(),
                            };
                            f.push(&formatted);
                        }
                    }
                    _ => {}
                },
                MdEvent::Text(t) => {
                    if f.in_code_block {
                        f.out.push_str(&t);
                    } else {
                        f.item_just_started = false;
                        f.push(&t);
                    }
                }
                MdEvent::Code(c) => {
                    f.item_just_started = false;
                    f.push(&format!("`{c}`"));
                }
                MdEvent::SoftBreak => {
                    if f.in_code_block {
                        f.out.push('\n');
                    } else if f.quote_depth > 0 {
                        f.out.push_str("\n> ");
                    } else {
                        f.out.push('\n');
                    }
                }
                MdEvent::HardBreak => {
                    if f.quote_depth > 0 {
                        f.out.push_str("\n> ");
                    } else {
                        f.out.push('\n');
                    }
                }
                MdEvent::Rule => {
                    f.ensure_blank_line();
                    f.out.push_str("────────\n\n");
                }
                MdEvent::TaskListMarker(checked) => {
                    let marker = if checked { "[x] " } else { "[ ] " };
                    f.push(marker);
                }
                _ => {}
            }
        }

        f.out.trim().to_string()
    }
}

mod split {
    //! One reply cut into messages a platform will take: each within a byte
    //! budget, at the most natural boundary in reach, rejoining exactly.

    pub(crate) fn split(text: &str, limit: usize) -> Vec<String> {
        let mut pieces = Vec::new();
        let mut rest = text;
        while !rest.is_empty() {
            if rest.len() <= limit {
                pieces.push(rest.to_string());
                break;
            }
            let (cut, skip) = boundary(rest, limit);
            pieces.push(rest[..cut].to_string());
            rest = &rest[cut + skip..];
        }
        pieces
    }

    // Falls back paragraph → line → space → char boundary, dropping nothing
    // (exact rejoin); the cut is never zero, or the loop would spin forever.
    fn boundary(rest: &str, budget: usize) -> (usize, usize) {
        let first = rest.chars().next().map_or(1, char::len_utf8);
        let mut end = budget.max(first);
        while end > first && !rest.is_char_boundary(end) {
            end -= 1;
        }
        let head = &rest[..end];
        for sep in ["\n\n", "\n", " "] {
            let Some(i) = head.rfind(sep).filter(|&i| i > end / 2) else {
                continue;
            };
            let skip = if sep == " " {
                1
            } else {
                rest[i..]
                    .bytes()
                    .take_while(|b| matches!(b, b'\n' | b'\r'))
                    .count()
            };
            return (i, skip);
        }
        (end, 0)
    }

    #[cfg(test)]
    mod tests {
        use super::*;

        #[test]
        fn a_run_with_no_boundary_is_cut_on_a_character_and_rejoins_exactly() {
            let text = "中".repeat(200);
            let pieces = split(&text, 100);
            assert!(pieces.len() > 1);
            assert_eq!(pieces.concat(), text);
        }

        #[test]
        fn a_budget_shorter_than_one_character_still_advances() {
            let pieces = split("中文中文", 1);
            assert_eq!(pieces.len(), 4);
        }

        #[test]
        fn a_long_reply_breaks_at_a_paragraph() {
            let text = format!("{}\n\n{}", "a".repeat(60), "b".repeat(60));
            assert_eq!(split(&text, 100), ["a".repeat(60), "b".repeat(60)]);
        }
    }
}

mod types {
    //! Wire types for the Weixin iLink bot API (HTTP/JSON long-poll), mirroring
    //! `@tencent-weixin/openclaw-weixin` 2.4.8.
    //!
    //! Unknown fields are ignored by construction (no `deny_unknown_fields`): the
    //! server adds fields between versions, and a decoder that dies on them
    //! breaks the whole long-poll loop.

    use serde::Deserialize;

    /// The fixed API host for QR requests and the default for everything else. A
    /// login may be redirected to another host (`scaned_but_redirect`); the
    /// confirmed response's `baseurl` is what a session then talks to.
    pub const DEFAULT_BASE_URL: &str = "https://ilinkai.weixin.qq.com";

    /// The channel version the server negotiates against, sent verbatim in every
    /// `base_info`. This is a protocol negotiation, not a cosmetic string: it is
    /// the package version of the reference client, and changing it is a claim
    /// about the wire format.
    pub const CHANNEL_VERSION: &str = "2.4.8";

    /// The `iLink-App-Id` every request carries, from the reference package.json.
    pub const ILINK_APP_ID: &str = "bot";

    /// The `iLink-App-ClientVersion` header: the reference package version 2.4.8
    /// encoded as `major<<16 | minor<<8 | patch` (0x00020008 = 132104).
    pub const ILINK_APP_CLIENT_VERSION: u32 = 132_104;

    /// What `get_bot_qrcode` asks for: the bot flavour, 3 per the reference.
    pub const BOT_TYPE: &str = "3";

    /// One login QR code, as issued.
    #[derive(Debug, Clone, Deserialize)]
    pub struct QrCode {
        pub qrcode: String,
        /// The URL the QR encodes; also what a phone can open directly.
        pub qrcode_img_content: String,
    }

    /// What a successful login hands back. `base_url` is the confirmed response's
    /// `baseurl` — the reference uses it for every subsequent request.
    #[derive(Clone)]
    pub struct Credentials {
        pub token: String,
        pub base_url: String,
        pub bot_id: String,
        pub user_id: String,
    }

    // Manual rather than derived: a `{:?}` that prints the session token leaks it
    // through any log line that happens to carry the credentials.
    impl std::fmt::Debug for Credentials {
        fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
            f.debug_struct("Credentials")
                .field("token", &"<redacted>")
                .field("base_url", &self.base_url)
                .field("bot_id", &self.bot_id)
                .field("user_id", &self.user_id)
                .finish()
        }
    }

    /// The result of one `get_qrcode_status` long-poll.
    #[derive(Debug, Clone)]
    pub enum QrStatus {
        // Nothing happened (including a client-side 35s timeout): keep polling.
        Wait,
        // Scanned; WeChat is still waiting for the user to confirm.
        Scanned,
        // The phone shows a verification code that has to be typed in.
        NeedVerifyCode,
        // The code was wrong too many times; a fresh QR is needed.
        VerifyCodeBlocked,
        // The QR has expired; a fresh one is needed.
        Expired,
        // This bot is already bound to another client; no new login possible.
        BindedRedirect,
        // The session is being redirected to another host; resume polling there.
        Redirect { host: String },
        // Login confirmed.
        Confirmed(Credentials),
    }

    /// One message from `getupdates`. Only the fields pi reads are typed; the rest
    /// ride along as ignored serde unknowns.
    #[derive(Debug, Clone, Deserialize)]
    pub struct WireMessage {
        #[serde(default)]
        pub from_user_id: String,
        /// 1 = user sent it, 2 = bot sent it. The loop handles only 1.
        #[serde(default)]
        pub message_type: i64,
        /// Required verbatim on any reply, or the reply misses the conversation.
        #[serde(default)]
        pub context_token: Option<String>,
        #[serde(default)]
        pub item_list: Vec<Item>,
    }

    #[derive(Debug, Clone, Deserialize)]
    pub struct Item {
        /// 1 text, 2 image, 3 voice, 4 file, 5 video.
        #[serde(default)]
        pub r#type: i64,
        #[serde(default)]
        pub text_item: Option<TextItem>,
        /// A voice item may carry a transcription (`text`), which is as close to
        /// text as this client goes.
        #[serde(default)]
        pub voice_item: Option<VoiceItem>,
    }

    #[derive(Debug, Clone, Deserialize)]
    pub struct TextItem {
        pub text: String,
    }

    #[derive(Debug, Clone, Deserialize)]
    pub struct VoiceItem {
        #[serde(default)]
        pub text: Option<String>,
    }

    /// The text a message carries, by priority: the first text item, else a voice
    /// transcription. Media-only messages yield "".
    pub fn text_of(msg: &WireMessage) -> &str {
        for item in &msg.item_list {
            match item.r#type {
                1 => {
                    if let Some(t) = &item.text_item {
                        return &t.text;
                    }
                }
                3 => {
                    if let Some(v) = &item.voice_item
                        && let Some(text) = &v.text
                    {
                        return text;
                    }
                }
                _ => {}
            }
        }
        ""
    }

    /// One `getupdates` response. A client-side long-poll timeout returns an empty
    /// `Update` (ret 0, no messages) rather than an error — that is the normal
    /// no-news case, exactly like the reference client.
    #[derive(Debug, Clone, Default, Deserialize)]
    pub struct Update {
        #[serde(default)]
        pub ret: i64,
        #[serde(default)]
        pub errcode: Option<i64>,
        #[serde(default)]
        pub errmsg: Option<String>,
        #[serde(default)]
        pub msgs: Vec<WireMessage>,
        /// The cursor to send on the next poll; persisted so nothing is re-sent.
        #[serde(default)]
        pub get_updates_buf: String,
        /// The server's suggested hold time for the next poll, when it says one.
        #[serde(default)]
        pub longpolling_timeout_ms: Option<u64>,
    }

    impl Update {
        /// The error code the server uses for a stale/expired bot token.
        pub const STALE_TOKEN: i64 = -14;

        /// Whether the response is an API error (as opposed to a normal empty
        /// long-poll). `ret` and `errcode` are checked independently, as in the
        /// reference monitor.
        pub fn is_error(&self) -> bool {
            self.ret != 0 || self.errcode.is_some_and(|e| e != 0)
        }

        /// Whether the error means the bot token no longer works and a fresh
        /// QR login is required.
        pub fn is_stale_token(&self) -> bool {
            self.ret == Self::STALE_TOKEN || self.errcode == Some(Self::STALE_TOKEN)
        }
    }

    /// What `getconfig` returns that pi uses.
    #[derive(Debug, Clone, Default, Deserialize)]
    pub struct Config {
        #[serde(default)]
        pub typing_ticket: Option<String>,
    }
}
