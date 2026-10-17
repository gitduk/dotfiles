---
[package]
edition = "2024"

[dependencies]
serde = { version = "1", features = ["derive"] }
serde_json = "1"
---

use serde::Deserialize;
use serde_json::{Value, json};
use std::path::Path;
use std::process::Command;

// Colours as ~/.claude/statusline.sh `section_project` writes them;
// the line counts wear pi's own diff colours instead.
const BLUE: &str = "34";
const CYAN: &str = "36";

// Only the fields this script reads; serde ignores the rest.
#[derive(Deserialize)]
struct Facts {
    root: String,
    tier: String,
    running: bool,
}

// `--no-optional-locks`: this runs every two seconds and must never take the
// index lock out from under a git command the agent is running.
fn git(args: &[&str]) -> Option<String> {
    let out = Command::new("git")
        .arg("--no-optional-locks")
        .args(args)
        .output()
        .ok()?;
    out.status
        .success()
        .then(|| String::from_utf8_lossy(&out.stdout).trim().to_string())
}

// Lines added and removed against HEAD, staged and unstaged alike.
// Binary files report `-` in numstat and are skipped.
fn diff_lines() -> (u64, u64) {
    let stat = git(&["diff", "--numstat", "HEAD"]).unwrap_or_default();
    stat.lines().fold((0, 0), |(a, d), line| {
        let mut cols = line.split('\t');
        let add = cols.next().and_then(|n| n.parse::<u64>().ok()).unwrap_or(0);
        let del = cols.next().and_then(|n| n.parse::<u64>().ok()).unwrap_or(0);
        (a + add, d + del)
    })
}

fn text(text: impl Into<String>, style: Value) -> Value {
    json!({ "text": text.into(), "style": style })
}

// `󰏗 name branch +add/-del`, one item so no separator lands inside it.
fn project(root: &str) -> Value {
    let name = Path::new(root)
        .file_name()
        .map(|n| n.to_string_lossy().into_owned())
        .unwrap_or_default();
    let mut group = vec![text(format!("󰏗 {name}"), json!(BLUE))];
    if let Some(branch) = git(&["branch", "--show-current"]).filter(|b| !b.is_empty()) {
        group.push(text(format!(" {branch}"), json!(CYAN)));
        let (add, del) = diff_lines();
        if add + del > 0 {
            group.push(text(" ", json!("muted")));
        }
        if add > 0 {
            group.push(text(format!("+{add}"), json!("add")));
        }
        if add > 0 && del > 0 {
            group.push(text("/", json!({ "sgr": ["dim"] })));
        }
        if del > 0 {
            group.push(text(format!("-{del}"), json!("del")));
        }
    }
    json!({ "group": group })
}

fn main() {
    let facts: Facts = serde_json::from_reader(std::io::stdin()).expect("facts on stdin");

    let mut left = vec![
        project(&facts.root),
        json!({ "part": "model", "style": "muted" }),
        json!({ "part": "effort", "style": "muted" }),
    ];
    if facts.running {
        left.push(text("working", json!("emphasis")));
    }

    let layout = json!({
        "lines": [
            {
                "left": left,
                "right": [
                    { "part": "update", "style": { "sgr": ["dim", "italic"] } },
                    { "part": "flash", "style": "muted" }
                ],
                "sep": { "text": "  " }
            }
        ],
        "refresh": 2
    });
    println!("{layout}");
}
