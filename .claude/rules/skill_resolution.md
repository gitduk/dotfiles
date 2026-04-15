# Skill Resolution

Do not assume a skill exists from the task name alone. Check the current session's available skills first. If no matching skill is installed, use Claude Code's native workflow or tools directly.

**Why:** Guessing skill names creates false starts, noisy errors, and wrong mental models about what capabilities are actually installed.

**How to apply:** Before invoking a skill for an action like commit, review, or deploy, confirm it appears in the available skills list for the current session. If it does not exist, do not probe by guesswork unless the user explicitly asks to search the skills ecosystem; perform the task with the built-in workflow instead.