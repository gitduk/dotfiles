---
name: xhs-legal-leads
description: Use when searching 小红书 for people who need legal help, to identify potential legal clients and save leads to CSV. Triggered by phrases like "找法律客户", "小红书获客", "采集法律线索".
user-invocable: true
---

# xhs-legal-leads — 小红书法律客户线索采集

用 chrome-agent（轻量级浏览器自动化工具，输出可访问性树 ~50 tokens）控制真实 Chrome 浏览小红书，用 Claude 的语义理解判断每条帖子是否反映了真实的法律需求，合格线索追加到 CSV 文件。

**重要：Claude 必须手动逐条操作，不要生成 bash 脚本。** 脚本无法处理动态页面变化和异常情况，Claude 手动操作可以实时判断和调整。

**严禁使用 for 循环批量处理。** 必须一条一条手动操作，每条之间观察页面状态、验证结果、处理异常。拟人化操作的核心是"人的节奏"，不是"机器的循环"。

## 工具要求

使用 `chrome-agent`（轻量级，输出可访问性树，~50 tokens vs HTML 2000+ tokens）。

检查是否可用：
```bash
chrome-agent --version
```

不可用则安装：`cargo install chrome-agent`

## 第一步：准备 CSV

目标文件：`~/xhs-legal-leads.csv`

如不存在，写入表头：

```
检索词,标题,帖子链接,作者昵称,案情摘要,法律领域,紧迫度,采集时间,发帖时间,评论内容
```

`紧迫度` 取值：高 / 中 / 低
`法律领域` 取值：劳动 / 婚姻家事 / 房产合同 / 消费维权 / 工伤交通 / 刑事 / 其他
`发帖时间` 格式：YYYY-MM-DD（从帖子页面提取）

## 第二步：启动 Chrome 并手动登录

### 首次使用

让用户在终端运行：

```bash
google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-xhs https://www.xiaohongshu.com
```

用户在弹出的 Chrome 窗口中手动登录小红书。

### 后续使用

用户只需重新运行同一条命令，Chrome 会保留登录状态，无需重新登录。

### Claude 连接

登录完成后，Claude 使用 chrome-agent 连接：

```bash
chrome-agent --connect http://127.0.0.1:9222 --stealth status
```

验证连接成功后即可开始采集。

## 第三步：动态生成关键词并搜索

### 关键词动态生成流程

每次会话开始时，Claude **不使用固定列表**，而是根据当前目标即时生成关键词。

#### 1. 读取上下文

```bash
# 读取关键词历史（避免重复）
cat ~/xhs-keyword-history.log 2>/dev/null | tail -50 || echo "（无历史）"
```

#### 2. 明确本次目标

从用户指令中提取：
- **目标域**：劳动 / 婚姻家事 / 房产合同 / 消费维权 / 工伤交通 / 刑事 / 其他
- **采集量**：默认 30 条，可指定
- **特殊要求**：时效、紧迫度优先级等

**未指定目标域时的默认策略**：

按小红书真实求助密度排序，生成每域 1-2 个词，优先高密度域：

1. 劳动（欠薪/裁员/仲裁求助者最多）→ 2 个词
2. 婚姻家事（离婚/家暴/财产纠纷）→ 2 个词
3. 消费维权（被骗/商家不退款）→ 1 个词
4. 工伤交通（事故/赔偿求助）→ 1 个词
5. 房产合同（开发商/中介纠纷）→ 1 个词
6. 刑事（家属求助为主）→ 1 个词

共 8 个词，够用则不再补充；采集量大（>30 条）时再追加词。

#### 3. 生成关键词列表

Claude 根据目标域，从以下维度**造词**，每次生成 5-10 个：

| 维度 | 说明 | 举例 |
|------|------|------|
| 被动受害 | 描述遭遇 + 无助/求救感 | 「被辞退了 不给赔偿」「钱转出去了找不到人」 |
| 主动维权 | 描述正在维权但遇到障碍 | 「投诉了没用」「申请仲裁 不知道怎么办」 |
| 情绪发泄 | 当事人情绪词 + 法律情景 | 「公司太黑心了 欠薪」「被骗了气死我了 合同」 |
| 具体损失 | 金额/时间/关系 + 纠纷词 | 「押金不退 中介」「工伤住院 公司不认」 |
| 求助信号 | 直接求助语 + 领域词 | 「求助 劳动仲裁」「有没有懂法律的 合同违约」 |

