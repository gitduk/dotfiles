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
    #[serde(default)]
    worktree: Option<String>,
    effort: String,
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
fn diff_lines() -> Option<(u64, u64)> {
    let stat = git(&["diff", "--numstat", "HEAD"])?;
    Some(stat.lines().fold((0, 0), |(a, d), line| {
        let mut cols = line.split('\t');
        let add = cols.next().and_then(|n| n.parse::<u64>().ok()).unwrap_or(0);
        let del = cols.next().and_then(|n| n.parse::<u64>().ok()).unwrap_or(0);
        (a + add, d + del)
    }))
}

fn text(text: impl Into<String>, style: Value) -> Value {
    json!({ "text": text.into(), "style": style })
}

// A wide glyph takes two columns; every non-ASCII character counts as wide.
fn glyph_width(c: char) -> usize {
    if c.is_ascii() { 1 } else { 2 }
}

// Keep the checkout identity once, with a bounded label for long names.
fn label(name: &str) -> String {
    let width: usize = name.chars().map(glyph_width).sum();
    if width <= 28 {
        return name.to_string();
    }
    let mut kept = String::new();
    let mut used = 0;
    for c in name.chars() {
        let w = glyph_width(c);
        if used + w > 27 {
            break;
        }
        used += w;
        kept.push(c);
    }
    kept.push('…');
    kept
}

fn project(root: &str, worktree: Option<&str>) -> Value {
    let name = Path::new(root)
        .file_name()
        .map(|n| n.to_string_lossy().into_owned())
        .unwrap_or_default();
    let branch = git(&["branch", "--show-current"]).filter(|b| !b.is_empty());
    let identity = worktree
        .map(|tree| branch.as_deref().unwrap_or(tree))
        .unwrap_or(&name);
    let mut group = vec![text(format!("󰏗 {}", label(identity)), json!(BLUE))];
    if let Some(branch) = &branch {
        if worktree.is_none() && branch != &name {
            group.push(text(format!(" {}", label(branch)), json!(CYAN)));
        }
    }
    if let Some(trees) = git(&["worktree", "list", "--porcelain", "-z"]) {
        let paths: Vec<_> = trees
            .split("\0\0")
            .filter(|record| !record.split('\0').any(|field| field.starts_with("prunable")))
            .filter_map(|record| record.split('\0').next()?.strip_prefix("worktree "))
            .map(Path::new)
            .collect();
        let count = paths.len().saturating_sub(1);
        let here = Path::new(root).canonicalize().unwrap_or_else(|_| root.into());
        let current = paths
            .iter()
            .enumerate()
            .filter(|(_, path)| here.starts_with(path))
            .max_by_key(|(_, path)| path.as_os_str().len())
            .map(|(index, _)| index);
        if count > 0 && let Some(current) = current {
            group.push(text(format!(" ({current}/{count})"), json!(CYAN)));
        }
    }
    // Detached or not, the diff is there to show.
    if let Some((add, del)) = diff_lines() {
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

    let mut model = vec![json!({ "part": "model", "style": "muted" })];
    if facts.effort != "off" {
        model.push(text(" ", json!("muted")));
    }
    model.push(json!({ "part": "effort", "style": "muted" }));

    let mut left = vec![
        project(&facts.root, facts.worktree.as_deref()),
        json!({ "group": model }),
        json!({ "part": "spent", "style": "muted" })
    ];
    // The run that last ended. The transcript keeps no row for these, so the
    // bar is the only place they show once a run is over.
    left.push(json!({ "group": [
        json!({ "part": "cache", "style": "muted" }),
        text("  ", json!("muted")),
        json!({ "part": "ctx", "style": "muted" }),
        text("  ", json!("muted")),
        json!({ "part": "cost", "style": "muted" })
    ] }));
    // What the agent is doing — idle, working, a retry, stopping — whether or
    // not a run is on: the status line it replaced took a row of its own.
    left.push(json!({ "part": "state", "style": "muted" }));
    // Last on the left: a long answer grows into free room and moves nothing.
    left.push(json!({ "group": [
        text("󱐋 ", json!("muted")),
        json!({ "part": "flash", "style": "muted" })
    ] }));

    let layout = json!({
        "lines": [
            {
                "left": left,
                "right": [
                    { "part": "update", "style": { "sgr": ["dim", "italic"] } }
                ],
                "sep": { "text": "  " }
            }
        ],
        "refresh": 1
    });
    println!("{layout}");
}
