#!/usr/bin/env bash
# publish.sh — 水墨风排版 + 微信 API 发布封装
# Usage: publish.sh <article.md> --cover <cover.jpg> [--account <alias>]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUBLISH_DIR="$HOME/.agents/skills/baoyu-skills/skills/baoyu-post-to-wechat"
TYPOGRAPHY="$SCRIPT_DIR/fix_typography.py"

MARKDOWN=""
COVER=""
ACCOUNT="default"
THEME="simple"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cover)   COVER="$2";   shift 2 ;;
    --account) ACCOUNT="$2"; shift 2 ;;
    --theme)   THEME="$2";   shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *)  MARKDOWN="$1"; shift ;;
  esac
done

if [[ -z "$MARKDOWN" ]]; then
  echo "Usage: publish.sh <article.md> --cover <cover.jpg> [--account <alias>]" >&2
  exit 1
fi

echo "[publish] Step 1: render markdown → HTML (theme: $THEME)"
RAW_HTML=$(bun "$PUBLISH_DIR/scripts/md-to-wechat.ts" "$MARKDOWN" --theme "$THEME" 2>/dev/null \
  | bun -e "const d=await Bun.stdin.text(); console.log(JSON.parse(d).htmlPath)" 2>/dev/null)

echo "[publish] Step 2: apply ink typography post-processing"
FIXED_HTML="${RAW_HTML%.html}-ink.html"
uv run --with beautifulsoup4 python3 "$TYPOGRAPHY" "$RAW_HTML" "$FIXED_HTML" 2>/dev/null

echo "[publish] Step 3: publish to WeChat (account: $ACCOUNT)"
COVER_ARG=""
[[ -n "$COVER" ]] && COVER_ARG="--cover $COVER"

bun "$PUBLISH_DIR/scripts/wechat-api.ts" \
  "$MARKDOWN" \
  --theme "$THEME" \
  --account "$ACCOUNT" \
  $COVER_ARG 2>&1
