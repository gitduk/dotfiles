#!/usr/bin/env python3
"""Waybar crypto ticker: streams live prices from Binance, reconnects on its own.

Percent shown is the day change: (last price / price at local midnight - 1),
the same reference OKX uses for its 日涨跌.
"""

import json
import math
import os
import signal
import subprocess
import sys
import threading
import time
import urllib.request
from collections import deque
from datetime import date, datetime
from pathlib import Path

COINS = ("BTC", "ETH")

# Per-coin calibration: |1m| / |5m| p99 (warn) and p99.9 (alert), percent. They act
# as floors at VOL_FLOOR_SCALE; the live threshold is k*sigma*sqrt(h) above that.
VOLATILITY = {
    "BTC": {"60": (0.35, 0.87), "300": (0.79, 1.44)},
    "ETH": {"60": (0.37, 1.08), "300": (0.89, 2.05)},
}
VOL_FALLBACK = {"60": (0.40, 1.00), "300": (0.90, 2.00)}
VOL_K = (4, 8)
VOL_FLOOR_SCALE = 0.5
VOL_LAMBDA = 0.94 ** (1 / 86400)  # RiskMetrics daily 0.94, resampled to 1s
VOL_WINDOWS = (60, 300)
VOL_HISTORY = 320
VOL_EXIT = 0.7
VOL_HOLD = 20
# Deep enough to read on waybar's light bar (contrast 2.97 / 3.64 vs #92AFC8).
COLOR_WARN = "#8a4b08"
COLOR_ALERT = "#991b1b"
# Plausibility bounds for USDT pairs; a bogus frame must not reach the bar or cache.
PRICE_RANGE = (1e-6, 1e9)
CHANGE_RANGE = (-99.99, 10000.0)
VOLUME_RANGE = (0.0, 1e15)

STREAM = os.environ.get("COIN_STREAM") or (
    "wss://data-stream.binance.vision/stream?streams="
    + "/".join(f"{c.lower()}usdt@ticker" for c in COINS)
)
KLINES = "https://data-api.binance.vision/api/v3/klines"
CACHE = Path.home() / ".cache/waybar/coin.cache"


def fmt_vol(value):
    if value >= 1e9:
        return f"{value / 1e9:.2f}B"
    if value >= 1e6:
        return f"{value / 1e6:.1f}M"
    return f"{value / 1e3:.0f}K"


def plausible(price, change24, volume):
    values = (price, change24, volume)
    ranges = (PRICE_RANGE, CHANGE_RANGE, VOLUME_RANGE)
    return all(
        math.isfinite(value) and low <= value <= high
        for value, (low, high) in zip(values, ranges)
    )


class Quote:
    def __init__(self):
        self.price = None
        self.change24 = None
        self.volume = None
        self.day_open = None
        self.open_day = ""
        self.history = deque()
        self.changes = [None, None]
        self.sigma = None
        self.warn_pct = None
        self.alert_pct = None
        self.level = 0
        self.level_since = 0.0

    def update(self, ticker):
        """Accept one ticker frame; reject non-finite or non-positive numbers."""
        try:
            price = float(ticker["c"])
            change24 = float(ticker["P"])
            volume = float(ticker["q"])
        except (KeyError, TypeError, ValueError):
            return False
        if not all(map(math.isfinite, (price, change24, volume))):
            return False
        if not plausible(price, change24, volume):
            return False
        self.price = price
        self.change24 = change24
        self.volume = volume
        return True

    def day_change(self):
        if self.price is None or not self.day_open:
            return None
        return (self.price / self.day_open - 1) * 100


def window_change(history, now, seconds):
    """Percent change from the newest sample at or before `now - seconds`."""
    target = now - seconds
    for stamp, price in reversed(history):
        if stamp <= target:
            return (history[-1][1] / price - 1) * 100
    return None


