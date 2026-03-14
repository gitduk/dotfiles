#!/usr/bin/env bash
# Memory system health check - runs before reflection
# Outputs issues found (if any) or empty string (if healthy)

set -euo pipefail

# Normalize path to handle edge cases: deleted directories, special characters, newlines
if [ ! -d "$PWD" ]; then
  echo "ERROR: Current directory does not exist" >&2
  exit 1
fi

NORMALIZED_PWD=$(cd "$PWD" && pwd -P 2>/dev/null)
if [ -z "$NORMALIZED_PWD" ]; then
  echo "ERROR: Failed to normalize current directory path" >&2
  exit 1
fi

NORMALIZED_PWD=$(echo "$NORMALIZED_PWD" | tr -d '\n\r')
if [[ "$NORMALIZED_PWD" != /* ]]; then
  echo "ERROR: Path is not absolute: $NORMALIZED_PWD" >&2
  exit 1
fi

PROJECT_SLUG=$(echo "$NORMALIZED_PWD" | sed 's|[/.]|-|g; s|^-||')
MEMORY_DIR="$HOME/.claude/projects/-${PROJECT_SLUG}/memory"
RULES_DIR="$HOME/.claude/rules"

LOCK_FILE="$HOME/.claude/hooks/.memory-heal.lock"
exec 201>"$LOCK_FILE"
if ! flock -n 201; then
  echo "ERROR: Another health check in progress" >&2
  exit 1
fi

issues=()

# Validate MEMORY_DIR is within expected location (prevent path traversal)
EXPECTED_PREFIX="$HOME/.claude/projects/"
if [[ "$MEMORY_DIR" != "$EXPECTED_PREFIX"* ]]; then
  echo "SECURITY_ERROR: Invalid memory directory path" >&2
  exit 1
fi

# --- Checks 1, 1.5, 3: Single-pass traversal (merged for I/O efficiency) ---
if [ -d "$MEMORY_DIR" ] && [ ! -L "$MEMORY_DIR" ]; then
  actual=""
  misplaced=""
  file_count=0
  for file in "$MEMORY_DIR"/*.md; do
    [ -f "$file" ] || continue
    [ -L "$file" ] && continue
    basename_file=$(basename "$file")
    [ "$basename_file" = "MEMORY.md" ] && continue

    actual+="$basename_file"$'\n'
    ((file_count++)) || true

    # Check 1.5: type placement
    mem_type=$(sed -n '/^---$/,/^---$/p' "$file" 2>/dev/null | grep "^type:" | awk '{print $2}' | head -1)
    if [ "$mem_type" = "user" ] || [ "$mem_type" = "feedback" ]; then
      misplaced+="$basename_file (type: $mem_type), "
    fi
  done
  actual=$(echo "$actual" | sort)

  # Check 1: Index consistency (subshell to avoid cd side effects)
  if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
    index_issues=$(
      cd "$MEMORY_DIR"

      indexed=$(grep -oP '\[.*?\]\(\K[^)]+' MEMORY.md 2>/dev/null | sort || true)

      # Validate extracted filenames (no path traversal, no symlinks)
      if [ -n "$indexed" ]; then
        while IFS= read -r filename; do
          if [[ "$filename" =~ \.\./|^/ ]]; then
            echo "SECURITY_ERROR: Path traversal detected in MEMORY.md: $filename"
            continue
          fi
          if [ -f "$filename" ] && [ -L "$filename" ]; then
            echo "SECURITY_ERROR: Symlink detected: $filename"
          fi
        done <<< "$indexed"
      fi

      orphans=$(comm -13 <(echo "$indexed") <(echo "$actual") | grep -v '^$' || true)
      if [ -n "$orphans" ]; then
        echo "ORPHAN_FILES: $(echo "$orphans" | tr '\n' ', ' | sed 's/,$//')"
      fi

      phantoms=$(comm -23 <(echo "$indexed") <(echo "$actual") | grep -v '^$' || true)
      if [ -n "$phantoms" ]; then
        echo "PHANTOM_ENTRIES: $(echo "$phantoms" | tr '\n' ', ' | sed 's/,$//')"
      fi
    )
    if [ -n "$index_issues" ]; then
      while IFS= read -r issue; do
        issues+=("$issue")
      done <<< "$index_issues"
    fi
  fi

  # Check 1.5 result: misplaced memory type
  if [ -n "$misplaced" ]; then
    misplaced=${misplaced%, }
    issues+=("MISPLACED_MEMORY: $misplaced should be in ~/.claude/rules/ (cross-project)")
  fi

  # Check 3 result: file count
  if [ "$file_count" -gt 30 ]; then
    issues+=("FILE_BLOAT: $file_count memory files, limit 30")
  fi

  # Check 3: Staleness with 24h cache (avoid find every invocation)
  STALE_CACHE="$HOME/.claude/hooks/.stale-cache-${PROJECT_SLUG}"
  CACHE_TTL=86400
  now=$(date +%s)
  stale_loaded=false
  stale=""
  if [ -f "$STALE_CACHE" ]; then
    cache_time=$(stat -c %Y "$STALE_CACHE" 2>/dev/null || echo 0)
    if [ $((now - cache_time)) -lt $CACHE_TTL ]; then
      stale=$(cat "$STALE_CACHE")
      stale_loaded=true
    fi
  fi
  if [ "$stale_loaded" = false ]; then
    stale=$(find "$MEMORY_DIR" -type f -name "*.md" ! -name "MEMORY.md" -mtime +180 2>/dev/null || true)
    echo "$stale" > "$STALE_CACHE"
  fi
  # Filter out files that no longer exist (cache may be stale)
  if [ -n "$stale" ]; then
    stale_valid=""
    while IFS= read -r f; do
      [ -f "$f" ] && stale_valid+="$f"$'\n'
    done <<< "$stale"
    stale="$stale_valid"
  fi
  if [ -n "$stale" ]; then
    stale_list=$(echo "$stale" | xargs -n1 basename | tr '\n' ', ' | sed 's/,$//')
    issues+=("STALE_FILES: not modified in 180+ days (review for relevance): $stale_list")
  fi
else
  # MEMORY_DIR is symlink or invalid
  if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
    issues+=("SECURITY_ERROR: memory directory is symlink or invalid")
  fi
fi

# --- Check 2: MEMORY.md line count ---
if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
  line_count=$(wc -l < "$MEMORY_DIR/MEMORY.md")
  if [ "$line_count" -gt 120 ]; then
    entry_count=$(grep -c '^- \[' "$MEMORY_DIR/MEMORY.md" || echo 0)
    issues+=("INDEX_BLOAT: MEMORY.md has $line_count lines ($entry_count entries), limit 120")
  fi
fi

# --- Check 4: Orphaned temp files ---
if [ -d "$MEMORY_DIR" ]; then
  # Exclude MEMORY.md.bak - created by repair instructions, may linger briefly
  orphaned_tmp=$(find "$MEMORY_DIR" -type f \( -name "*.tmp" -o -name "*.bak" \) ! -name "MEMORY.md.bak" -mmin +60 2>/dev/null || true)
  if [ -n "$orphaned_tmp" ]; then
    tmp_list=$(echo "$orphaned_tmp" | xargs -n1 basename | tr '\n' ', ' | sed 's/,$//')
    issues+=("ORPHANED_TMP: temp files older than 1 hour (safe to delete): $tmp_list")
  fi
fi

# --- Check 5: Rules file size ---
if [ -d "$RULES_DIR" ]; then
  for file in "$RULES_DIR"/*.md; do
    [ -f "$file" ] || continue
    lines=$(wc -l < "$file")
    if [ "$lines" -gt 30 ]; then
      basename=$(basename "$file")
      issues+=("RULES_OVERSIZE: $basename has $lines lines, limit 30")
    fi
  done
fi

# Output issues (one per line) or empty
if [ ${#issues[@]} -gt 0 ]; then
  printf '%s\n' "${issues[@]}"
fi

