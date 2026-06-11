---
name: bilibili-to-wechat
description: Bilibili/YouTube 视频或现成 Markdown 转微信公众号文章/HTML。支持从视频提取字幕生成文章，也支持直接美化 Markdown、转换公众号 HTML、预览排版、发布到微信公众号草稿箱。触发：用户提供 Bilibili/YouTube 视频链接要求写公众号文章、提供 Markdown 文件要求美化成公众号格式、要求生成公众号 HTML、预览公众号排版，或 /bilibili-to-wechat 命令。
user-invocable: true
---

# Bilibili / Markdown → 微信公众号 工作流

统一发布链：
- 视频链接 → 字幕提取 → 文章生成 → 质量审核 → 人工确认 → 排版 → 发布
- 现成 Markdown → 排版 → 预览 / 发布

> **排版前必读** `~/.claude/skills/aesthetics/SKILL.md` —— 凯歌的视觉偏好（中式雅、青绿主色、中文排版标准）。所有样式决策以它为准。

这个 skill 只有一个主入口，但支持两类输入：
1. **视频模式**：用户提供 Bilibili / YouTube 链接，生成公众号文章并发布
2. **Markdown 模式**：用户提供现成 `.md` 文件或直接粘贴 Markdown，只做公众号排版、HTML 生成、预览、发布

## 运行时依赖

发布脚本需要 `bun` 或 `npx`。解析方式：
- `bun` 已安装 → 使用 `bun`
- `npx` 可用 → 使用 `npx -y bun`
- 否则提示用户安装 bun

将解析结果存为 `${BUN_X}`。

发布脚本目录（以下称 `{publishDir}`）：
```
$HOME/.agents/skills/baoyu-skills/skills/baoyu-post-to-wechat
```

| 脚本 | 用途 |
|------|------|
| `{publishDir}/scripts/wechat-api.ts` | API 方式发布文章（默认） |
| `{publishDir}/scripts/wechat-article.ts` | 浏览器 CDP 方式发布文章 |
| `{publishDir}/scripts/md-to-wechat.ts` | Markdown → 微信 HTML |
| `{publishDir}/scripts/check-permissions.ts` | 环境检查 |

---

## Step 0: 解析输入

先判断用户提供的是 **视频** 还是 **现成 Markdown**。

### A. 视频模式

适用场景：
- 用户提供 Bilibili / YouTube 链接
- 用户要求“把这个视频写成公众号文章”

执行：
- 从用户消息中提取视频 URL（Bilibili / YouTube）
- 收集可选写作指导：目标受众、文章风格、重点内容
- 创建工作目录：

```bash
WORK_DIR="$(pwd)/bilibili-to-wechat/$(date +%Y-%m-%d)"
mkdir -p "$WORK_DIR/imgs"
```

判断平台：
- Bilibili：URL 含 `bilibili.com` 或以 `BV` 开头
- YouTube：URL 含 `youtube.com` 或 `youtu.be`

### B. Markdown 模式

适用场景：
- 用户提供现成 `.md` 文件并要求美化成公众号格式
- 用户粘贴 Markdown 内容并要求生成公众号 HTML
- 用户要求“预览公众号排版”或“只转换，不发布”

执行：
- 若用户提供文件路径：直接使用该 Markdown 文件
- 若用户直接粘贴 Markdown：保存到 `$WORK_DIR/article.md`
- 若当前目录存在明显是刚生成的目标文章，可向用户确认是否直接使用
- 创建工作目录：

```bash
WORK_DIR="$(pwd)/bilibili-to-wechat/$(date +%Y-%m-%d)"
mkdir -p "$WORK_DIR/imgs"
```

若输入不是文件而是粘贴内容，保存为：

```bash
$WORK_DIR/article.md
```

并将其视为后续排版/预览/发布的输入稿件。

---

## Step 0.5: 读取发布配置（EXTEND.md）

按优先级查找 EXTEND.md：

```bash
test -f .baoyu-skills/baoyu-post-to-wechat/EXTEND.md && echo "project"
test -f "${XDG_CONFIG_HOME:-$HOME/.config}/baoyu-skills/baoyu-post-to-wechat/EXTEND.md" && echo "xdg"
test -f "$HOME/.baoyu-skills/baoyu-post-to-wechat/EXTEND.md" && echo "user"
```