**造词规则**：
- 用真实当事人的口语，不用法律术语
- 避免「怎么办」结尾（结果以科普为主，真实求助者少）
- 与历史关键词**角度明显不同**（换维度、换领域、换情绪词）
- 每个词要有**可区分性**，不要造一批意思相近的词

**生成后声明**：Claude 把生成的关键词列表输出给用户，简要说明每个词的目标定位，然后开始采集。

#### 4. 记录已用关键词

每次搜索前追加到历史：

```bash
echo "$(date '+%Y-%m-%d %H:%M') | $search_keyword" >> ~/xhs-keyword-history.log
```

#### 5. 关键词质量评估与调整

每个关键词跑完 10 条后评估：
- **录入率 < 20%**（10 条里不到 2 条合格）→ 该词质量差，立即换下一个
- **录入率 ≥ 20%** → 继续跑完计划条数
- **连续 3 个关键词质量差** → 暂停，告知用户并等待指令

评估后 Claude 可**即时补充新关键词**（不受初始列表限制），填补低质量词的缺口。

每个关键词默认处理 **15 条**（均摊到总目标 30 条），用户可指定总条数或类别。

搜索导航（`$search_keyword` 为当前关键词变量，需 URL encode）：
```bash
encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$search_keyword'))")
chrome-agent --connect http://127.0.0.1:9222 --stealth goto "https://www.xiaohongshu.com/search_result?keyword=${encoded}&type=51"
```

`type=51` 是笔记类型过滤。

### 翻页（无限滚动 + 虚拟 DOM）

小红书搜索页是无限滚动，且使用**虚拟滚动**——DOM 中始终只保留约 24 个 `section.note-item` 节点（当前视口附近），滚动时复用这些节点渲染新内容。

**关键策略**：先处理完当前屏的所有帖子，再滚动加载下一屏，避免虚拟滚动导致元素被移除。

```
已收集 ID = Set()
处理计数 = 0

循环：
  1. 提取当前屏所有 note-item，过滤（去重、律师账号、教程类）→ /tmp/xhs-filtered.txt
  2. **逐个处理完当前屏的所有过滤后帖子**（点入、判断、评论、写CSV、返回）
  3. 当前屏处理完后，分段滚动加载下一屏：
     for i in {1..2}; do
       chrome-agent --connect http://127.0.0.1:9222 eval "window.scrollBy(0, $((300 + RANDOM % 200)))"
       sleep $((1 + RANDOM % 2))
     done
     sleep $((1 + RANDOM % 3))
  4. 每处理 5 条，休息 10-20 秒
  5. 若累计达到目标条数或连续两屏无新帖，停止
```

提取当前屏帖子并过滤（一步完成）：
```bash
# 提取列表到变量
xhs_list=$(chrome-agent --connect http://127.0.0.1:9222 eval "[...document.querySelectorAll('section.note-item')].slice(0, 30).map((el, idx) => {
  const title = el.querySelector('.title span')?.innerText || '';
  const author = el.querySelector('[class*=\"name\"]')?.innerText?.split('\\n')[0] || '';
  const link = el.querySelector('a')?.href || '';
  const id = link.match(/\\/explore\\/([a-f0-9]+)/)?.[1] || '';
  return \`\${idx+1}|\${title}|\${author}|\${id}\`;
}).join('\\n')")

echo "$xhs_list"

# 一次过滤：去重 + 律师账号 + 已评论 + 教程类标题
while IFS='|' read -r idx title author post_id; do
  # 跳过空行和无效行
  [ -z "$post_id" ] || [ "$post_id" = '"' ] && continue

  # 过滤律师/机构账号
  echo "$author" | grep -qiE '律师|法务|法援|说法|普法|律所|维权.*中心|官方|平台' && continue

  # 检查是否已存在于 CSV（已录入）
  grep -q "$post_id" ~/xhs-legal-leads.csv 2>/dev/null && continue

  # 检查是否已评论（今日评论日志）
  [ -f ~/xhs-comments-$(date +%Y-%m-%d).log ] && grep -q "$post_id" ~/xhs-comments-$(date +%Y-%m-%d).log && continue

  # 过滤标题：经验分享、教程、方法论
  echo "$title" | grep -qiE '方法|步骤|教你|技巧|经验|攻略|指南|提醒|别再|策略|新规|高手' && continue

  echo "$idx|$title|$author|$post_id"
done < <(echo "$xhs_list") > /tmp/xhs-filtered.txt

echo "待处理: $(wc -l < /tmp/xhs-filtered.txt) 条（已过滤重复、已评论和教程）"
```

