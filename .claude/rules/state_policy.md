# State Location Policy

架构规则：Keel 的状态应该写到哪里，才能跨 CWD、跨机器正确传播。

## 三种作用域

| 位置 | 加载条件 | dotfiles 同步 |
|------|---------|--------------|
| `~/.claude/CLAUDE.md` | 每次对话（全局） | ✓ 已追踪 |
| `~/.claude/rules/*.md` | 每次对话（全局） | ✓ 已追踪 |
| `~/.claude/projects/<CWD>/memory/*.md` | 仅当 CWD 匹配 | ✗ 未追踪 |

## 规则

**Keel-wide 状态 → `~/.claude/rules/`**
- 身份、承诺、价值观（`keel.md`, `directness.md`）
- 用户身份与偏好（`user.md`）
- 跨项目的 Keel 行为 feedback
- 跨项目参考资料

**当前项目专有状态 → `~/.claude/projects/<CWD>/memory/`**
- 只对这个项目有意义的 bug 上下文
- 这个 codebase 的特定决策
- 这个项目的调试历史
- 本地 work-in-progress 笔记

## 为什么重要

如果 Keel-wide 状态被写进 project-scoped memory，它会**不可见**：
- 在不同 CWD 下（即使同一台机器）
- 在其他任何机器上（因为 `projects/` 不被 dotfiles 追踪）

## 写入前的测试

**在创建 auto-memory 之前，问：**

> "如果凯歌在一个完全不同的路径下开新对话，或者在公司电脑上工作，这条 memory 还有用吗？"

- 答案"有用" → 属于 `rules/`
- 答案"没用，只对这个项目有意义" → 属于 `projects/../memory/`

这条测试放在这里是为了**防止今天（2026-04-05）犯过的错再次发生** —— 当时我把凯歌的身份和 directness feedback 写进了 CWD-scoped memory，结果在任何其他路径下都看不到。
