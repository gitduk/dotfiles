#!/usr/bin/env bash
# btc-watch skeleton watcher
#
# High-precision BTC event watcher with local dedupe state and Telegram delivery
# delegated to the send-message skill.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$SKILL_DIR/.env"
STATE_DIR="$SKILL_DIR/state"
FIXTURES_DIR="$SKILL_DIR/fixtures"
SEEN_FILE="$STATE_DIR/seen-events.json"
LAST_CHECK_FILE="$STATE_DIR/last-check.json"
SEND_MESSAGE_SH="$HOME/.claude/skills/send-message/scripts/send.sh"

usage() {
  cat <<'EOF'
Usage: watch.sh <command> [options]

Commands:
  check [--dry-run] [--fixture <file>]  Run one watcher pass
  notify --event-file <file>            Send one event JSON via send-message
  test-notify                           Send a synthetic high-impact test event
  gc                                    Drop old dedupe entries
  --help, -h                            Show this help

Examples:
  watch.sh check --dry-run --fixture ~/.claude/skills/btc-watch/fixtures/sample-events.json
  watch.sh check --fixture ~/.claude/skills/btc-watch/fixtures/sample-events.json
  watch.sh test-notify
  watch.sh gc
EOF
}

die() { printf 'btc-watch: %s\n' "$*" >&2; exit 1; }

command -v jq      >/dev/null || die "jq not found"
command -v python3 >/dev/null || die "python3 not found"
command -v xh      >/dev/null || die "xh not found"
[[ -x "$SEND_MESSAGE_SH" ]] || die "send-message script not found: $SEND_MESSAGE_SH"

mkdir -p "$STATE_DIR"
[[ -f "$SEEN_FILE" ]]      || printf '[]\n' > "$SEEN_FILE"
[[ -f "$LAST_CHECK_FILE" ]] || printf '{"last_checked_at":null,"last_summary":null}\n' > "$LAST_CHECK_FILE"

load_env() {
  [[ -f "$ENV_FILE" ]] || return 0
  chmod 600 "$ENV_FILE" 2>/dev/null || true
  while IFS='=' read -r k v || [[ -n "$k" ]]; do
    [[ -z "$k" || "$k" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${!k:-}" ]] && export "$k=$v"
  done < "$ENV_FILE"
}

load_env

BTC_WATCH_ENABLED="${BTC_WATCH_ENABLED:-1}"
BTC_WATCH_NOTIFY="${BTC_WATCH_NOTIFY:-1}"
BTC_WATCH_SEEN_RETENTION_DAYS="${BTC_WATCH_SEEN_RETENTION_DAYS:-30}"
BTC_WATCH_MIN_SEVERITY="${BTC_WATCH_MIN_SEVERITY:-high}"
BTC_WATCH_ENABLE_LIVE="${BTC_WATCH_ENABLE_LIVE:-1}"
BTC_WATCH_SOURCE_LIMIT="${BTC_WATCH_SOURCE_LIMIT:-10}"
BTC_WATCH_MAX_EVENT_AGE_DAYS="${BTC_WATCH_MAX_EVENT_AGE_DAYS:-7}"
BTC_WATCH_SOURCE_SEC_RSS="${BTC_WATCH_SOURCE_SEC_RSS:-https://www.sec.gov/news/pressreleases.rss}"
BTC_WATCH_SOURCE_FED_RSS="${BTC_WATCH_SOURCE_FED_RSS:-https://www.federalreserve.gov/feeds/press_all.xml}"

severity_rank() {
  case "$1" in
    critical) echo 3 ;;
    high)     echo 2 ;;
    medium)   echo 1 ;;
    low)      echo 0 ;;
    *)        echo -1 ;;
  esac
}

MIN_SEVERITY_RANK="$(severity_rank "$BTC_WATCH_MIN_SEVERITY")"

json_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

canonical_path() {
  readlink -f "$1"
}

