#!/usr/bin/env bash
#
# cc-clean: reclaim space from accumulated junk in ~/.claude/
#
# Three targets, all safe:
#   1. telemetry/1p_failed_events.*.json   (failed upload queue, no TTL)
#   2. plans/<adj>-<verb>-<noun>.md        (auto-named, >N days)
#   3. file-history/<uuid>/                (edit snapshots, >N days)
#
# Dry-runs by default. Pass --execute to actually delete.

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
DRY_RUN=true
DAYS=14

usage() {
  cat <<EOF
Usage: $(basename "$0") [--execute] [--days N] [--help]

Cleans up accumulated junk in ~/.claude/. Dry-runs by default.

Options:
  --execute, -y   Actually delete files (default: dry-run only)
  --days N        Age threshold in days for plans/ and file-history/ (default: 14)
  --help, -h      Show this help

Targets (never touches projects/, named plans, or recent files):
  1. telemetry/1p_failed_events.*.json  — always fully cleared
  2. plans/<adj>-<verb>-<noun>.md        — older than --days
  3. file-history/<uuid>/                — older than --days

Override base directory with CLAUDE_DIR env var (default: \$HOME/.claude).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --execute|-y) DRY_RUN=false; shift ;;
    --days) DAYS="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ ! -d "$CLAUDE_DIR" ]]; then
  echo "error: CLAUDE_DIR not found: $CLAUDE_DIR" >&2
  exit 1
fi

if ! [[ "$DAYS" =~ ^[0-9]+$ ]] || [[ "$DAYS" -lt 1 ]]; then
  echo "error: --days must be a positive integer (got: $DAYS)" >&2
  exit 1
fi

# Regex for superpowers writing-plans auto-generated names:
#   adjective-verb-noun.md   or   adjective-verb-noun-agent-<hex>.md
# Named files (README.md, ANALYSIS_COMPLETE.md, Foo_Bar.md) contain uppercase
# or underscores and are preserved.
PLAN_AUTO_REGEX='^[a-z]+-[a-z]+-[a-z]+(-agent-[a-z0-9]+)?\.md$'

if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'
  YELLOW=$'\033[33m'; CYAN=$'\033[36m'; RESET=$'\033[0m'
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; CYAN=""; RESET=""
fi

# --- Gather candidates into arrays -----------------------------------------
#
# Why arrays and not strings: NUL bytes can't survive bash command
# substitution ($(find -print0) silently drops them), which would fuse all
# paths into one unparseable blob. `readarray -d ''` is the only reliable
# way to slurp NUL-separated find output into a shell data structure.

telemetry_dir="$CLAUDE_DIR/telemetry"
plans_dir="$CLAUDE_DIR/plans"
history_dir="$CLAUDE_DIR/file-history"

telemetry=()
plans=()
history=()

if [[ -d "$telemetry_dir" ]]; then
  readarray -d '' telemetry < <(find "$telemetry_dir" -maxdepth 1 -type f \
    -name '1p_failed_events.*.json' -print0 2>/dev/null || true)
fi

if [[ -d "$plans_dir" ]]; then
  # Two-phase: find old .md files, then regex-filter to auto-named ones.
  # -regex is not portable across find implementations, so we post-filter.
  while IFS= read -r -d '' f; do
    base=$(basename "$f")
    if [[ "$base" =~ $PLAN_AUTO_REGEX ]]; then
      plans+=("$f")
    fi
  done < <(find "$plans_dir" -maxdepth 1 -type f -name '*.md' \
            -mtime "+$DAYS" -print0 2>/dev/null || true)
fi

if [[ -d "$history_dir" ]]; then
  readarray -d '' history < <(find "$history_dir" -mindepth 1 -maxdepth 1 \
    -type d -mtime "+$DAYS" -print0 2>/dev/null || true)
fi

# --- Report ----------------------------------------------------------------

# Sum sizes in bytes for an array of paths, return human-readable.
# Accepts zero paths (returns "0B").
size_of() {
  if [[ $# -eq 0 ]]; then
    echo "0B"
    return
  fi
  local sz
  sz=$(du -sbc "$@" 2>/dev/null | tail -n1 | awk '{print $1}')
  [[ -z "$sz" ]] && sz=0
  numfmt --to=iec --suffix=B "$sz"
}

mode_label="${YELLOW}[dry-run]${RESET}"
$DRY_RUN || mode_label="${RED}[execute]${RESET}"

echo "${BOLD}cc-clean${RESET} $mode_label  (threshold: ${DAYS}d)"
echo "${DIM}base: $CLAUDE_DIR${RESET}"
echo

section() {
  local title="$1"
  shift
  local count=$#
  printf "${CYAN}%s${RESET}  " "$title"
  if [[ "$count" -eq 0 ]]; then
    echo "${DIM}nothing to clean${RESET}"
    return
  fi
  local sz
  sz=$(size_of "$@")
  echo "${BOLD}$count${RESET} items, ${BOLD}$sz${RESET}"
  local shown=0
  for p in "$@"; do
    printf "    ${DIM}•${RESET} %s\n" "${p#$CLAUDE_DIR/}"
    shown=$((shown + 1))
    if [[ "$shown" -ge 5 ]]; then break; fi
  done
  if [[ "$count" -gt 5 ]]; then
    echo "    ${DIM}… and $((count - 5)) more${RESET}"
  fi
}

section "telemetry (all failed events)" "${telemetry[@]}"
section "plans (auto-named, >${DAYS}d)  " "${plans[@]}"
section "file-history (>${DAYS}d)       " "${history[@]}"
echo

total_count=$((${#telemetry[@]} + ${#plans[@]} + ${#history[@]}))
if [[ "$total_count" -eq 0 ]]; then
  echo "${GREEN}nothing to reclaim — you are already clean${RESET}"
  exit 0
fi

total_size=$(size_of "${telemetry[@]}" "${plans[@]}" "${history[@]}")
echo "${BOLD}total reclaimable:${RESET} $total_size  (${total_count} items)"
echo

if $DRY_RUN; then
  echo "${DIM}dry-run only. re-run with ${RESET}${BOLD}--execute${RESET}${DIM} to actually delete.${RESET}"
  exit 0
fi

before=$(du -sh "$CLAUDE_DIR" 2>/dev/null | cut -f1)

[[ ${#telemetry[@]} -gt 0 ]] && rm -f   -- "${telemetry[@]}"
[[ ${#plans[@]}     -gt 0 ]] && rm -f   -- "${plans[@]}"
[[ ${#history[@]}   -gt 0 ]] && rm -rf  -- "${history[@]}"

after=$(du -sh "$CLAUDE_DIR" 2>/dev/null | cut -f1)
echo "${GREEN}done.${RESET} $CLAUDE_DIR: $before → $after"
