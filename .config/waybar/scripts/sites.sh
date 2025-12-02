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

# Configuration
MAX_RETRIES=3
TIMEOUT=3

# Temp dir for parallel results
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

check_site() {
  local index=$1
  local name=$2
  local url=$3
  
  local attempt=1
  local success=false
  local response=""
  local exit_code=0
  
  # Retry loop
  while [ $attempt -le $MAX_RETRIES ]; do
    # Check latency with curl
    response=$(curl -o /dev/null -s -w '%{time_total}' --max-time $TIMEOUT "$url" 2>/dev/null)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
      # Success - calculate milliseconds
      local ms=$(echo "$response" | awk '{printf "%.0f", $1 * 1000}')
      
      # Save results
      echo -n "${ms}ms" > "$TMP_DIR/$index.out"
      if [ $attempt -gt 1 ]; then
        printf "%-8s: %s (attempt %d/%d)" "$name" "${ms}ms" "$attempt" "$MAX_RETRIES" > "$TMP_DIR/$index.tip"
      else
        printf "%-8s: %s" "$name" "${ms}ms" > "$TMP_DIR/$index.tip"
      fi
      echo "up" > "$TMP_DIR/$index.status"
      success=true
      break
    else
      # Failed - check if we should retry
      if [ $attempt -lt $MAX_RETRIES ]; then
        # Wait a bit before retrying (exponential backoff)
        sleep $(echo "0.5 * $attempt" | bc 2>/dev/null || echo "0.5")
      fi
      ((attempt++))
    fi
  done
  
  # All retries failed
  if [ "$success" = false ]; then
    echo -n "-1ms" > "$TMP_DIR/$index.out"
    printf "%-8s: %s (failed after %d attempts)" "$name" "DOWN" "$MAX_RETRIES" > "$TMP_DIR/$index.tip"
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
  # Append tooltip
  if [ -f "$TMP_DIR/$i.tip" ]; then
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
printf '{"text": "󰭩 %s", "tooltip": "%s", "class": "%s"}\n' \
  "$OUTPUT_TEXT$1" \
  "$TOOLTIP_TEXT\r\rUpdate Time: $(date +%T)" \
  "$CLASS"