assert_state_path() {
  local path real_path real_state
  path="$1"
  real_path="$(canonical_path "$path")"
  real_state="$(canonical_path "$STATE_DIR")"
  [[ "$real_path" == "$real_state"/* ]] || die "refusing to access path outside state dir: $path"
}

fingerprint_event() {
  python3 - "$1" <<'PY'
import hashlib, json, sys
obj = json.loads(sys.argv[1])

def norm(s):
    return " ".join((s or "").strip().lower().split())

payload = "|".join([
    norm(obj.get("title")),
    norm(obj.get("url")),
    norm(obj.get("event_type")),
    norm((obj.get("published_at") or "")[:10]),
])
print(hashlib.sha256(payload.encode("utf-8")).hexdigest())
PY
}

build_notification_text() {
  python3 - "$1" <<'PY'
import json, sys
obj = json.loads(sys.argv[1])
direction_map = {'bullish': '偏多', 'bearish': '偏空', 'mixed': '中性'}
direction = direction_map.get(obj.get('direction', 'mixed'), obj.get('direction', '中性'))
print(
    "BTC 影响事件\n\n"
    f"- 事件：{obj.get('title', 'unknown')}\n"
    f"- 倾向：{direction}\n"
    f"- 原因：{obj.get('reason', '暂无说明。')}\n"
    f"- 来源：{obj.get('source', 'unknown')}\n"
    f"- 链接：{obj.get('url', 'n/a')}"
)
PY
}

normalize_event() {
  local event_json now fp
  event_json="$1"
  now="$(json_now)"
  fp="$(fingerprint_event "$event_json")"
  jq -cn \
    --argjson obj "$event_json" \
    --arg fingerprint "$fp" \
    --arg first_seen_at "$now" \
    '{
      fingerprint: $fingerprint,
      title: ($obj.title // ""),
      source: ($obj.source // ""),
      url: ($obj.url // ""),
      event_type: ($obj.event_type // ""),
      published_at: ($obj.published_at // null),
      first_seen_at: $first_seen_at,
      notified_at: null,
      severity: ($obj.severity // ""),
      direction: ($obj.direction // "mixed"),
      reason: ($obj.reason // ""),
      decision: null
    }'
}

record_last_check() {
  local summary now tmp
  summary="$1"
  now="$(json_now)"
  tmp="$LAST_CHECK_FILE.tmp"
  assert_state_path "$LAST_CHECK_FILE"
  jq -cn --arg ts "$now" --argjson summary "$summary" '{last_checked_at:$ts,last_summary:$summary}' > "$tmp"
  mv "$tmp" "$LAST_CHECK_FILE"
}

append_seen_event() {
  local event_json tmp
  event_json="$1"
  tmp="$SEEN_FILE.tmp"
  assert_state_path "$SEEN_FILE"
  jq --argjson item "$event_json" '. + [$item]' "$SEEN_FILE" > "$tmp"
  mv "$tmp" "$SEEN_FILE"
}

mark_notified() {
  local fingerprint notified_at tmp
  fingerprint="$1"
  notified_at="$(json_now)"
  tmp="$SEEN_FILE.tmp"
  assert_state_path "$SEEN_FILE"
  jq --arg fp "$fingerprint" --arg ts "$notified_at" '
    map(if .fingerprint == $fp then .notified_at = $ts | .decision = "notified" else . end)
  ' "$SEEN_FILE" > "$tmp"
  mv "$tmp" "$SEEN_FILE"
}

seen_event_json() {
  local fingerprint
  fingerprint="$1"
  jq --arg fp "$fingerprint" -c 'map(select(.fingerprint == $fp)) | .[0] // empty' "$SEEN_FILE"
}

should_accept_event() {
  local event_json severity severity_val event_type title source url reason
  event_json="$1"
  severity="$(jq -r '.severity // empty' <<<"$event_json")"
  severity_val="$(severity_rank "$severity")"
  event_type="$(jq -r '.event_type // empty' <<<"$event_json")"
  title="$(jq -r '.title // empty' <<<"$event_json")"
  source="$(jq -r '.source // empty' <<<"$event_json")"
  url="$(jq -r '.url // empty' <<<"$event_json")"
  reason="$(jq -r '.reason // empty' <<<"$event_json")"

  [[ -n "$title" ]]  || { echo "skip_invalid_title"; return 1; }
  [[ -n "$source" ]] || { echo "skip_invalid_source"; return 1; }
  [[ -n "$url" ]]    || { echo "skip_invalid_url"; return 1; }
  [[ -n "$reason" ]] || { echo "skip_invalid_reason"; return 1; }

  case "$event_type" in
    macro|regulation|etf|exchange|corporate|security) ;;
    *) echo "skip_event_type"; return 1 ;;
  esac

  (( severity_val >= MIN_SEVERITY_RANK )) || { echo "skip_severity"; return 1; }
  echo "accept"
}

run_notify_event_file() {
  local event_file event_json text
  event_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --event-file) event_file="${2:-}"; shift 2 ;;
      *) die "unknown notify argument: $1" ;;
    esac
  done
  [[ -n "$event_file" ]] || die "notify requires --event-file <file>"
  [[ -f "$event_file" ]] || die "event file not found: $event_file"
  event_json="$(<"$event_file")"
  text="$(build_notification_text "$event_json")"
  "$SEND_MESSAGE_SH" --stdin <<<"$text"
}

run_test_notify() {
  local tmp event_json
  tmp="$STATE_DIR/test-event.json"
  assert_state_path "$tmp"
  event_json='{
    "title":"Federal Reserve unexpectedly slows balance sheet runoff",
    "source":"Federal Reserve",
    "url":"https://example.com/test-fed-liquidity-shift",
    "event_type":"macro",
    "published_at":"2026-04-13T08:30:00Z",
    "severity":"high",
    "direction":"bullish",
    "reason":"放缓缩表可能改善边际流动性预期，并支撑包括 BTC 在内的风险资产。"
  }'
  printf '%s\n' "$event_json" > "$tmp"
  run_notify_event_file --event-file "$tmp"
}

select_best_event() {
  python3 - "$1" <<'PY'
import json, sys
items = json.loads(sys.argv[1])
rank = {"critical": 3, "high": 2, "medium": 1, "low": 0}
items.sort(key=lambda x: (rank.get(x.get("severity", ""), -1), x.get("published_at") or ""), reverse=True)
print(json.dumps(items[0] if items else None))
PY
}

run_gc() {
  local tmp cutoff
  assert_state_path "$SEEN_FILE"
  cutoff="$(python3 - "$BTC_WATCH_SEEN_RETENTION_DAYS" <<'PY'
from datetime import datetime, timedelta, timezone
import sys
print((datetime.now(timezone.utc) - timedelta(days=int(sys.argv[1]))).strftime('%Y-%m-%dT%H:%M:%SZ'))
PY
)"
  tmp="$SEEN_FILE.tmp"
  jq --arg cutoff "$cutoff" '
    map(select((.first_seen_at // "") >= $cutoff))
  ' "$SEEN_FILE" > "$tmp"
  mv "$tmp" "$SEEN_FILE"
  jq -cn --arg cutoff "$cutoff" '{gc_cutoff:$cutoff,status:"ok"}'
}

fetch_url() {
  local url
  url="$1"
  xh --check-status --timeout 20 --ignore-stdin GET "$url"
}

parse_rss_feed() {
  python3 - "$1" "$2" "$3" "$4" <<'PY'
import json, re, sys
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta, timezone
from email.utils import parsedate_to_datetime

xml_text = sys.argv[1]
source_name = sys.argv[2]
limit = int(sys.argv[3])
max_age_days = int(sys.argv[4])

macro_patterns = [
    (re.compile(r'\bfomc\b|federal open market committee|interest rate|rates?|balance sheet|runoff|liquidity|quantitative tightening|quantitative easing', re.I), 'macro', 'high'),
]
reg_patterns = [
    (re.compile(r'bitcoin|spot bitcoin|crypto|cryptocurrency|digital asset|exchange traded fund|\betf\b|custody|exchange', re.I), None, 'high'),
]
cutoff = datetime.now(timezone.utc) - timedelta(days=max_age_days)

def parse_pub_date(value):
    if not value:
        return None
    try:
        dt = parsedate_to_datetime(value)
    except Exception:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)

root = ET.fromstring(xml_text)
items = []
for item in root.findall('./channel/item')[:limit]:
    title = (item.findtext('title') or '').strip()
    link = (item.findtext('link') or '').strip()
    pub = (item.findtext('pubDate') or '').strip()
    desc = (item.findtext('description') or '').strip()
    pub_dt = parse_pub_date(pub)
    if pub_dt is None or pub_dt < cutoff:
        continue
    title_desc = f"{title}\n{desc}".strip()
    event = None

    if source_name == 'Federal Reserve':
        for pat, event_type, severity in macro_patterns:
            if pat.search(title_desc):
                reason = '美联储官方表态，可能影响流动性、利率或政策预期，进而影响市场对 BTC 的风险偏好。'
                direction = 'mixed'
                low = title_desc.lower()
                if any(x in low for x in ['slower runoff', 'easing', 'support', 'liquidity']) and 'tightening' not in low:
                    direction = 'bullish'
                elif any(x in low for x in ['rate hike', 'tightening', 'faster runoff']):
                    direction = 'bearish'
                event = {
                    'title': title,
                    'source': source_name,
                    'url': link,
                    'event_type': event_type,
                    'published_at': pub,
                    'severity': severity,
                    'direction': direction,
                    'reason': reason,
                }
                break
    elif source_name == 'SEC':
        for pat, _, severity in reg_patterns:
            if pat.search(title_desc):
                low = title_desc.lower()
                event_type = 'regulation'
                if 'etf' in low or 'exchange traded fund' in low or 'spot bitcoin' in low:
                    event_type = 'etf'
                elif 'exchange' in low or 'custody' in low:
                    event_type = 'security'
                reason = 'SEC 官方动作或声明，可能影响加密市场准入、监管预期或 BTC ETF 定位。'
                direction = 'mixed'
                if any(x in low for x in ['approves', 'approval', 'dismissed charges', 'clarify custody path']):
                    direction = 'bullish'
                elif any(x in low for x in ['charges', 'sues', 'fraud', 'denies', 'delay', 'delays', 'enforcement']):
                    direction = 'bearish'
                event = {
                    'title': title,
                    'source': source_name,
                    'url': link,
                    'event_type': event_type,
                    'published_at': pub,
                    'severity': severity,
                    'direction': direction,
                    'reason': reason,
                }
                break

    if event:
        items.append(event)

print(json.dumps(items))
PY
}

fetch_live_candidates_json() {
  local limit sec_json fed_json combined_json source_errors source_successes source_total status

  if [[ "$BTC_WATCH_ENABLE_LIVE" != "1" ]]; then
    jq -cn '{status:"live_disabled", candidates:[], source_total:0, source_successes:0, source_failures:0, source_errors:[]}'
    return 0
  fi

  limit="$BTC_WATCH_SOURCE_LIMIT"
  source_errors='[]'
  source_successes=0
  source_total=0
  sec_json='[]'
  fed_json='[]'

  if [[ -n "$BTC_WATCH_SOURCE_SEC_RSS" ]]; then
    (( source_total += 1 ))
    if sec_xml="$(fetch_url "$BTC_WATCH_SOURCE_SEC_RSS" 2>/dev/null)"; then
      sec_json="$(parse_rss_feed "$sec_xml" "SEC" "$limit" "$BTC_WATCH_MAX_EVENT_AGE_DAYS")"
      (( source_successes += 1 ))
    else
      source_errors="$(jq -cn --argjson current "$source_errors" --arg source "SEC" --arg error "fetch_failed" '$current + [{source:$source,error:$error}]')"
    fi
  fi

  if [[ -n "$BTC_WATCH_SOURCE_FED_RSS" ]]; then
    (( source_total += 1 ))
    if fed_xml="$(fetch_url "$BTC_WATCH_SOURCE_FED_RSS" 2>/dev/null)"; then
      fed_json="$(parse_rss_feed "$fed_xml" "Federal Reserve" "$limit" "$BTC_WATCH_MAX_EVENT_AGE_DAYS")"
      (( source_successes += 1 ))
    else
      source_errors="$(jq -cn --argjson current "$source_errors" --arg source "Federal Reserve" --arg error "fetch_failed" '$current + [{source:$source,error:$error}]')"
    fi
  fi

  combined_json="$(jq -cn --argjson sec "$sec_json" --argjson fed "$fed_json" '$sec + $fed')"
  status="ok"
  if (( source_total > 0 && source_successes == 0 )); then
    status="all_sources_failed"
  elif (( source_successes < source_total )); then
    status="partial_source_failure"
  fi

  jq -cn \
    --arg status "$status" \
    --argjson candidates "$combined_json" \
    --argjson source_errors "$source_errors" \
    --argjson source_total "$source_total" \
    --argjson source_successes "$source_successes" \
    '{
      status:$status,
      candidates:$candidates,
      source_total:$source_total,
      source_successes:$source_successes,
      source_failures:($source_total - $source_successes),
      source_errors:$source_errors
    }'
}

run_check() {
  local dry_run=0 fixture="" candidates_json accepted_json best_json best_fp existing summary decision normalized tmp_event duplicate_count=0 live_result live_status source_total source_successes source_failures source_errors

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) dry_run=1; shift ;;
      --fixture) fixture="${2:-}"; [[ -n "$fixture" ]] || die "--fixture needs a value"; shift 2 ;;
      *) die "unknown check argument: $1" ;;
    esac
  done

  [[ "$BTC_WATCH_ENABLED" == "1" ]] || {
    summary='{"status":"disabled"}'
    record_last_check "$summary"
    jq -cn --arg status "disabled" '{status:$status}'
    return 0
  }

  if [[ -n "$fixture" ]]; then
    [[ -f "$fixture" ]] || die "fixture not found: $fixture"
    candidates_json="$(<"$fixture")"
    live_status="fixture"
    source_total=0
    source_successes=0
    source_failures=0
    source_errors='[]'
  else
    live_result="$(fetch_live_candidates_json)"
    live_status="$(jq -r '.status' <<<"$live_result")"
    candidates_json="$(jq -c '.candidates' <<<"$live_result")"
    source_total="$(jq -r '.source_total' <<<"$live_result")"
    source_successes="$(jq -r '.source_successes' <<<"$live_result")"
    source_failures="$(jq -r '.source_failures' <<<"$live_result")"
    source_errors="$(jq -c '.source_errors' <<<"$live_result")"

    if [[ "$live_status" == "live_disabled" ]]; then
      summary='{"status":"live_disabled","accepted":0,"notified":0}'
      record_last_check "$summary"
      jq -cn --arg status "live_disabled" '{status:$status, accepted:0, notified:0}'
      return 0
    fi

    if [[ "$live_status" == "all_sources_failed" ]]; then
      summary="$(jq -cn --arg status "$live_status" --argjson total "$source_total" --argjson successes "$source_successes" --argjson failures "$source_failures" --argjson errors "$source_errors" '{status:$status, accepted:0, notified:0, source_total:$total, source_successes:$successes, source_failures:$failures, source_errors:$errors}')"
      record_last_check "$summary"
      jq -cn --arg status "$live_status" --argjson total "$source_total" --argjson successes "$source_successes" --argjson failures "$source_failures" --argjson errors "$source_errors" '{status:$status, accepted:0, notified:0, source_total:$total, source_successes:$successes, source_failures:$failures, source_errors:$errors}'
      return 0
    fi
  fi

  accepted_json="$(jq -c 'map(select(type == "object"))' <<<"$candidates_json")"

  tmp_event="[]"
  while IFS= read -r row; do
    [[ -n "$row" ]] || continue
    decision="$(should_accept_event "$row" || true)"
    if [[ "$decision" == "accept" ]]; then
      normalized="$(normalize_event "$row")"
      best_fp="$(jq -r '.fingerprint' <<<"$normalized")"
      existing="$(seen_event_json "$best_fp")"
      if [[ -n "$existing" ]]; then
        (( duplicate_count += 1 ))
      else
        tmp_event="$(jq -cn --argjson current "$tmp_event" --argjson item "$normalized" '$current + [$item]')"
      fi
    fi
  done < <(jq -c '.[]' <<<"$accepted_json")

  best_json="$(select_best_event "$tmp_event")"
  if [[ "$best_json" == "null" ]]; then
    summary="$(jq -cn --arg status "$live_status" --argjson duplicates "$duplicate_count" --argjson total "$source_total" --argjson successes "$source_successes" --argjson failures "$source_failures" --argjson errors "$source_errors" '{status:$status, accepted:0, notified:0, duplicate_count:$duplicates, source_total:$total, source_successes:$successes, source_failures:$failures, source_errors:$errors}')"
    record_last_check "$summary"
    jq -cn --arg status "$live_status" --argjson duplicates "$duplicate_count" --argjson total "$source_total" --argjson successes "$source_successes" --argjson failures "$source_failures" --argjson errors "$source_errors" '{status:$status, accepted:0, notified:0, duplicate_count:$duplicates, source_total:$total, source_successes:$successes, source_failures:$failures, source_errors:$errors}'
    return 0
  fi

  best_fp="$(jq -r '.fingerprint' <<<"$best_json")"
  existing="$(seen_event_json "$best_fp")"
  if [[ -n "$existing" ]]; then
    summary='{"status":"ok","accepted":1,"notified":0,"decision":"skip_duplicate"}'
    record_last_check "$summary"
    jq -cn --arg status "ok" '{status:$status, accepted:1, notified:0, decision:"skip_duplicate"}'
    return 0
  fi

  if (( dry_run )); then
    summary="$(jq -cn --arg status "$live_status" --arg fp "$best_fp" --argjson total "$source_total" --argjson successes "$source_successes" --argjson failures "$source_failures" --argjson errors "$source_errors" '{status:$status, accepted:1, notified:0, fingerprint:$fp, source_total:$total, source_successes:$successes, source_failures:$failures, source_errors:$errors}')"
    record_last_check "$summary"
    jq -cn --argjson event "$best_json" --arg status "$live_status" --argjson total "$source_total" --argjson successes "$source_successes" --argjson failures "$source_failures" --argjson errors "$source_errors" '{status:$status, accepted:1, notified:0, source_total:$total, source_successes:$successes, source_failures:$failures, source_errors:$errors, event:$event}'
    return 0
  fi

  best_json="$(jq '.decision = "selected"' <<<"$best_json")"
  append_seen_event "$best_json"

  if [[ "$BTC_WATCH_NOTIFY" == "1" ]]; then
    local event_file text_result
    event_file="$STATE_DIR/current-event.json"
    assert_state_path "$event_file"
    printf '%s\n' "$best_json" > "$event_file"
    text_result="$(run_notify_event_file --event-file "$event_file")"
    mark_notified "$best_fp"
    summary="$(jq -cn --arg status "$live_status" --arg notify "$text_result" --argjson total "$source_total" --argjson successes "$source_successes" --argjson failures "$source_failures" --argjson errors "$source_errors" '{status:$status, accepted:1, notified:1, notify_result:$notify, source_total:$total, source_successes:$successes, source_failures:$failures, source_errors:$errors}')"
    record_last_check "$summary"
    jq -cn --argjson event "$best_json" --arg status "$live_status" --arg notify "$text_result" --argjson total "$source_total" --argjson successes "$source_successes" --argjson failures "$source_failures" --argjson errors "$source_errors" '{status:$status, accepted:1, notified:1, notify_result:$notify, source_total:$total, source_successes:$successes, source_failures:$failures, source_errors:$errors, event:$event}'
    return 0
  fi

  summary="$(jq -cn --arg status "$live_status" --argjson total "$source_total" --argjson successes "$source_successes" --argjson failures "$source_failures" --argjson errors "$source_errors" '{status:$status, accepted:1, notified:0, decision:"notify_disabled", source_total:$total, source_successes:$successes, source_failures:$failures, source_errors:$errors}')"
  record_last_check "$summary"
  jq -cn --argjson event "$best_json" --arg status "$live_status" --argjson total "$source_total" --argjson successes "$source_successes" --argjson failures "$source_failures" --argjson errors "$source_errors" '{status:$status, accepted:1, notified:0, decision:"notify_disabled", source_total:$total, source_successes:$successes, source_failures:$failures, source_errors:$errors, event:$event}'
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    check) shift; run_check "$@" ;;
    notify) shift; run_notify_event_file "$@" ;;
    test-notify) shift; [[ $# -eq 0 ]] || die "test-notify takes no arguments"; run_test_notify ;;
    gc) shift; [[ $# -eq 0 ]] || die "gc takes no arguments"; run_gc ;;
    --help|-h|help|"") usage ;;
    *) die "unknown command: $cmd" ;;
  esac
}

main "$@"