滚动触发加载（分段滚动）：
```bash
# 分 2-3 次滚动，每次 300-500px
for i in {1..2}; do
  chrome-agent --connect http://127.0.0.1:9222 eval "window.scrollBy(0, $((300 + RANDOM % 200)))"
  sleep $((1 + RANDOM % 2))
done
sleep $((2 + RANDOM % 3))
```

**停止条件**：目标条数（默认 30）已达到，或连续 2 次滚动后 `已收集链接 Set` 无新增。

## 第四步：逐帖阅读与评估

**关键原则：优化验证策略，节省 token。**

- **点击操作**：点击后默认成功，不立即验证 URL
- **后续操作失败时**：才检查页面状态（截图或检查 URL），判断是否遇到验证码或页面异常
- **评论框验证**：如果找不到 contenteditable 元素，说明可能未进入详情页或遇到异常，此时再检查

对搜索结果中的每条笔记：

1. **必须从搜索页面点击进入**，不可直接 goto 帖子 URL：
   - 小红书链接包含 `xsec_token` 签名参数，直接访问 `/explore/<id>` 会 404
   - **严禁使用 eval 点击任何元素**（包括 `element.click()`、`dispatchEvent` 等）：会触发 300031 反爬，必须使用 `chrome-agent click`
   - **必须点击封面图片（image），不是标题文字（link）**：真实用户点击的是帖子封面图，点击标题链接通常无效
   - 点击策略（按优先级尝试，全部失败则跳过该帖）：
     1. 点击封面图（`image` 元素，通常位于 link 内部）
     2. 点击外层图片（封面图上方的独立 `image` 元素）
     3. 以上都失败 → **跳过该帖**，绝不降级为 eval 点击
   ```bash
   # 第一步：用 inspect 找到帖子封面图的 uid（不是标题 link）
   chrome-agent --connect http://127.0.0.1:9222 inspect | grep -B5 "标题关键词" | head -15
   # 输出示例：
   #   uid=n112129 image          ← 点击这个（封面图，通常在 link 内部）
   #   uid=n112130 link
   #   uid=n112131 link "深圳欠薪垫付"
   #   uid=n112097 image          ← 或这个（外层封面图）
   # 优先点击 link 内部的 image，其次点击外层 image

   # 第二步：用 chrome-agent click 点击封面图（不要用 eval，不要点 link）
   chrome-agent --connect http://127.0.0.1:9222 click n112129
   sleep $((2 + RANDOM % 2))

   # 第三步：验证是否进入详情页
   url=$(chrome-agent --connect http://127.0.0.1:9222 eval "location.href")
   # 如果 URL 仍是 search_result → 点击未生效，尝试下一个 image 元素
   # 如果 URL 是 /explore/xxx → 成功进入详情页
   # 如果 URL 包含 /404 或 error_code=300031 → 触发反爬，立即停止等待恢复
   ```

2. 用 eval 提取正文和发帖时间（snapshot 通常已包含文本，必要时补充）：
   ```bash
   # 提取正文
   chrome-agent --connect http://127.0.0.1:9222 eval "document.querySelector('.desc')?.innerText || document.querySelector('#detail-desc')?.innerText || ''"

   # 提取发帖时间
   chrome-agent --connect http://127.0.0.1:9222 eval "document.querySelector('.date, .time, [class*=\"date\"], [class*=\"time\"]')?.innerText || ''"
   ```

