---
name: video-to-wechat
description: 视频转微信公众号文章。从 YouTube/Bilibili 视频提取字幕，生成文章，审核迭代，一键发布。
  触发：用户提供视频链接要求写公众号文章，或 /video-to-wechat 命令。
user-invocable: true
---

# Video → 微信公众号 工作流

端到端自动化：视频链接 → 字幕提取 → 文章生成 → 质量审核 → 人工确认 → 发布。

## Step 0: 解析输入

- 从用户消息中提取视频 URL（YouTube / Bilibili）
- 收集可选写作指导：目标受众、文章风格、重点内容
- 创建工作目录：

```bash
WORK_DIR="$(pwd)/video-to-wechat/$(date +%Y-%m-%d)"
mkdir -p "$WORK_DIR"
```

判断平台：
- YouTube: URL 含 `youtube.com` 或 `youtu.be`
- Bilibili: URL 含 `bilibili.com` 或以 `BV` 开头

## Step 1: 提取 Transcript

### YouTube

```bash
# 技能目录
YT_SKILL="$HOME/.agents/skills/youtube-transcript"

uv run "$YT_SKILL/scripts/get_transcript.py" "VIDEO_URL" > "$WORK_DIR/transcript.txt"
```

### Bilibili

使用 [bilibili-cli](https://github.com/jackwener/bilibili-cli)（`bili` 命令）提取字幕：

```bash
bili video "VIDEO_URL" --subtitle > "$WORK_DIR/transcript.txt"
```

- 保存原始 transcript 到工作目录（`transcript.txt`）
- 如提取失败（无字幕），报告错误，询问用户是否手动提供 transcript
- 安装：`uv tool install bilibili-cli`

## Step 2: Transcript → Article Markdown

读取 `references/transcript-to-article.md` 中的模板和规则，生成文章。

**输入**：
- 原始 transcript 内容
- 用户提供的写作指导（如有）

**生成内容**：
1. 文章正文（1000-1500 字 Markdown）
2. 5 个候选爆款标题
3. frontmatter（title/author/summary）

将文章保存为 `$WORK_DIR/article.md`。

按 `references/transcript-to-article.md` 的规则执行。

## Step 3: 质量审核（subagent）

启动 subagent，读取 `references/quality-review.md` 中的审核标准，对 `$WORK_DIR/article.md` 进行检查：

- 结构完整性（开头-正文-结尾）
- 信息密度（去水分/重复）
- 与原始 transcript 的信息保真度
- 标题吸引力评分

subagent 直接对文章进行优化，写回 `$WORK_DIR/article.md`，并输出审核摘要。

## Step 4: 人工审核循环

向用户展示：
1. **5 个候选标题**（编号 1-5）
2. **文章全文**
3. **审核摘要**（一段话）

等待用户反馈：
- 用户选择标题（如"选 3"）
- 用户提出修改意见 → 按意见修改文章，再次展示
- 用户回复"确认"或"发布" → 进入 Step 4.5

生成最终定稿 `$WORK_DIR/article-final.md`（含选定标题的 frontmatter）。

## Step 4.5: 获取封面图

微信公众号文章需要封面图（推荐 900×383px 或 16:9 比例）。

**自动获取流程**：

1. 从文章标题/摘要提取关键词（2-3 个核心词）
2. 使用 Unsplash/Pexels API 搜索相关图片
3. 下载第一张合适的图片到 `$WORK_DIR/imgs/cover.jpg`
4. 向用户展示图片预览（使用 Read 工具读取图片）
5. 询问："使用这张封面？（是/否/换一张）"

**关键词提取示例**：
- "为什么有人天生自带香气？中医教你从内养出体香" → `chinese herbs, wellness, natural`
- "AI 如何改变编程" → `artificial intelligence, coding, technology`

**图片搜索 API**：

```bash
# Unsplash（需要 API key，免费 50 次/小时）
curl "https://api.unsplash.com/search/photos?query=chinese+herbs&per_page=1&client_id=$UNSPLASH_ACCESS_KEY"

# Pexels（需要 API key，免费 200 次/小时）
curl -H "Authorization: $PEXELS_API_KEY" "https://api.pexels.com/v1/search?query=wellness&per_page=1"

# Picsum（无需 key，随机图片，备用方案）
curl -L "https://picsum.photos/900/383" -o cover.jpg
```

**如果用户拒绝**：
- "换一张" → 搜索下一张（offset +1）
- "否" → 询问是否手动提供图片路径或 URL
- 用户提供路径/URL → 下载到 `$WORK_DIR/imgs/cover.jpg`

**API Key 配置**（可选，提升图片质量）：
- 在 `~/.claude/skills/video-to-wechat/.env` 中添加：
  ```
  UNSPLASH_ACCESS_KEY=your_key
  PEXELS_API_KEY=your_key
  ```
- 如无 key，使用 Picsum 随机图片作为备用

## Step 5: 主题选择与发布

展示可用主题：

| 主题 | 风格 |
|------|------|
| default | 经典蓝色，通用 |
| grace | 优雅紫色，人文 |
| simple | 极简黑白 |
| modern | 现代深色 |

可用颜色（13 种）：`#1a1a2e` `#16213e` `#0f3460` `#533483` `#6a0572` `#e94560` `#ff6b6b` `#feca57` `#48dbfb` `#1dd1a1` `#006266` `#1b1b2f` `#2c2c54`

询问用户主题偏好（默认 `default`），然后调用 baoyu-post-to-wechat skill 发布：

```bash
# baoyu skill 发布脚本内部处理 md → HTML 渲染
BAOYU_SKILL="$HOME/.agents/skills/baoyu-post-to-wechat"
# 调用方式参见 baoyu-post-to-wechat SKILL.md
```

使用默认 API 方法（非 CDP），传入 `article-final.md`，主题为用户选择值。

## 错误处理

- Transcript 提取失败 → 询问用户是否手动粘贴 transcript
- 网络错误 → 报告并等待用户决策
- 发布失败 → 提示用户检查 token 配置
