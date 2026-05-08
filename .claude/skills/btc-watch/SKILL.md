---
name: btc-watch
description: Monitor high-impact information that could move Bitcoin and notify 凯歌 only when a new, high-value event appears. High precision by default: macro hard events, major regulatory actions, ETF regime shifts, and top-tier exchange/security incidents — not general crypto noise.
user-invocable: true
---

# btc-watch — high-precision Bitcoin event watcher

A local watcher skill for **high-impact BTC-moving events**. This is not a
broad crypto news scraper. It is intentionally narrow and conservative: it
tries to notify only when a new event is plausibly important enough to affect
Bitcoin price expectations.

## What this skill is for

- Check for **new** high-impact BTC events
- Keep local state so the same event is not sent twice
- Summarize a selected event briefly
- Reuse `send-message` as the outbound Telegram delivery mechanism

## What this skill is NOT for

- General market news aggregation
- KOL sentiment, Twitter/X monitoring, YouTube summaries
- Technical analysis alerts
- Full macro calendar ingestion across every release

## Scope of version 1

Version 1 is a **skeleton watcher** with a stable local state machine and a
real notification path. It supports:

- `test-notify` using a synthetic event
- `check --fixture <file>` for repeatable local testing
- live-source checking from official announcement feeds
- event deduplication by fingerprint
- one-shot Telegram notification through `send-message`
- garbage collection of old dedupe records

The first live sources are intentionally narrow: official Federal Reserve and
SEC announcement feeds.

## Directory layout

```text
~/.claude/skills/btc-watch/
├── SKILL.md
├── .env
├── fixtures/
├── scripts/watch.sh
└── state/
    ├── seen-events.json
    └── last-check.json
```

## Configuration

Create `~/.claude/skills/btc-watch/.env`.

Example:

```bash
BTC_WATCH_ENABLED=1
BTC_WATCH_NOTIFY=1
BTC_WATCH_SEEN_RETENTION_DAYS=30
BTC_WATCH_MIN_SEVERITY=high
BTC_WATCH_ENABLE_LIVE=1
BTC_WATCH_SOURCE_LIMIT=10
BTC_WATCH_SOURCE_SEC_RSS=https://www.sec.gov/news/pressreleases.rss
BTC_WATCH_SOURCE_FED_RSS=https://www.federalreserve.gov/feeds/press_all.xml
```

Notes:
- `.env` is parsed line-by-line, not `source`d
- real env vars override `.env`
- notification delivery still goes through:
  `~/.claude/skills/send-message/scripts/send.sh`

## Commands

### `watch.sh check [--dry-run] [--fixture <file>]`

Run one watcher pass.

- With `--fixture`, load candidate events from a local JSON file
- Without a fixture, version 1 fetches a narrow set of official live sources
  (currently Federal Reserve + SEC announcement feeds)
- `--dry-run` performs full classification/dedup logic without writing state or
  sending Telegram messages

### `watch.sh notify --event-file <file>`

Send one event JSON through `send-message` after formatting it into a short BTC
impact summary.

### `watch.sh test-notify`

Send a synthetic high-impact test event through the real Telegram path.

### `watch.sh gc`

Drop dedupe entries older than `BTC_WATCH_SEEN_RETENTION_DAYS` (default 30).

## Event JSON shape

Each candidate event should be a JSON object with at least:

```json
{
  "title": "Fed signals slower balance sheet runoff",
  "source": "Federal Reserve",
  "url": "https://example.com/event",
  "event_type": "macro",
  "published_at": "2026-04-13T08:30:00Z",
  "severity": "high",
  "direction": "bullish",
  "reason": "改善边际流动性预期"
}
```

Accepted `event_type` values in v1:
- `macro`
- `regulation`
- `etf`
- `exchange`
- `corporate`
- `security`

Accepted `severity` values:
- `high`
- `critical`

Lower-severity events are intentionally ignored in v1.

## Notification format

Notifications are short by design. The watcher sends:

```text
BTC 影响事件

- 事件：...
- 倾向：bullish / bearish / mixed
- 原因：...
- 来源：...
- 链接：...
```

If no new high-impact event is found, nothing is sent.

## State model

### `seen-events.json`
Stores dedupe decisions by event fingerprint.

### `last-check.json`
Stores last run metadata and summary counts.

The watcher deduplicates by **event fingerprint**, not by article filename. If
multiple sources describe the same event, v1 should still send at most one
notification.

## Safety properties

- No Telegram API logic is duplicated here — outbound delivery is delegated to
  `send-message`
- `.env` is never sourced as shell code
- state is kept under the skill directory only
- no notification is sent during `--dry-run`
- duplicate events are skipped by fingerprint

## Typical validation flow

```bash
~/.claude/skills/btc-watch/scripts/watch.sh test-notify
~/.claude/skills/btc-watch/scripts/watch.sh check --dry-run --fixture ~/.claude/skills/btc-watch/fixtures/sample-events.json
~/.claude/skills/btc-watch/scripts/watch.sh check --fixture ~/.claude/skills/btc-watch/fixtures/sample-events.json
~/.claude/skills/btc-watch/scripts/watch.sh check --fixture ~/.claude/skills/btc-watch/fixtures/sample-events.json
~/.claude/skills/btc-watch/scripts/watch.sh gc
```

The third command should notify once; the fourth should skip as duplicate.