3. **提取标签快速判断**（优化：减少无效深度分析）：
   ```bash
   # 提取所有标签
   chrome-agent --connect http://127.0.0.1:9222 eval "[...document.querySelectorAll('[class*=\"tag\"], [class*=\"topic\"], a[href*=\"search_result\"]')].map(el => el.innerText.trim()).filter(t => t.startsWith('#')).join(' ')"
   ```

   **标签快速过滤规则**：

   | 类型 | 标签示例 | 判断 |
   |------|---------|------|
   | ✅ 明确求助 | #求助贴 #在线求助 #裁员公司赔偿 #仲裁 #维权 #法律咨询 | 继续深度分析 |
   | ❌ 情绪分享 | #碎碎念 #辞职日记 #离职 #职场感悟 #裸辞 #emo | 直接跳过 |
   | ⚠️ 模糊/无标签 | #职场 #打工人 或无标签 | 继续深度分析 |

   **流程**：
   - 如果标签明确属于"情绪分享"类 → 直接跳过，返回搜索页
   - 如果标签属于"明确求助"类或模糊/无标签 → 继续步骤 4 的深度判断

4. **Claude 判断**：阅读提取到的标题 + 正文 + 标签 + 发帖时间，按以下标准决定录入 or 跳过：

### ✅ 录入（真实法律需求）

- 发帖人**本人或家属**描述了具体困境（被侵权、纠纷、人身伤害等）
- 有明确或隐含的求助意图（"怎么办"、"有没有律师"、"能告吗"、"求指导"）
- 内容有具体事实陈述，不是泛泛讨论
- **发帖时间在近 2 年内**（优先当年和去年，超过 2 年的降低优先级）

### ❌ 跳过

- 普法科普帖（无具体案情）
- 律师自我推广 / 广告帖
- 新闻转发或旁观者评论
- 内容与法律完全无关
- **发帖时间超过 3 年**（问题很可能已解决，线索价值低）

### 作者名快速过滤（先看作者，再决定是否点进去）

从搜索结果列表就能看到作者昵称，以下模式直接跳过，不用点进去：

| 模式 | 示例 |
|------|------|
| 含「律师」「法务」「法援」「说法」「普法」 | 裴你说法、深圳劳动律师、法务张三 |
| 含地名+法律词 | 广州律师事务所、北京劳动法 |
| 含「维权」+机构感 | 劳动维权中心、维权帮帮帮 |
| 明显机构账号（全大写/带「官方」「平台」） | 劳动法官方、维权平台V |

**真实用户昵称特征**：随机字符、emoji、生活化词汇、姓名/小名，例如 `fengzi`、`打工人阿强`、`小李🌸` 等。

模糊情况：**偏向录入**，案情摘要加"[待核实]"。

## 第五步：提取信息、生成评论、发表、写入 CSV

确认录入后，**依序**完成：提取字段 → 生成评论 → 发表评论 → 写入 CSV。写 CSV 在评论之后，这样评论内容可以一并记录。

### 1. 提取字段

从当前详情页提取：

- **标题**：笔记标题
- **帖子链接**：`chrome-agent --connect http://127.0.0.1:9222 eval "location.href"`
- **作者昵称**：发帖人昵称
- **案情摘要**：1-2 句话概括核心诉求，不超过 100 字；英文逗号替换为中文逗号
- **法律领域**：劳动 / 婚姻家事 / 房产合同 / 消费维权 / 工伤交通 / 刑事 / 其他
- **紧迫度**：
  - 高：有明确时间压力（开庭在即、被强制执行、正在遭受伤害）
  - 中：已发生纠纷但尚无紧急时限
  - 低：咨询阶段，尚未实际发生
- **发帖时间**：YYYY-MM-DD 格式
  - 小红书常见："2天前"、"1周前"、"2026-04-20"，需换算；无法提取时填 "未知"

### 2. 生成评论

```bash
# 读取律所信息（session 内首次执行即可）
cat ~/.claude/skills/xhs-legal-leads/lawinfo.txt

# 读取所有已发评论（去重），避免重复。必须逐条比对，不能只看今日。
cut -d',' -f10 ~/xhs-legal-leads.csv | sort -u
```

