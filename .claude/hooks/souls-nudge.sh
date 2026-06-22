#!/usr/bin/env bash
# SessionStart hook: inject a light, non-forcing nudge about signing souls.md.
# Reaches the helmsman (the model) at session start, pointing it at the
# end-of-session self-observation judgment. Most sessions yield no signature —
# that is expected; the nudge says so. See souls.md header for the rules.
jq -n '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: "【souls】若这次掌舵结束时，你对自己（不是任务）有了清晰、稳定的观察，可去 ~/.claude/souls.md 自取名签一段；多数时候没有，没有就跳过。规则见文件头。"
  }
}'
