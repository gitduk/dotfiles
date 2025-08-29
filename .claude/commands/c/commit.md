---
name: commit
description: "Analyze git diff and generate commit message, then commit changes"
category: git
complexity: intermediate
mcp-servers: []
personas: []
---

# /c:commit - Smart Git Commit with Analysis

## Triggers
- When you need to commit changes with an intelligent commit message
- Analyze staged changes and generate meaningful commit descriptions
- Automate the commit process with context-aware messaging

## Usage
```
/c:commit [--message "custom message"] [--dry-run] [--amend]
```

## Behavioral Flow

1. **Analyze Changes**: 
   - Run `git --work-tree=~ --git-dir=~/.dotfiles.git diff` to get changes
   - Run `git --work-tree=~ --git-dir=~/.dotfiles.git diff --staged` to get staged changes
   - Parse the diff output to understand what changed
   - Categorize changes by type (feat, fix, docs, style, refactor, etc.)

2. **Generate Commit Message**:
   - Follow conventional commit format
   - Create meaningful subject line based on changes
   - Add detailed body if changes are complex
   - Include breaking changes if detected

3. **Execute Commit**:
   - Show generated message for review
   - Execute `git --work-tree=~ --git-dir=~/.dotfiles.git commit -m "generated message"`
   - Provide commit hash and summary

4. Push commit:
   - Execute `git --work-tree=~ --git-dir=~/.dotfiles.git push`


## Implementation

The command should:

1. **Check for staged changes**:
   ```bash
   git --work-tree=~ --git-dir=~/.dotfiles.git diff --cached --name-only
   ```

2. **Analyze the diff**:
   ```bash
   git --work-tree=~ --git-dir=~/.dotfiles.git diff --cached
   ```

3. **Generate commit message** based on:
   - Files changed (frontend, backend, config, docs, etc.)
   - Type of changes (additions, deletions, modifications)
   - Patterns in the changes (new features, bug fixes, refactoring)

4. **Commit format**:
   ```
   <type>(<scope>): <subject>
   
   <body>
   
   <footer>
   ```

## Example Output:
```
🔍 Analyzing staged changes...
📁 Files changed: 3 files
   - .claude/commands/sc/analyze.md (new file)
   - src/utils/parser.js (modified)
   - README.md (modified)

📝 Generated commit message:
feat(commands): add code analysis command with behavioral flow

- Add comprehensive analyze command for code quality assessment
- Update parser utility to handle new analysis patterns  
- Document new command in README

✅ Commit: abc123f feat(commands): add code analysis command
```

## Command Options:
- `--message, -m`: Use custom message instead of generated one
- `--dry-run, -n`: Show what would be committed without executing
- `--amend`: Amend the last commit with staged changes
- `--scope`: Manually specify the scope for conventional commits
