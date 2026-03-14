---
name: btc-monitor skill file output location
description: btc-monitor skill must use XDG directories instead of polluting home directory
type: feedback
---

btc-monitor skill outputs files directly to home directory (bitcoin_*.sh, btc_*.json, etc.) instead of proper cache/data directories.

**Why:** Pollutes home directory with temporary data and logs that should be in XDG-compliant locations.

**How to apply:** When using or modifying btc-monitor skill, ensure all output files go to `~/.cache/btc-monitor/` (for temporary data/logs) or `~/.local/share/btc-monitor/` (for persistent data). Never output to home directory root.