根据 **法律领域 + 案情摘要 + 紧迫度**，结合 lawinfo.txt 对应领域亮点，Claude 生成 1-2 句自然评论。

### ⛔ 评论重复禁令（CRITICAL）

**每条评论必须从案情摘要中提取至少 1 个具体细节写入评论**，确保评论与帖子内容一一对应。严禁生成可由其他帖子复用的通用评论。

**生成前强制检查**：
1. 读取所有已有评论：`cut -d',' -f10 ~/xhs-legal-leads.csv | sort -u`
2. 新评论必须与 CSV 中**每条**已有评论的编辑距离 ≥ 10 个字
3. 新评论必须包含**帖子特有细节**（如具体金额、时间、公司名、伤害类型、关系称谓等），这些细节直接来自案情摘要
4. 如果案情摘要没有足够细节可以嵌入 → 评论角度必须与已有评论**明显不同**（换一个法律切入点：时效→证据→协商策略→法律后果→类似案例）

**反例（会被判重复）**：
- 「劳动维权关键在证据和时效，不要超过一年仲裁时效。我们劳动争议处理得多，私信帮你分析。」→ 通用模板，无任何帖子细节
- 「被裁员补偿太低可能不合理，N是法定最低，违法解除是2N。工龄越长补偿越多，别轻易签协商协议。我们劳动争议处理得多，私信帮你分析。」→ 只有法律常识，没有嵌入具体案情

**正例**：
- 帖子「工伤住院 公司不认」→ 嵌入「工伤认定」和「住院记录」：「工伤认定有时效，住院记录是关键证据。第一时间申请认定比事后维权容易得多。我们劳动这边工伤案子处理得多私信帮你看看。」
- 帖子「押金不退 中介跑路」→ 嵌入「押金」和「中介跑路」：「中介跑路押金不退可以联合其他租客一起报案，人数多立案快。我们这边处理过类似租赁纠纷私信聊聊。」

**生成评论前先过 checklist**：
- [ ] 这句评论能不能原样贴到另一篇帖子下？如果能 → 重写
- [ ] 评论里有没有帖子特有的具体事实（金额/时间/地点/人物/伤害/物品）？如果没有 → 重写
- [ ] 这句评论和 CSV 里已有评论的相似度是否过高？逐条比对 → 如果高度相似 → 重写

- **先共鸣，后引导**：第一句回应当事人处境，第二句自然带出律所能力或建议私信
- **领域对应亮点**（从 lawinfo.txt 中提取）：
  - 劳动/工伤 → 劳动争议团队、仲裁经验
  - 婚姻家事 → 婚姻家事核心业务、专业部门
  - 刑事 → 刑事辩护基础业务
  - 房产合同 → 房地产核心业务、合同纠纷
  - 消费维权 → 民商事纠纷、累计服务客户多
  - 深圳案件 → 紧邻深圳中院、区位优势、深圳执业律师多
- **紧迫度高** → 语气更急切，主动提"有时效"或"尽快"
- **简短优先**：不超过 50 字，绝不超过 3 行
- **无广告感**：不出现"收费"、"免费咨询"、"专业律师团队"等推销词；律所名字可代之以"我们律所"或"我这边"

### 3. 发表评论（拟人化）

**评论区 DOM 结构（关键）**：

评论区是一个 `div.engage-bar`，有三种状态：

| 状态 | engage-bar class | 发送按钮 |
|------|-----------------|----------|
| 未激活（没点过输入框） | `class="engage-bar"` | `<button class="btn submit gray" disabled="">` |
| 已激活（点过输入框但无文字） | `class="engage-bar active"` | `<button class="btn submit gray" disabled="">` 仍 disabled |
| 已输入文字 | `class="engage-bar active"` | `<button class="btn submit">` **不再 disabled，无 gray** |

输入框选择器：`p#content-textarea[contenteditable="true"]`

