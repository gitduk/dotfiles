Check dotfiles repo status. Show:
1. Modified tracked files (staged and unstaged)
2. Any rule files in `~/.claude/rules/` or hook files in `~/.claude/hooks/` not tracked by dotfiles
3. Unpushed commits

Use `git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git` for all git operations.
If there are changes worth committing, suggest a commit with appropriate message.
