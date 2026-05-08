#!/usr/bin/env python3
"""
publish_html.py — 直接将预渲染 HTML 发布到微信公众号草稿箱。
读取 ~/.baoyu-skills/baoyu-post-to-wechat/EXTEND.md 中的凭证。

Usage:
  uv run --with requests --with pyyaml python3 publish_html.py \
    --html <article.html> \
    --title "标题" \
    --digest "摘要" \
    [--cover <cover.jpg>] \
    [--account default]
"""

import sys
import json
import argparse
from pathlib import Path

import requests
import yaml


# ── 读取 EXTEND.md 凭证 ───────────────────────────────────────────────────────

def load_credentials(account_alias: str) -> dict:
    extend_path = Path.home() / ".baoyu-skills/baoyu-post-to-wechat/EXTEND.md"
    text = extend_path.read_text(encoding="utf-8")

    # 提取 YAML frontmatter
    if text.startswith("---"):
        end = text.index("---", 3)
        frontmatter = yaml.safe_load(text[3:end])
    else:
        frontmatter = {}

    # 从 accounts 块找到指定账号
    body = text[text.index("---", 3) + 3:]
    accounts_match = None
    for line in body.split("\n"):
        if "accounts:" in line:
            accounts_match = True
            break

    if accounts_match:
        accounts_yaml = body[body.index("accounts:"):]
        data = yaml.safe_load(accounts_yaml)
        accounts = data.get("accounts", [])
        for acc in accounts:
            if acc.get("alias") == account_alias or (account_alias == "default" and acc.get("default")):
                return acc

    raise ValueError(f"Account '{account_alias}' not found in EXTEND.md")


# ── 微信 API ──────────────────────────────────────────────────────────────────

def get_access_token(app_id: str, app_secret: str) -> str:
    resp = requests.get(
        "https://api.weixin.qq.com/cgi-bin/token",
        params={"grant_type": "client_credential", "appid": app_id, "secret": app_secret},
        timeout=15,
    )
    data = resp.json()
    if "access_token" not in data:
        raise RuntimeError(f"Token error: {data}")
    return data["access_token"]


def upload_image(token: str, image_path: str) -> str:
    """上传图片，返回 media_id"""
    with open(image_path, "rb") as f:
        resp = requests.post(
            f"https://api.weixin.qq.com/cgi-bin/material/add_material?access_token={token}&type=image",
            files={"media": (Path(image_path).name, f, "image/jpeg")},
            timeout=30,
        )
    data = resp.json()
    if "media_id" not in data:
        raise RuntimeError(f"Image upload error: {data}")
    return data["media_id"]


def create_draft(token: str, title: str, digest: str, content: str, thumb_media_id: str) -> str:
    payload = {
        "articles": [{
            "title": title,
            "digest": digest,
            "content": content,
            "thumb_media_id": thumb_media_id,
            "need_open_comment": 1,
            "only_fans_can_comment": 0,
        }]
    }
    resp = requests.post(
        f"https://api.weixin.qq.com/cgi-bin/draft/add?access_token={token}",
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={"Content-Type": "application/json; charset=utf-8"},
        timeout=30,
    )
    data = resp.json()
    if "media_id" not in data:
        raise RuntimeError(f"Draft error: {data}")
    return data["media_id"]


# ── 主流程 ────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--html",    required=True)
    parser.add_argument("--title",   required=True)
    parser.add_argument("--digest",  default="")
    parser.add_argument("--cover",   default="")
    parser.add_argument("--account", default="default")
    args = parser.parse_args()

    print(f"[publish_html] Account: {args.account}")
    creds = load_credentials(args.account)
    app_id = creds["app_id"]
    app_secret = creds["app_secret"]

    print("[publish_html] Fetching access token...")
    token = get_access_token(app_id, app_secret)

    cover_media_id = ""
    if args.cover and Path(args.cover).exists():
        print(f"[publish_html] Uploading cover: {args.cover}")
        cover_media_id = upload_image(token, args.cover)
    else:
        raise RuntimeError("--cover is required and must exist")

    full_html = Path(args.html).read_text(encoding="utf-8")

    # WeChat content field requires body fragment, not full HTML document
    from bs4 import BeautifulSoup
    soup = BeautifulSoup(full_html, "html.parser")
    body = soup.find("body")
    content = str(body.decode_contents()) if body else full_html

    # WeChat digest limit is 120 bytes (UTF-8), truncate safely
    raw_digest = args.digest or args.title
    encoded = raw_digest.encode("utf-8")
    if len(encoded) > 120:
        # Truncate at byte boundary without breaking multi-byte chars
        truncated = encoded[:120].decode("utf-8", errors="ignore")
        digest = truncated
    else:
        digest = raw_digest

    print("[publish_html] Creating draft...")
    media_id = create_draft(token, args.title, digest, content, cover_media_id)

    print(json.dumps({"success": True, "media_id": media_id, "title": args.title}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