- **找到**：读取并解析，提取 `default_theme`、`default_color`、`default_publish_method`、`default_author`、账号配置等
- **未找到**：继续，发布时执行首次配置（见 Step 5）

### 多账号支持

若 EXTEND.md 含 `accounts:` 块：
- 1 个账号 → 自动选择，提示 `Using account: <name>`
- 多个账号且有 `default: true` → 预选默认账号
- 多个账号无默认 → 提示用户选择

---

## Step 1: 提取 Transcript

### Bilibili

```bash
bili video "VIDEO_URL" --subtitle > "$WORK_DIR/transcript.txt"
```

安装：`uv tool install bilibili-cli`

### YouTube

```bash
YT_SKILL="$HOME/.agents/skills/youtube-transcript"
uv run "$YT_SKILL/scripts/get_transcript.py" "VIDEO_URL" > "$WORK_DIR/transcript.txt"
```

- 保存原始 transcript 到 `$WORK_DIR/transcript.txt`
- 提取失败（无字幕）→ 报告错误，询问用户是否手动提供 transcript

---

## Step 2: Transcript → 文章 Markdown

读取 `references/transcript-to-article.md` 中的模板和规则，生成文章。

**输入**：
- `$WORK_DIR/transcript.txt` 内容
- 用户提供的写作指导（如有）

**生成内容**：
1. 文章正文（1000-1500 字 Markdown，含 frontmatter）
2. 8 个候选标题（微信草稿 API 限制标题不超过 64 字节，约 20 个中文字符）

**frontmatter 模板**：
```yaml
---
title: \"\"        # Step 4 用户选定后填入
author: \"\"       # 留空或填入指定作者
summary: \"\"      # 150字以内，概括核心价值
---
```

将文章保存为 `$WORK_DIR/article.md`。

按 `references/transcript-to-article.md` 的规则执行。

---

## Step 3: 质量审核（subagent）

启动 subagent，读取 `references/quality-review.md` 中的审核标准，对 `$WORK_DIR/article.md` 进行检查：

- 结构完整性（开头-正文-结尾）
- 信息密度（去水分/重复）
- 与原始 transcript 的信息保真度
- 标题吸引力评分

subagent 直接对文章进行优化，写回 `$WORK_DIR/article.md`，并输出审核摘要。

---

## Step 4: 人工审核循环

向用户展示：
1. **8 个候选标题**（编号 1-8，含审核推荐排序）
2. **文章全文**
3. **审核摘要**（一段话）

等待用户反馈：
- 用户选标题（如"选3"）→ 填入 frontmatter title
- 用户提出修改意见 → 按意见修改文章，再次展示
- 用户回复"确认"或"发布" → 进入 Step 4.5

生成最终定稿 WORK_DIR/article-final.md（含选定标题的 frontmatter）。

---

## Step 4.5: 封面图搜索

自动搜索封面图（横幅比例 900x383）：

1. 从文章标题/摘要提取 2-3 个英文关键词
2. 按优先级尝试图源：
   - Unsplash API（需 UNSPLASH_ACCESS_KEY）
   - Pexels API（需 PEXELS_API_KEY）
   - Picsum 随机图（无需 key，备用）
3. 展示图片给用户确认

**API Key 配置**（可选）：
在 `~/.claude/skills/bilibili-to-wechat/.env` 中添加：
```
UNSPLASH_ACCESS_KEY=your_key
PEXELS_API_KEY=your_key
```

**用户反馈处理**：
- 确认 → 继续
- 换一张 → 搜索下一张（offset +1）
- 用户提供路径/URL → 下载到 `$WORK_DIR/imgs/cover.jpg`

---

## Step 5: 排版后处理、预览与���布

这一步既服务于**视频模式**，也服务于**Markdown 模式**。

- 视频模式：输入通常是 `$WORK_DIR/article-final.md`
- Markdown 模式：输入通常是用户提供的 `.md` 文件，或保存后的 `$WORK_DIR/article.md`

默认排版风格从 EXTEND.md 读取 `default_typography`：
- `ink`（默认）：黑白水墨风，宣纸底色，首行缩进，墨色层次
- 空／未设置：跳过后处理，直接用 baoyu-md 原始渲染

询问用户是否使用默认排版，或切换其他风格。

### A. 仅生成 HTML / 预览（不发布）

