# RTK - Rust Token Killer

Token-optimized CLI proxy (60-90% savings on dev operations). Ordinary commands are rewritten to `rtk <cmd>` automatically by a Claude Code hook — transparent, nothing to do. Use `rtk` directly only for its meta commands:

```bash
rtk gain              # Token savings analytics (--history for per-command)
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```
