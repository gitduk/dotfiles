#!/usr/bin/env bun
/**
 * publish-html.ts — 将预渲染 HTML 发布到微信公众号草稿箱
 * 复用 wechat-api.ts 的 API 结构，支持水墨风后处理 HTML 直接发布
 *
 * Usage:
 *   bun publish-html.ts \
 *     --html article-ink.html \
 *     --title "标题" \
 *     --digest "摘要" \
 *     --cover cover.jpg \
 *     [--account default]
 */

import fs from "node:fs";
import path from "node:path";
import os from "node:os";

// ── 读取 EXTEND.md 凭证 ───────────────────────────────────────────────────────

function loadCredentials(alias: string) {
  const extendPath = path.join(os.homedir(), ".baoyu-skills/baoyu-post-to-wechat/EXTEND.md");
  const text = fs.readFileSync(extendPath, "utf-8");

  // Split into account blocks at each "- name:" entry
  const blocks = text.split(/(?=\s+-\s+name:)/);
  for (const block of blocks) {
    const appId     = block.match(/app_id:\s*(\S+)/)?.[1];
    const appSecret = block.match(/app_secret:\s*(\S+)/)?.[1];
    const blockAlias   = block.match(/alias:\s*(\S+)/)?.[1];
    const isDefault = /default:\s*true/.test(block);

    if (!appId || !appSecret) continue;
    if (blockAlias === alias || (alias === "default" && isDefault)) {
      return { app_id: appId, app_secret: appSecret, alias: blockAlias };
    }
  }
  throw new Error(`Account '${alias}' not found in EXTEND.md`);
}

// ── 微信 API ──────────────────────────────────────────────────────────────────

async function getToken(appId: string, appSecret: string): Promise<string> {
  const url = `https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=${appId}&secret=${appSecret}`;
  const data = await fetch(url).then(r => r.json()) as any;
  if (data.errcode) throw new Error(`Token error ${data.errcode}: ${data.errmsg}`);
  return data.access_token;
}

async function uploadCover(token: string, imagePath: string): Promise<string> {
  const url = `https://api.weixin.qq.com/cgi-bin/material/add_material?access_token=${token}&type=image`;
  const fileBuffer = fs.readFileSync(imagePath);
  const filename = path.basename(imagePath);

  const form = new FormData();
  form.append("media", new Blob([fileBuffer], { type: "image/jpeg" }), filename);

  const data = await fetch(url, { method: "POST", body: form }).then(r => r.json()) as any;
  if (!data.media_id) throw new Error(`Cover upload error: ${JSON.stringify(data)}`);
  console.error(`[publish-html] Cover uploaded: ${data.media_id}`);
  return data.media_id;
}

async function createDraft(
  token: string,
  title: string,
  digest: string,
  content: string,
  thumbMediaId: string,
): Promise<string> {
  const url = `https://api.weixin.qq.com/cgi-bin/draft/add?access_token=${token}`;
  const article = {
    article_type: "news",
    title,
    digest: digest.slice(0, 120),
    content,
    thumb_media_id: thumbMediaId,
    need_open_comment: 1,
    only_fans_can_comment: 0,
  };

  const data = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ articles: [article] }),
  }).then(r => r.json()) as any;

  if (data.errcode && data.errcode !== 0) {
    throw new Error(`Draft error ${data.errcode}: ${data.errmsg}`);
  }
  return data.media_id;
}

// ── 主流程 ────────────────────────────────────────────────────────────────────

async function main() {
  const args = process.argv.slice(2);
  const get = (flag: string) => {
    const i = args.indexOf(flag);
    return i >= 0 ? args[i + 1] : undefined;
  };

  const htmlPath  = get("--html")    ?? "";
  const title     = get("--title")   ?? "";
  const digest    = get("--digest")  ?? title;
  const cover     = get("--cover")   ?? "";
  const account   = get("--account") ?? "default";

  if (!htmlPath || !title || !cover) {
    console.error("Usage: bun publish-html.ts --html <file> --title <title> --cover <img> [--digest <text>] [--account <alias>]");
    process.exit(1);
  }

  console.error(`[publish-html] Account: ${account}`);
  const creds = loadCredentials(account);

  console.error("[publish-html] Fetching access token...");
  const token = await getToken(creds.app_id!, creds.app_secret!);

  console.error(`[publish-html] Uploading cover: ${cover}`);
  const thumbId = await uploadCover(token, cover);

  // 提取 body 内容
  const fullHtml = fs.readFileSync(htmlPath, "utf-8");
  const bodyMatch = fullHtml.match(/<body[^>]*>([\s\S]*)<\/body>/i);
  const content = bodyMatch ? bodyMatch[1]! : fullHtml;

  console.error("[publish-html] Creating draft...");
  const mediaId = await createDraft(token, title, digest, content, thumbId);

  console.log(JSON.stringify({ success: true, media_id: mediaId, title }, null, 2));
}

await main().catch(e => {
  console.error("Error:", e.message);
  process.exit(1);
});