def volatility_level(changes, thresholds, sigma, scale=1.0):
    level = 0
    for change, span in zip(changes, VOL_WINDOWS):
        if change is None:
            continue
        warn_floor, alert_floor = thresholds[str(span)]
        reach = sigma * math.sqrt(span)
        if abs(change) >= max(VOL_K[1] * reach, VOL_FLOOR_SCALE * alert_floor) * scale:
            level = 2
        elif abs(change) >= max(VOL_K[0] * reach, VOL_FLOOR_SCALE * warn_floor) * scale:
            if level < 1:
                level = 1
    return level


def track_sigma(quote, sym, now, price):
    """One-second EWMA variance, seeded from the coin's calibrated p99."""
    thresholds = VOLATILITY.get(sym, VOL_FALLBACK)
    span = VOL_WINDOWS[0]
    if quote.sigma is None:
        quote.sigma = thresholds[str(span)][0] / (VOL_K[0] * math.sqrt(span))
    if len(quote.history) >= 2:
        stamp, prev = quote.history[-2]
        if now - stamp <= 5:
            ret = (price / prev - 1) * 100
            var = quote.sigma**2 * VOL_LAMBDA + (1 - VOL_LAMBDA) * ret**2
            quote.sigma = math.sqrt(var)
    reach = quote.sigma * math.sqrt(span)
    quote.warn_pct = max(VOL_K[0] * reach, VOL_FLOOR_SCALE * thresholds[str(span)][0])
    quote.alert_pct = max(VOL_K[1] * reach, VOL_FLOOR_SCALE * thresholds[str(span)][1])


def note_volatility(quote, sym, now):
    """Track the 60s/300s windows and the warn/alert level with hysteresis."""
    track_sigma(quote, sym, now, quote.history[-1][1])
    thresholds = VOLATILITY.get(sym, VOL_FALLBACK)
    changes = [window_change(quote.history, now, span) for span in VOL_WINDOWS]
    quote.changes = changes
    reach = volatility_level(changes, thresholds, quote.sigma)
    if reach > quote.level:
        quote.level, quote.level_since = reach, now
    elif reach < quote.level and now - quote.level_since >= VOL_HOLD:
        if volatility_level(changes, thresholds, quote.sigma, VOL_EXIT) < quote.level:
            quote.level, quote.level_since = reach, now


def emit(quotes, note=""):
    text = []
    tooltip = []
    for sym in COINS:
        quote = quotes[sym]
        if quote.price is None:
            text.append(f"{sym} —")
            tooltip.append(f"\n{sym}  无数据")
            continue
        change = quote.day_change()
        color = {1: COLOR_WARN, 2: COLOR_ALERT}.get(quote.level)
        body = f"{quote.price:.2f}" + (
            f" {change:+.2f}%" if change is not None else ""
        )
        text.append(f"{sym} " + (f"<span foreground='{color}'>{body}</span>" if color else body))
        line = f"\n{sym}  {quote.price:.2f} USDT"
        if change is not None:
            line += f"  日 {change:+.2f}%"
        else:
            line += "  日 —（基准价未取到）"
        if quote.change24 is not None:
            line += f"  24h {quote.change24:+.2f}%"
        if quote.volume is not None:
            line += f"  vol {fmt_vol(quote.volume)}"
        for span, move in zip(VOL_WINDOWS, quote.changes):
            if move is not None:
                line += f"  {span // 60}m {move:+.2f}%"
        if quote.warn_pct is not None:
            line += f"  60s 触发 {quote.warn_pct:.2f}/{quote.alert_pct:.2f}%"
        tooltip.append(line)
    header = "更新 " + datetime.now().strftime("%H:%M:%S") + note
    line = {"text": " · ".join(text) + " ", "tooltip": header + "".join(tooltip)}
    print(json.dumps(line, ensure_ascii=False), flush=True)


def midnight():
    return time.mktime(date.today().timetuple())


def fetch_day_open(sym):
    url = (
        f"{KLINES}?symbol={sym}USDT&interval=1m"
        f"&startTime={int(midnight() * 1000)}&limit=1"
    )
    request = urllib.request.Request(url, headers={"User-Agent": "waybar-coin/1.0"})
    with urllib.request.urlopen(request, timeout=10) as response:
        bars = json.load(response)
    return float(bars[0][1])


