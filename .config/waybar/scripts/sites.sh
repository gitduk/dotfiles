#!/usr/bin/env bash

# Define target sites (Format: name|url)
if [[ ! -f "$HOME/.sites.txt" ]]; then
  cat <<'EOF' > $HOME/.sites.txt
Gemini|https://gemini.google.com
ChatGPT|https://chatgpt.com
Claude|https://claude.ai
EOF
fi
SITES=($(cat $HOME/.sites.txt))

# Temp dir for parallel results
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

check_site() {
  local index=$1
  local name=$2
  local url=$3
  
  # Check latency
  # --max-time 3: Total operation timeout in seconds
  # -o /dev/null: Discard body
  # -s: Silent mode
  # -w: Custom output format (status code and total time)
  # -L: Follow redirects (optional, remove if you want to catch 302 as failure)
  local response
  response=$(curl -o /dev/null -s -w '%{time_total}' --max-time 3 "$url")
  local exit_code=$?
  
  if [ $exit_code -eq 0 ]; then
    # Parse response
    local ms=$(echo "$response" | awk '{printf "%.0f", $1 * 1000}')
    echo -n "${ms}ms" > "$TMP_DIR/$index.out"
    printf "%-8s: %s" "$name" "${ms}ms" > "$TMP_DIR/$index.tip"
    echo "up" > "$TMP_DIR/$index.status"
  else
    # curl command failed (timeout, connection error, etc.)
    echo -n "-1ms" > "$TMP_DIR/$index.out"
    printf "%-8s: %s" "$name" "-1ms" > "$TMP_DIR/$index.tip"
    echo "down" > "$TMP_DIR/$index.status"
  fi
}

# Launch checks in parallel
for i in "${!SITES[@]}"; do
  IFS='|' read -r name url <<< "${SITES[$i]}"
  [[ -z "$name" || -z "$url" ]] && continue
  check_site "$i" "$name" "$url" &
done

# Wait for all background jobs
wait

# Aggregate results in order
OUTPUT_TEXT=""
TOOLTIP_TEXT=""
ALL_UP=true
UP_COUNT=0
TOTAL_COUNT=${#SITES[@]}

for i in "${!SITES[@]}"; do
  # Append tooltip with JSON-safe newline
  if [ -f "$TMP_DIR/$i.tip" ]; then
    # Add separator if not empty
    [ -n "$TOOLTIP_TEXT" ] && TOOLTIP_TEXT+="\r" 
    TOOLTIP_TEXT+="$(cat "$TMP_DIR/$i.tip")"
  fi
  
  # Check status
  if [ -f "$TMP_DIR/$i.status" ]; then
    STATUS=$(cat "$TMP_DIR/$i.status")
    if [ "$STATUS" == "up" ]; then
      ((UP_COUNT++))
    else
      ALL_UP=false
    fi
  fi
done

# Set text to ratio (e.g., 2/3)
OUTPUT_TEXT="${UP_COUNT}/${TOTAL_COUNT}"

# Determine CSS class
CLASS="connected"
if [ "$ALL_UP" = false ]; then
  CLASS="disconnected"
fi

# Output JSON for Waybar
printf '{"text": "󰭩 %s", "tooltip": "%s", "class": "%s"}\n' "$OUTPUT_TEXT$1" "$TOOLTIP_TEXT\n\nUpdate Time: $(date +%T)" "$CLASS"