适用场景：
- 用户要求“生成公众号 HTML”
- 用户要求“预览排版”
- 用户要求“只转换，不发布”

执行：

```bash
SKILL_DIR="$HOME/.claude/skills/bilibili-to-wechat"
INPUT_MD="$WORK_DIR/article.md"   # 或 article-final.md / 用户提供的 .md

# Step 1: 渲染 markdown → HTML（底座主题 simple）
RAW_HTML=$(bun {publishDir}/scripts/md-to-wechat.ts \
  "$INPUT_MD" --theme simple 2>/dev/null \
  | bun -e "const d=await Bun.stdin.text(); console.log(JSON.parse(d).htmlPath)" 2>/dev/null)

# Step 2: 水墨风排版后处理
FIXED_HTML="$WORK_DIR/article-ink.html"
uv run --with beautifulsoup4 python3 \
  "$SKILL_DIR/scripts/fix_typography.py" "$RAW_HTML" "$FIXED_HTML"
```

完成后：
- 告诉用户生成的 HTML 路径
- 可用 Read 工具抽查前几十行，确认标题层级、代码块、表格、图片路径是否合理
- 若用户需要，在浏览器中打开 HTML 进行预览
- 若用户确认继续发布，再进入 B 分支

### B. 发布到微信公众号草稿箱

适用场景：
- 用户明确要求发布
- 用户在预览满意后要求继续发布

**三步管道**：渲染 → 排版后处理 → 发布

```bash
SKILL_DIR="$HOME/.claude/skills/bilibili-to-wechat"
INPUT_MD="$WORK_DIR/article-final.md"   # Markdown 模式下也可以是 article.md 或用户提供的 .md

# Step 1: 渲染 markdown → HTML（底座主题 simple）
RAW_HTML=$(bun {publishDir}/scripts/md-to-wechat.ts \
  "$INPUT_MD" --theme simple 2>/dev/null \
  | bun -e "const d=await Bun.stdin.text(); console.log(JSON.parse(d).htmlPath)" 2>/dev/null)

# Step 2: 水墨风排版后处理
FIXED_HTML="$WORK_DIR/article-ink.html"
uv run --with beautifulsoup4 python3 \
  "$SKILL_DIR/scripts/fix_typography.py" "$RAW_HTML" "$FIXED_HTML"

# Step 3: 发布预处理好的 HTML
uv run --with requests --with pyyaml python3 \
  "$SKILL_DIR/scripts/publish_html.py" \
  --html "$FIXED_HTML" \
  --title "<title>" \
  --digest "<summary>" \
  --cover "$WORK_DIR/imgs/cover.jpg" \
  --account <alias>
```

### 浏览器 CDP 方式（备用）

```bash
${BUN_X} {publishDir}/scripts/wechat-article.ts \
  --markdown "$INPUT_MD" \
  --theme simple \
  --account <alias>
```

### 首次配置（无 EXTEND.md 时）

引导用户完成配置：
1. 选择发布方式（API / 浏览器）
2. 若选 API：输入 `WECHAT_APP_ID` 和 `WECHAT_APP_SECRET`，保存到 `~/.baoyu-skills/.env`
3. 若选浏览器：首次运行时扫码登录，session 自动保存

### 发布完成提示

```bash
发布完成！

来源：<VIDEO_URL 或 MARKDOWN_PATH>
文章：<title>
主题：<theme> <color>
方式：API / 浏览器

结果：
✓ 草稿已保存到微信公众号
  media_id: <media_id>

下一步：
→ 登录 https://mp.weixin.qq.com 进入「内容管理」→「草稿箱」发布

工作目录：<WORK_DIR>
```

---

## 错误处理

| 错误 | 处理方式 |
|------|----------|
| Transcript 提取失败 | 询问用户是否手动粘贴 transcript |
| 网络错误 | 报告并等待用户决策 |
| 发布失败（token 错误） | 提示检查 `.baoyu-skills/.env` 中的凭证 |
| 发布失败（浏览器未登录） | 提示重新扫码登录 |
| 封面图下载失败 | 使用 Picsum 备用，或询问用户手动提供 |

---

## 工作目录结构

```
bilibili-to-wechat/YYYY-MM-DD/
├── transcript.txt       # 原始字幕
├── article.md           # 生成+审核后的文章
├── article-final.md     # 用户确认后的定稿
└── imgs/
    └── cover.jpg        # 封面图
```
