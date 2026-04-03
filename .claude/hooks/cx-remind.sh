#!/usr/bin/env bash
# cx-remind-version: 2
# cx navigation reminders — handles two hook events:
#   SubagentStart  — inject cx rules into subagent context at startup
#   PreToolUse     — soft-remind main session when using Read/Grep/Glob

if ! command -v jq &>/dev/null || ! command -v cx &>/dev/null; then
  exit 0
fi

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')

case "$EVENT" in

  SubagentStart)
    AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty')
    case "$AGENT_TYPE" in
      Explore|"general-purpose"|Plan|"") ;;
      *) exit 0 ;;
    esac
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "SubagentStart",
        "additionalContext": "TOOL USAGE RULE: cx is available in this environment. You MUST prefer cx over Read/Grep/Glob for source code navigation. Escalation hierarchy: (1) cx overview <file> to understand structure (~200 tokens); (2) cx symbols [--kind K] [--name GLOB] to find symbols across project; (3) cx definition --name <name> to read a specific function/type body; (4) cx references --name <name> to find all usages. Only fall back to Read when you need the full file or context beyond a symbol body. Never use Grep to search for symbol definitions or usages — use cx symbols / cx references instead."
      }
    }'
    ;;

  PreToolUse)
    TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
    case "$TOOL" in
      Read)
        FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
        case "$FILE" in
          *.rs|*.py|*.ts|*.tsx|*.js|*.jsx|*.go|*.c|*.cpp|*.h|*.java|*.rb|*.swift|*.kt)
            MSG="[cx-remind] You are using Read on a source file. Prefer cx escalation hierarchy: cx overview $FILE first (~200 tokens), then cx definition --name <symbol> for specific symbols. Fall back to Read only when you need the full file or surrounding context."
            ;;
          *) exit 0 ;;
        esac
        ;;
      Grep)
        PATTERN=$(echo "$INPUT" | jq -r '.tool_input.pattern // empty')
        MSG="[cx-remind] You are using Grep to search: \"$PATTERN\". Prefer cx: use \`cx symbols --name \"<glob>\"\` to find symbols, or \`cx references --name <name>\` to find usages. Grep is fine for non-symbol text searches."
        ;;
      Glob)
        MSG="[cx-remind] You are using Glob. If you are looking for where a symbol/function is defined, prefer \`cx symbols\` instead. Glob is fine for file discovery."
        ;;
      *) exit 0 ;;
    esac
    jq -n \
      --arg msg "$MSG" \
      '{
        "hookSpecificOutput": {
          "hookEventName": "PreToolUse",
          "additionalContext": $msg
        }
      }'
    ;;

esac
