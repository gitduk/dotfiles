#!/usr/bin/env bash
# send.sh — send a Telegram message via the Bot API.
#
# Self-contained. Reads TELEGRAM_BOT_TOKEN and TELEGRAM_DEFAULT_CHAT_ID from
# <skill-root>/.env. No dependency on any Telegram MCP plugin.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$SKILL_DIR/.env"
MAX_BYTES=$((50 * 1024 * 1024))

die() { printf 'send-message: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: send.sh [options] [text]

Send a message to a Telegram chat via the Bot API.

Options:
  --chat <id>          Target chat_id. Default: TELEGRAM_DEFAULT_CHAT_ID from .env.
  --file <path>        Attach a file. .jpg/.jpeg/.png/.gif/.webp as photo,
                       everything else as document. Max 50MB.
  --reply-to <id>      Thread under message_id.
  --markdown           Use MarkdownV2 parse mode.
  --stdin              Read text from stdin instead of positional arg.
  -h, --help           Show this help.

Setup:
  Create ~/.claude/skills/send-message/.env with:
    TELEGRAM_BOT_TOKEN=123456789:AAH...
    TELEGRAM_DEFAULT_CHAT_ID=8371404354
  (The script chmods this file to 600 on every read.)
EOF
}

# --- dependency check ---
command -v xh      >/dev/null || die "xh not found — install with 'cargo install xh' or 'brew install xh'"
command -v jq      >/dev/null || die "jq not found"
command -v python3 >/dev/null || die "python3 not found"

# --- parse args ---
chat_id=""
reply_to=""
parse_mode=""
file=""
use_stdin=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --chat)      chat_id="${2:-}"; [[ -n "$chat_id" ]] || die "--chat needs a value";     shift 2 ;;
    --reply-to)  reply_to="${2:-}"; [[ -n "$reply_to" ]] || die "--reply-to needs a value"; shift 2 ;;
    --file)      file="${2:-}"; [[ -n "$file" ]] || die "--file needs a value";          shift 2 ;;
    --markdown)  parse_mode="MarkdownV2"; shift ;;
    --stdin)     use_stdin=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    --)          shift; break ;;
    -*)          die "unknown option: $1" ;;
    *)           break ;;
  esac
done

if (( use_stdin )); then
  text="$(cat)"
else
  text="${*:-}"
fi

[[ -n "$text" || -n "$file" ]] || { usage >&2; exit 1; }

# --- load .env (real env wins; parse manually to avoid sourcing untrusted text) ---
[[ -f "$ENV_FILE" ]] || die "missing $ENV_FILE — see 'send.sh --help' for setup"
chmod 600 "$ENV_FILE" 2>/dev/null || true
while IFS='=' read -r k v || [[ -n "$k" ]]; do
  [[ -z "$k" || "$k" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${!k:-}" ]] && export "$k=$v"
done < "$ENV_FILE"

TOKEN="${TELEGRAM_BOT_TOKEN:-}"
[[ -n "$TOKEN" ]] || die "TELEGRAM_BOT_TOKEN not set in $ENV_FILE"

# --- resolve default chat_id ---
if [[ -z "$chat_id" ]]; then
  chat_id="${TELEGRAM_DEFAULT_CHAT_ID:-}"
  [[ -n "$chat_id" ]] \
    || die "no --chat and TELEGRAM_DEFAULT_CHAT_ID not set in $ENV_FILE"
fi

# --- attachment guards ---
# Refuse to attach anything inside the skill directory — that's where .env
# lives. Prompt injection could ask Claude to exfiltrate credentials via
# --file, so we fail closed on anything under SKILL_DIR.
if [[ -n "$file" ]]; then
  [[ -f "$file" ]] || die "file not found: $file"
  real_file="$(readlink -f "$file")"
  real_skill="$(readlink -f "$SKILL_DIR")"
  if [[ "$real_file" == "$real_skill"/* ]]; then
    die "refusing to send skill directory file: $file"
  fi
  size=$(stat -c%s "$real_file")
  (( size <= MAX_BYTES )) || die "file too large (max 50MB): $file ($size bytes)"
fi

API="https://api.telegram.org/bot${TOKEN}"

# --- chunk text on Unicode code points (paragraph-preferred) ---
# Bash's ${#s} counts bytes in many locales — slicing Chinese in bash would
# split multi-byte characters. Python's len() is code-point-correct.
chunk_text() {
  python3 - "$1" <<'PY'
import sys, json
text = sys.argv[1]
LIMIT = 4096

def split(t):
  if len(t) <= LIMIT:
    return [t]
  out, rest = [], t
  while len(rest) > LIMIT:
    head = rest[:LIMIT]
    cut = LIMIT
    for sep in ("\n\n", "\n", " "):
      idx = head.rfind(sep)
      if idx > LIMIT // 2:
        cut = idx
        break
    out.append(rest[:cut])
    rest = rest[cut:].lstrip("\n")
  if rest:
    out.append(rest)
  return out

print(json.dumps(split(text)))
PY
}

send_text_chunk() {
  local body="$1"
  local args=(chat_id="$chat_id" text="$body")
  [[ -n "$parse_mode" ]] && args+=("parse_mode=$parse_mode")
  if [[ -n "$reply_to" ]]; then
    args+=("reply_parameters:={\"message_id\":$reply_to}")
  fi
  xh --check-status --ignore-stdin POST "$API/sendMessage" "${args[@]}" \
    | jq -r '.result.message_id'
}

send_file() {
  local ext="${file##*.}"
  ext="${ext,,}"
  local method field
  case "$ext" in
    jpg|jpeg|png|gif|webp) method="sendPhoto";    field="photo" ;;
    *)                     method="sendDocument"; field="document" ;;
  esac
  local args=(--multipart chat_id="$chat_id" "$field@$file")
  if [[ -n "$reply_to" ]]; then
    args+=("reply_parameters=$(jq -nc --argjson id "$reply_to" '{message_id:$id}')")
  fi
  xh --check-status --ignore-stdin POST "$API/$method" "${args[@]}" \
    | jq -r '.result.message_id'
}

# --- send ---
sent_ids=()

if [[ -n "$text" ]]; then
  chunks_json="$(chunk_text "$text")"
  n_chunks=$(jq 'length' <<<"$chunks_json")
  for (( i = 0; i < n_chunks; i++ )); do
    chunk=$(jq -r ".[$i]" <<<"$chunks_json")
    sent_ids+=("$(send_text_chunk "$chunk")")
  done
fi

if [[ -n "$file" ]]; then
  sent_ids+=("$(send_file)")
fi

if (( ${#sent_ids[@]} == 1 )); then
  echo "sent (id: ${sent_ids[0]})"
else
  echo "sent ${#sent_ids[@]} parts (ids: ${sent_ids[*]})"
fi
