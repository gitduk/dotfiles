# Destructive Operations

Look and leap are two commands, never one.

- **Irreversible ops** — the pre-check and the destructive command are separate commands: inspect first with visible output, then act. Never fuse "look" and "leap" into one line.
- **Uncommitted work is unrecoverable** — `git checkout -- <path>`, `git restore`, `git reset --hard`, `git clean`, `git stash drop` look like "undo" but permanently destroy uncommitted working-tree changes, including edits I made this session. Before any of them: run `git status` + `git diff <target>` to see what would be lost; if the target has uncommitted modifications, `git stash push -m "<why>"` first (reversible) or get the user's explicit confirmation — never discard directly.
