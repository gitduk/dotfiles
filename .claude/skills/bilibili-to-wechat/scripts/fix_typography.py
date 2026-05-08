#!/usr/bin/env python3
"""
Post-process baoyu-md HTML output — 黑白水墨风 Chinese ink-wash typography.
"""

import sys
from bs4 import BeautifulSoup

# ── 水墨色系 ──────────────────────────────────────────────────────────────────
INK       = "#1a1a1a"   # 浓墨
INK_MID   = "#444"      # 中墨
INK_LIGHT = "#888"      # 淡墨
INK_TRACE = "#bbb"      # 墨迹
PAPER     = "#f8f7f4"   # 宣纸色
PAPER_MID = "#efefec"   # 略深宣纸

# ── 段落 ──────────────────────────────────────────────────────────────────────
P_STYLE = (
    "margin-top: 0;"
    "margin-bottom: 1.5em;"
    "text-indent: 2em;"
    "line-height: 2.0;"
    "font-size: 15px;"
    f"color: {INK_MID};"
    "word-break: break-word;"
    "letter-spacing: 0.02em;"
)

P_IN_BLOCKQUOTE = (
    "margin: 0;"
    "text-indent: 0;"
    "line-height: 2.0;"
    "font-size: 14px;"
    f"color: {INK_LIGHT};"
    "font-style: normal;"
)

# ── H2：宣纸底 + 左侧墨线，像碑刻题头 ────────────────────────────────────────
H2_STYLE = (
    "display: block;"
    f"border-left: 4px solid {INK};"
    f"background: {PAPER_MID};"
    "padding: 0.5em 1em;"
    "margin: 2.2em 0 1.2em 0;"
    "font-size: 1.2em;"
    "font-weight: bold;"
    f"color: {INK};"
    "border-radius: 0 4px 4px 0;"
    "letter-spacing: 0.06em;"
    "box-shadow: none;"
)

# ── H3：细墨线下划，简洁 ──────────────────────────────────────────────────────
H3_STYLE = (
    "display: block;"
    f"border-bottom: 1px solid {INK_TRACE};"
    "padding: 0 0 0.35em 0;"
    "margin: 1.8em 0 0.9em 0;"
    "font-size: 1.05em;"
    "font-weight: bold;"
    f"color: {INK};"
    "letter-spacing: 0.04em;"
    "box-shadow: none;"
    "border-left: none;"
    "background: none;"
)

# ── 引用块：淡墨渲染 ──────────────────────────────────────────────────────────
BLOCKQUOTE_STYLE = (
    "margin: 1.5em 0;"
    f"border-left: 3px solid {INK_LIGHT};"
    f"background: {PAPER};"
    "padding: 0.9em 1.2em;"
    "border-radius: 0 4px 4px 0;"
    "box-shadow: none;"
    "font-style: normal;"
)

# ── 列表项 ────────────────────────────────────────────────────────────────────
LI_STYLE = (
    "margin: 0.55em 0;"
    "line-height: 2.0;"
    "font-size: 15px;"
    f"color: {INK_MID};"
    "letter-spacing: 0.02em;"
)

# ── 分割线：淡淡一横 ──────────────────────────────────────────────────────────
HR_STYLE = (
    "border: none;"
    f"border-top: 1px solid {INK_TRACE};"
    "margin: 2.5em auto;"
    "width: 40%;"
    "opacity: 0.5;"
)

# ── 加粗：浓墨强调 ────────────────────────────────────────────────────────────
STRONG_STYLE = (
    f"color: {INK};"
    "font-weight: bold;"
    "letter-spacing: 0.02em;"
)


def fix_html(html: str) -> str:
    soup = BeautifulSoup(html, "html.parser")

    for p in soup.find_all("p"):
        if p.find_parent("blockquote"):
            p["style"] = P_IN_BLOCKQUOTE
        else:
            p["style"] = P_STYLE

    for h2 in soup.find_all("h2"):
        h2["style"] = H2_STYLE

    for h3 in soup.find_all("h3"):
        h3["style"] = H3_STYLE

    for bq in soup.find_all("blockquote"):
        bq["style"] = BLOCKQUOTE_STYLE

    for li in soup.find_all("li"):
        li["style"] = LI_STYLE

    for hr in soup.find_all("hr"):
        hr["style"] = HR_STYLE

    for strong in soup.find_all("strong"):
        strong["style"] = STRONG_STYLE

    # body 背景改为宣纸色
    body = soup.find("body")
    if body:
        existing = body.get("style", "")
        body["style"] = existing + f"; background: {PAPER};"

    return str(soup)


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <input.html> <output.html>", file=sys.stderr)
        sys.exit(1)

    with open(sys.argv[1], "r", encoding="utf-8") as f:
        html = f.read()

    fixed = fix_html(html)

    with open(sys.argv[2], "w", encoding="utf-8") as f:
        f.write(fixed)

    print(f"Done: {sys.argv[2]}")


if __name__ == "__main__":
    main()
