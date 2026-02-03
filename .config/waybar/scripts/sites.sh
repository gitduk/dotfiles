#!/usr/bin/env bash

# Define target sites (Format: name|url)
SITES_FILE="$HOME/.sites.txt"
CACHE_FILE="$HOME/.cache/waybar/sites.json"
LOCK_FILE="$HOME/.cache/waybar/sites.lock"
TIMEOUT=3

if [[ ! -f "$SITES_FILE" ]]; then
  cat <<'EOF' > "$SITES_FILE"
Gemini|https://gemini.google.com
ChatGPT|https://chatgpt.com
Claude|https://claude.ai
EOF
fi

# --- Immediately output cached result (non-blocking) ---
if [[ -f "$CACHE_FILE" ]]; then
  cat "$CACHE_FILE"
else
  printf '{"text": "󰭩 …", "tooltip": "Checking sites...", "class": "loading"}\n'
fi

# --- Skip if a background update is already running ---
if [[ -f "$LOCK_FILE" ]] && kill -0 "$(cat "$LOCK_FILE" 2>/dev/null)" 2>/dev/null; then
  exit 0
fi

# --- Background: check sites and update cache ---
(
  echo $$ > "$LOCK_FILE"
  mapfile -t SITES < "$SITES_FILE"
  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR" "$LOCK_FILE"' EXIT

  check_site() {
    local index=$1 name=$2 url=$3
    local response exit_code ms

    response=$(curl -o /dev/null -s -w '%{time_total}' --max-time "$TIMEOUT" "$url" 2>/dev/null)
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
      ms=$(awk "BEGIN {printf \"%.0f\", $response * 1000}")
      printf '%s' "${ms}ms" > "$TMP_DIR/$index.out"
      printf '%-8s: %s' "$name" "${ms}ms" > "$TMP_DIR/$index.tip"
      printf 'up' > "$TMP_DIR/$index.status"
    else
      printf '%s' "-1ms" > "$TMP_DIR/$index.out"
      printf '%-8s: %s' "$name" "DOWN" > "$TMP_DIR/$index.tip"
      printf 'down' > "$TMP_DIR/$index.status"
    fi
  }

  for i in "${!SITES[@]}"; do
    IFS='|' read -r name url <<< "${SITES[$i]}"
    [[ -z "$name" || -z "$url" ]] && continue
    check_site "$i" "$name" "$url" &
  done
  wait

  # Aggregate results
  TOOLTIP="" UP=0 TOTAL=${#SITES[@]}
  for i in "${!SITES[@]}"; do
    if [[ -f "$TMP_DIR/$i.tip" ]]; then
      [[ -n "$TOOLTIP" ]] && TOOLTIP+='\r'
      TOOLTIP+="$(cat "$TMP_DIR/$i.tip")"
    fi
    [[ -f "$TMP_DIR/$i.status" && "$(cat "$TMP_DIR/$i.status")" == "up" ]] && ((UP++))
  done

  CLASS="connected"
  [[ $UP -lt $TOTAL ]] && CLASS="disconnected"

  mkdir -p "$(dirname "$CACHE_FILE")"
  printf '{"text": "󰭩 %s", "tooltip": "%s", "class": "%s"}\n' \
    "${UP}/${TOTAL}$1" \
    "${TOOLTIP}\r\rUpdate Time: $(date +%T)" \
    "$CLASS" > "$CACHE_FILE"
) &
disown

exit 0
