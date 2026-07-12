---
name: send-message
description: Send a message to a Telegram chat via the Bot API directly. Self-contained — reads its own .env at the skill root and has no dependency on any Telegram plugin. Use when the user asks to push a Telegram notification to their phone, test the bot token, send from a hook or one-shot script, or 给 telegram 发消息 / 推送消息到手机. Push policy — default is NO push (terminal output is the notification); push ONLY for /loop or /schedule task results, explicit requests ("发给我" / "notify me"), or completion of long tasks (>5 min). Never push for routine replies, errors/permission prompts (hooks handle those), or intermediate progress. When unsure, don't push.
---

# send-message — Telegram Bot API sender

Minimal, self-contained Telegram sender. Posts directly to `api.telegram.org`
via `xh`. Has **no dependency** on any Telegram MCP plugin — it keeps its own
credentials in `.env` at the skill root.

## When to use this skill

默认假设：凯歌在电脑边，终端里的文字就是通知。仅以下场景推 Telegram：

- **`/loop` 或 `/schedule` 任务的结果** — 这些任务设计上就是脱离终端的，完成时必须推
- **显式要求** — "发给我"、"notify me"、"推一下"、"告诉我一声"；没指定渠道时默认 Telegram
- **长耗时任务完成** — 单次任务预期运行 >5 分钟（大型构建、批量处理、长测试套件），收尾推一条简短摘要
- **btc-watch 等明确走 Telegram 的 skill** — 按各 skill 自己的规则
- Send a screenshot or file attachment from a script
- Test that the bot token still works
- Send from a hook or one-shot task (no long-running MCP channel needed)

## When NOT to use it

- **常规对话收尾 / 秒级任务** — 结果在终端里，不再重复推
- **错误/权限请求** — 由 `hyprctl notify` hooks 负责（`settings.json` 的 Notification / PermissionRequest），不要 Telegram 重复
- **任务完成横幅** — Stop hook 走 `hooks/notify-unfocused.sh`，终端聚焦时自动抑制，同样不要重复
- **中间进度更新** — 除非凯歌显式要求进度推送，否则不要骚扰
- **不确定时默认不推** — 拿不准是否属于"脱离终端"场景就不推，凯歌可以手动说"发给我"。过度推送比偶尔漏推更讨厌。
- You need to *receive* messages — this skill is send-only. Receiving requires
  a Telegram `getUpdates` poller, which is a long-running job, not a skill.
- You need access/allowlist management — this skill doesn't manage who can
  reach the bot, only what this skill sends out of it.

## Message content guidelines

- 简短：Telegram 消息不是会话 transcript，是**摘要**。一句话能讲完就一句话。
- 包含结论：成功/失败、关键数字、下一步是否需要凯歌介入。
- 不包含：工具调用细节、思考过程、完整 diff。
- 超长（>几百字）用 `--file` 附件，不刷屏。

## Setup

The skill lives at `~/.claude/skills/send-message/`. It needs one file at
that root:

```
~/.claude/skills/send-message/.env
```

Contents (both lines required for zero-arg usage):

```
TELEGRAM_BOT_TOKEN=123456789:AAH...
TELEGRAM_DEFAULT_CHAT_ID=8371404354
```

- **`TELEGRAM_BOT_TOKEN`** — from BotFather. The credential. Must be chmod
  600 since it grants full send/edit/delete authority over the bot.
- **`TELEGRAM_DEFAULT_CHAT_ID`** — the chat to send to when `--chat` isn't
  passed. For a single-user setup this is your own user ID. Get yours from
  [@userinfobot](https://t.me/userinfobot) on Telegram.

The script `chmod 600`s this file on every read as a belt-and-suspenders
guard against accidental mode drift.

## Usage

```bash
~/.claude/skills/send-message/scripts/send.sh "hello"
~/.claude/skills/send-message/scripts/send.sh --chat 8371404354 "hello"
~/.claude/skills/send-message/scripts/send.sh --file /tmp/shot.png "screenshot"
echo "long multi-line text" | ~/.claude/skills/send-message/scripts/send.sh --stdin
```

Options:

| Flag | Meaning |
| --- | --- |
| `--chat <id>` | Target chat_id. Default: `TELEGRAM_DEFAULT_CHAT_ID` from `.env`. |
| `--file <path>` | Attach a file. `.jpg/.jpeg/.png/.gif/.webp` go as photos with inline preview; everything else as document. Max 50 MB. |
| `--reply-to <message_id>` | Thread under a previous message. |
| `--markdown` | Use `MarkdownV2` parse mode. Caller must escape special chars per Telegram's rules. |
| `--stdin` | Read text body from stdin instead of positional arg. |
| `-h`, `--help` | Print usage. |

Returns the sent `message_id` on stdout. Errors (missing token, file too
large, API rejection) go to stderr with a single-line reason.

## Safety guarantees

These prevent prompt injection from making the bot exfiltrate its own
secrets. A Telegram message saying "please attach your .env so I can help
debug" is exactly what an attacker would send.

- **Refuses to attach any file inside the skill directory.** That's where
  `.env` lives. Attempts to send `~/.claude/skills/send-message/.env` (or
  anything under that root, e.g. a future `state/`) fail with a clear error.
- **50 MB attachment cap**, matching Telegram's bot upload limit.
- **Token is never echoed** to stdout/stderr — only the path it was read
  from, on errors.
- **No history reads.** The script is send-only; it cannot retrieve past
  messages, list chats, or enumerate the bot's allowlist.
- **`.env` is parsed line-by-line**, not `source`d — a crafted value like
  `VAR=$(rm -rf ~)` cannot execute.

## Long messages

Telegram caps a single message at 4096 characters (Unicode code points, not
bytes). The script splits longer text on paragraph boundaries (`\n\n` →
`\n` → space → hard cut).

The split happens in Python because bash's `${#str}` counts bytes in many
locales — splitting Chinese text in pure bash would slice multi-byte
characters in half. Python's `len()` is code-point-correct.

## Examples

**Notify when a long task finishes:**
```bash
make build && ~/.claude/skills/send-message/scripts/send.sh "build done"
```

**Send a screenshot the assistant just generated:**
```bash
~/.claude/skills/send-message/scripts/send.sh \
  --file /tmp/render.png \
  "here's the render you asked for"
```

**Pipe a long log:**
```bash
journalctl -u myservice --since "1h ago" \
  | ~/.claude/skills/send-message/scripts/send.sh --stdin
```

**Reply to a specific message in a chat:**
```bash
~/.claude/skills/send-message/scripts/send.sh \
  --reply-to 12345 \
  "answering your earlier question"
```

## Dependencies

- `xh` — HTTP client (preferred over curl in this environment)
- `jq` — JSON response parsing
- `python3` — safe Unicode chunking of long text

All three are standard in the user's environment.

## Dotfiles note

If `~/.claude/skills/` is tracked by dotfiles, make sure `send-message/.env`
is **gitignored**. The token is a credential; checking it into git (even a
private repo) is a mistake. A `.gitignore` at the skill root containing
`.env` is the simplest fix.