**激活 + 发送流程**：
1. 点击 `p#content-textarea` → engage-bar 变为 `active`
2. 输入文字 → 发送按钮从 `disabled` 变为可用（去掉 `gray` 类和 `disabled` 属性）
3. 点击发送按钮 → 评论发出
4. 验证：检查页面正文是否出现评论内容 + `刚刚` 时间标记

```bash
# 1. 查找底部评论框 — 优先用 p#content-textarea
chrome-agent --connect http://127.0.0.1:9222 inspect | tail -30
# 找到类似 "uid=nXXXXX paragraph" 且 id="content-textarea" 的元素
# 或直接找最后一个空 paragraph（页面底部评论输入区）

# 2. 点击评论框激活 engage-bar（禁止用 eval，必须用 chrome-agent click）
chrome-agent --connect http://127.0.0.1:9222 click n<paragraph_uid>
sleep 1

# 3. 用 execCommand('insertText') 输入文字（关键：这种方式能正确触发 React 状态更新，解禁发送按钮）
# 不要用 innerText += char 的方式，那不会解禁发送按钮
comment="<Claude 生成的评论内容>"
chrome-agent --connect http://127.0.0.1:9222 eval "
const input = document.querySelector('p#content-textarea[contenteditable=\"true\"]');
if (input) {
  input.focus();
  input.innerText = '';
  document.execCommand('insertText', false, '${comment}');
  input.dispatchEvent(new Event('input', {bubbles: true}));
  input.dispatchEvent(new Event('change', {bubbles: true}));
}
"
sleep 1

# 4. 确认发送按钮已解禁（不再是 disabled/gray）
chrome-agent --connect http://127.0.0.1:9222 inspect | grep 'button.*发送'
# 正确状态：uid=nXXXXX button "发送" （无 disabled 字样）
# 错误状态：uid=nXXXXX button "发送" disabled → 文字未正确触发 React 更新，重新执行步骤 3

# 5. 点击发送
chrome-agent --connect http://127.0.0.1:9222 click n<button_uid>
sleep 3

# 7. 验证结果：检查评论区是否出现刚发的评论内容（通常在第一条，带"刚刚"时间标记）
# CRITICAL: 小红书保留评论草稿，发送后 contenteditable 不会清空，不能用输入框是否为空判断成败
sleep $((1 + RANDOM % 2))
success=$(chrome-agent --connect http://127.0.0.1:9222 eval "
  // 取评论前 20 字去页面正文搜索，匹配到且上下文含"刚刚"即为成功
  const snippet = '${comment}'.substring(0, 20);
  const body = document.body.innerText;
  const idx = body.indexOf(snippet);
  if (idx >= 0) {
    const ctx = body.substring(Math.max(0, idx - 5), idx + 60);
    ctx.includes('刚刚') ? 'success' : 'found_but_no_ganggang';
  } else {
    'not_found';
  }
" | tr -d '"' | tr -d "'")

if [ "$success" = "success" ]; then
  echo "✓ 评论成功"
  comment_content="$comment"
  echo "$post_id | $title | $author | $comment" >> ~/xhs-comments-$(date +%Y-%m-%d).log
else
  echo "⚠️ 评论未确认成功 (result=$success)，用 Enter 键兜底"
  
  # Enter 键兜底
  chrome-agent --connect http://127.0.0.1:9222 eval "
  const input = document.querySelector('[contenteditable=\"true\"]');
  if (input) {
    input.focus();
    input.dispatchEvent(new KeyboardEvent('keydown', {key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true}));
  }
  "
  sleep 3
  
  # 再次验证
  retry=$(chrome-agent --connect http://127.0.0.1:9222 eval "
    const snippet = '${comment}'.substring(0, 20);
    const body = document.body.innerText;
    const idx = body.indexOf(snippet);
    (idx >= 0 && body.substring(Math.max(0, idx - 5), idx + 60).includes('刚刚')) ? 'success' : 'failed';
  " | tr -d '"' | tr -d "'")
  
  if [ "$retry" = "success" ]; then
    echo "✓ Enter 兜底成功"
    comment_content="$comment"
    echo "$post_id | $title | $author | $comment" >> ~/xhs-comments-$(date +%Y-%m-%d).log
  else
    echo "⚠️ 评论失败，检查页面状态"
    chrome-agent --connect http://127.0.0.1:9222 screenshot
    
    page_title=$(chrome-agent --connect http://127.0.0.1:9222 eval "document.title" | tr -d '"')
    if echo "$page_title" | grep -qi "验证\|captcha\|安全"; then
      echo "❌ 检测到验证码，停止采集"
      echo "请在浏览器中手动完成验证后，告知继续"
      exit 1
    fi
    
    echo "⚠️ 跳过评论，写入错误日志"
    comment_content=""
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $post_id | $title | $author | $comment" >> ~/xhs-comment-errors.log
  fi
fi
```