def refresh_day_opens(quotes, stop):
    """Keep each symbol's local-midnight price; retried until today's is in hand."""
    while not stop.is_set():
        today = date.today().isoformat()
        for sym in COINS:
            quote = quotes[sym]
            if quote.day_open is not None and quote.open_day == today:
                continue
            try:
                quote.day_open = fetch_day_open(sym)
                quote.open_day = today
            except (OSError, ValueError, KeyError, IndexError) as exc:
                print(f"coin: day open {sym}: {exc}", file=sys.stderr)
        stop.wait(30)


def load_cache(quotes):
    try:
        rows = CACHE.read_text().splitlines()
    except OSError:
        return
    for row in rows:
        parts = row.split()
        if len(parts) < 6 or parts[0] not in COINS:
            continue
        sym, price, change24, volume, day_open, open_day = parts[:6]

        def number(value):
            return None if value == "-" else float(value)

        quote = quotes[sym]
        try:
            price, change24, volume, day_open = (
                number(text) for text in (price, change24, volume, day_open)
            )
        except ValueError:
            continue
        if price is not None and not plausible(price, change24 or 0.0, volume or 0.0):
            continue
        if day_open is not None and not plausible(day_open, 0.0, 0.0):
            day_open = None
        quote.price = price
        quote.change24 = change24
        quote.volume = volume
        quote.day_open = day_open
        quote.open_day = "" if open_day == "-" else open_day


def save_cache(quotes):
    rows = []
    for sym, quote in quotes.items():
        fields = [
            "" if quote.price is None else f"{quote.price}",
            "" if quote.change24 is None else f"{quote.change24}",
            "" if quote.volume is None else f"{quote.volume:.2f}",
            "" if quote.day_open is None else f"{quote.day_open}",
            quote.open_day or "-",
        ]
        fields = [field or "-" for field in fields]
        rows.append(f"{sym} " + " ".join(fields) + "\n")
    try:
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        CACHE.write_text("".join(rows))
    except OSError as exc:
        print(f"coin: cache write failed: {exc}", file=sys.stderr)


def follow(quotes):
    """Read one stream connection until it breaks; emit a line per ticker push."""
    proc = subprocess.Popen(
        ["curl", "-sN", "--max-time", "0", STREAM],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    decoder = json.JSONDecoder()
    buffer = ""
    try:
        while True:
            chunk = os.read(proc.stdout.fileno(), 65536)
            if not chunk:
                raise ConnectionError("stream closed")
            buffer += chunk.decode(errors="replace")
            while True:
                buffer = buffer.lstrip()
                if not buffer:
                    break
                try:
                    message, end = decoder.raw_decode(buffer)
                except json.JSONDecodeError:
                    break
                buffer = buffer[end:]
                ticker = message.get("data")
                if not isinstance(ticker, dict):
                    continue
                sym = (ticker.get("s") or "")[:-4]
                if sym in quotes:
                    quote = quotes[sym]
                    if not quote.update(ticker):
                        continue
                    now = time.monotonic()
                    quote.history.append((now, quote.price))
                    while quote.history and now - quote.history[0][0] > VOL_HISTORY:
                        quote.history.popleft()
                    note_volatility(quote, sym, now)
                    emit(quotes)
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            proc.kill()


def main():
    quotes = {sym: Quote() for sym in COINS}

    def stop(*_):
        save_cache(quotes)
        sys.exit(0)

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    load_cache(quotes)
    if any(quote.price is not None for quote in quotes.values()):
        emit(quotes, "（缓存）")

    halt = threading.Event()
    threading.Thread(target=refresh_day_opens, args=(quotes, halt), daemon=True).start()

    backoff = 2
    while True:
        started = time.monotonic()
        try:
            follow(quotes)
        except (ConnectionError, OSError) as exc:
            print(f"coin: {exc}", file=sys.stderr)
        lived = time.monotonic() - started
        save_cache(quotes)
        emit(quotes, "（断线，显示最后价）")
        backoff = 2 if lived > 60 else min(backoff * 2, 30)
        time.sleep(backoff)


if __name__ == "__main__":
    main()
