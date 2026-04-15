# Review Discipline — 代码审查纪律

任何代码改动都走此流程；纯研究/阅读不触发。

## 流程
1. 写前声明本次防守类别，并叠加 `~/.claude/projects/<CWD>/memory/checklist.md`（若存在）。
2. 实现改动，聚焦当前意图。
3. 宣告完成前做对抗重读：逐项过清单，至少找一处可改点；若 truly trivial，明确说明。
4. 若触发升级条件，主动启动外部 agent 循环：收集发现，分成真 bug / 认同改进 / 拒绝建议；修前两类，显式拒绝第三类并说明理由；若本轮有修改则再验证一轮。
5. 交付时说明：防守类别、对抗重读改了什么、agent 轮次与收敛情况、拒绝项、待凯歌裁决项。

## 通用防守类别
- 正确性：边界、空值、off-by-one、并发、类型安全
- 简洁性：重复、过度抽象、dead code、未使用参数
- 安全性：输入验证、secret、注入、权限检查
- 可读性：命名、结构一致、注释讲 WHY
- 性能（仅热路径）：N+1、不必要分配/拷贝、async 阻塞
- 接口契约：兼容性、破坏性变更
- 测试：golden path + 至少一个 edge case（若项目有测试）

## 升级触发条件
以下场景自动进入 agent 循环：
- 改动 ≥3 文件或总变更 ≥100 行：`code-reviewer` + `simplify`
- 安全敏感：`security-auditor`
- 设计判断不确定：`code-reviewer`
- 项目有测试框架：`tester`

小范围、单文件 CRUD 且不满足以上条件时，可只做对抗重读。

## 循环护栏
- 终止条件：连续一轮无新 severity ≥ medium 问题；或累计 3 轮；或出现建议震荡
- agent 是检测器，不是权威；我保留拒绝风格性/过度抽象建议的判断权

## 项目 checklist
当某项目反复出现同类问题时，追加到 `~/.claude/projects/<CWD>/memory/checklist.md`，并同步更新该项目 `MEMORY.md` 索引。