### 4. 写入 CSV

评论结果确认后追加一行（摘要、评论内容中的英文逗号替换为中文逗号）：

```bash
echo "$search_keyword,$title,$url,$author,$summary,$domain,$urgency,$collect_time,$post_time,$comment_content" >> ~/xhs-legal-leads.csv
```

**CSV 格式示例：**
```
欠薪维权,公司拖欠工资3个月不给,https://...,打工人小李,被拖欠工资3个月老板失联求助,劳动,高,2026-04-23,2026-04-15,欠薪时间越长追回来越难仲裁有时效要注意。我们劳动这边接过不少类似案子可以私信聊聊情况。
```

## 第六步：返回继续

```bash
chrome-agent --connect http://127.0.0.1:9222 back
sleep $((2 + RANDOM % 2))  # 随机延迟 2-3 秒
```

**批次休息**：每处理 3 条帖子后：

```bash
if [ $((processed_count % 3)) -eq 0 ]; then
  echo "✓ 已处理 $processed_count 条，休息 20-40 秒..."
  sleep $((20 + RANDOM % 20))
fi
```

## 第七步：错误处理

遇到以下情况立即停止：

1. **404 或 300031 错误**（反爬触发）：
   ```bash
   echo "⚠️ 检测到反爬机制（错误码: 300031）"
   echo "等待 30-60 秒后重试..."
   sleep $((30 + RANDOM % 30))
   echo "请检查浏览器是否需要验证码"
   # 询问用户是否继续
   ```

2. **验证码出现**：
   - 暂停脚本
   - 提示用户在浏览器中手动完成
   - 等待用户确认
   - 继续前等待 10 秒

3. **连续失败 3 次**：
   - 停止当前关键词
   - 建议休息 10-15 分钟后重新启动

## 单次会话限制

**重要**：单次会话不要超过 30 条线索。建议策略：

- 采集 20-30 条后主动停止
- 休息 10-15 分钟
- 关闭并重新启动浏览器
- 继续采集下一批

## 反爬保护措施（CRITICAL）

**必须严格遵守以下规则，否则会被封号：**

### 1. 随机延迟

每次操作后使用**随机延迟**，不要固定间隔：

```bash
# 搜索后等待
sleep $((3 + RANDOM % 3))  # 3-5 秒

# 滚动后等待
sleep $((2 + RANDOM % 2))  # 2-3 秒

# 点击帖子后等待
sleep $((2 + RANDOM % 2))  # 2-3 秒

# 返回搜索页后等待
sleep $((2 + RANDOM % 2))  # 2-3 秒
```

### 2. 分段滚动（模拟人类）

不要一次滚动到底，分多次小幅滚动：

```bash
# 错误：一次滚动到底
chrome-agent --connect http://127.0.0.1:9222 eval "window.scrollTo(0, document.body.scrollHeight)"

# 正确：分段滚动
for i in {1..3}; do
  chrome-agent --connect http://127.0.0.1:9222 eval "window.scrollBy(0, $((300 + RANDOM % 200)))"
  sleep $((1 + RANDOM % 2))
done
```

### 3. 内容为空或反爬触发

遇到连续多条帖子内容为空：
- 切换到下一个关键词继续采集

## 完成汇报

每个关键词跑完输出一行小结：

```
[关键词] 扫描 N 条 → 录入 M 条（劳动×2 婚姻×1 ...）
```

全部完成后告知 CSV 路径和总线索数。
