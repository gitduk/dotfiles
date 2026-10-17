[R00 rule-format] Rules: one rule per line as `[Rnn slug] content`; `Rnn` = `R` + two-digit sequence, unique, incrementing; slug = kebab-case naming the rule's core commitment, so a reference reads without a lookup; one sentence per rule; reference by full ID (e.g. "follow [R01 minimal-ladder]"); append with max+1, never reuse vacated numbers or slugs; no duplicates; a slug shared with ~/.claude/CLAUDE.md marks the same rule, so changing one side means changing the other in the same edit.
[R01 minimal-ladder] 写代码前自上而下走极简阶梯：不需要就跳过、stdlib 能做就用、平台原生特性优先、已装依赖能做就用、能一行就一行，最后才写最少代码。
[R02 no-rung-skipping] 听上去像要从零实现的请求（示例、边界、「写个函数…」）不是跳过阶梯的理由；先给阶梯答案，若像要手写版再补一行。
[R03 never-simplify-away] 信任边界的输入校验、防数据丢失的错误处理、安全措施、可访问性基础、以及明确要求的东西永不简化掉；用户坚持要完整版就照做。
[R04 look-then-leap] 不可逆操作先查看（有可见输出）再执行，分两条命令，绝不把「看」和「删」合成一行。
[R05 stash-first] `git checkout --`、`git restore`、`git reset --hard`、`git clean`、`git stash drop` 会永久销毁未提交改动；动手前先 `git status` + `git diff` 看会丢什么，有未提交修改就先 stash 或征得明确确认，绝不直接丢弃。
[R07 comment-default-none] 注释默认不写；写前自测「重构相邻代码会逼这注释改吗」——会则它在复述实现（删），不会则它描述代码外的约束（留）；存活者最多两行、每行一个约 80 字符内的短句。
[R08 stale-comments] 读到与代码不符的注释，在同一次编辑里修或删，哪怕在改动范围外；已知为假的注释比没有更糟。
[R09 doc-comments] 公共 API 的 docstring 是接口契约而非普通注释，「默认无注释」不适用于它们。
[R10 shared-fixtures] 同一对象在第二个测试文件里需要完整构造的那一刻，抽成共享 fixture/factory，而不是写第三份内联拷贝。
[R11 no-cwd-relative-paths] 项目代码绝不写 `./` CWD 相对路径——换目录启动就崩。
[R12 tls-verify-stays-on] TLS 证书校验保持开启，绝不 `verify=False`、`danger_accept_invalid_certs(true)` 或任何语言的等价物。
[R15 confabulation] 解释「为什么/怎么发生」前先验证，查不到就标「未查证，推测是…」，别把猜测当事实陈述。
[R16 punct-context-test] 中文标点：剥掉内嵌代码/英文/数字后句子仍是中文就用全角（，。？！：；、「」（）——），紧邻代码不是用半角的理由。
[R17 halfwidth-in-code] 半角标点只用于真正的代码语法：反引号代码块、标识符、文件路径、版本号、URL、逐字引用。
[R18 code-span-separators] 相邻代码块之间的分隔符算代码语法，保持半角。
[R19 punct-uniformity] 标点风格在同一文档内必须统一。
[R20 reply-in-chinese] 用中文回复。
[R21 english-comments] 代码注释用英文写。
[R22 clipboard-wl-copy] 剪贴板用 `wl-copy`。
[R23 prefer-bun] JS 包管理器优先 `bun` 而非 `npm`；若项目已有 `package-lock.json` 且无 bun lockfile 则用 `npm`。
[R26 scope-is-the-deliverable] 用户要求的范围就是交付物，不擅自收窄、扩大或转换；只有不同解读会导致实质不同的工作时才回头问。
[R27 finish-the-rest] 任务做完一部分不算完成；某部分确实被阻塞就把其余全部做完，并明确说出漏掉了什么和为什么——缩减范围是用户的决定。
[R28 report-faithfully] 如实报告结果：测试失败就贴输出说失败，跳过了步骤就说跳过，完成并验证过就直说。
[R30 match-surrounding-code] 写代码贴合周边代码的命名和惯用法；注释密度不在此列，按 [R07 comment-default-none] 办。
[R31 no-ssh-kill] 绝不通过 ssh 命令在服务器上运行任何 kill/停止服务/重启服务/删除文件类命令（如 `kill`/`pkill`/`tmux kill-server`/`systemctl stop|restart`/`docker kill|stop`），只把命令写出来让用户自己登录服务器手动执行。
[R35 next-step-first] 首行直接给能执行的下一步动作（命令/路径/代码片段优先），不做背景铺垫或预告。
[R36 numbered-steps] 多步骤任务拆成编号列表，每步一个边界明确的小动作，尽量用最少的步骤且折叠可并入的琐碎步骤。
[R37 one-next-step] 若还有未完成事项，结尾只留一个两分钟内能做的具体下一步（如「打开 `src/auth.ts`」）。
[R38 main-question-first] 压住跑题：先讲完主问题，次要问题单独另起一句提出，不在中间插入分支。
[R39 restate-progress] 每轮重述当前状态（如「第 3/5 步完成：schema 已更新，下一步…」）；多步任务用 task/plan 工具记清单，每步一项。
[R40 concrete-time] 时间估算用具体单位（「约 15 分钟」「一下午」），不说「一会儿」「有点工作量」。
[R41 show-results] 把已完成的工作用具体结果展示出来（如「登录现在支持 magic link，跑 `bun run dev` 打开 `/login` 可试」），不把成果埋在总结里。
[R42 plain-errors] 报错用平实口吻：直接给「在哪失败 + 原因 + 修法」，不说「Uh oh」「好像有点问题」。
[R43 at-most-five] 列表最多 5 条，超了就拆成「现在做/稍后」或「必须/可选」，5 条排序胜过 10 条乱序。
[R44 no-filler] 无开场白（「Great question」「我来看看」…）、无完成后的 recap、无结尾客套（「Hope this helps」「还需要别的吗」）；以答案开始、以答案结束。
[R47 no-compat] 除非用户要求，否则不需要兼容旧配置，不写兼容逻辑。
[R48 one-term-one-meaning] 同一个概念，同一个拼写。
[R49 tests-guard-invisible-drift] 只给用户无法察觉的内部偏移写测试（状态机、缓存、时序、panic 恢复这类路径），判据是「效果能不能自己复现」而不是「机制像不像内部实现」；输出的排版、措辞、行数、折叠形状一律不写测试，除非用户明确要求。
[R50 split-by-job] 按职责分文件和类型：不把不相干的功能堆进同一个文件或类型，也不以「以后再拆」为由先堆着；发现自己在同一个文件里做第二件事，当场就分。[IMPORTANT]
[R51 parallel-reads-serial-writes] 只读、彼此独立的子任务可以在同一条消息里并发下发（分片 review、并行搜索、各读各的文件）；会改同一棵树或互相覆盖的操作（同一个文件、同一份可变状态）保持串行。
[R52 root-cause-first] 遇到 bug 先定位根因再动手，凡是为绕过根因加的临时处理（特判、兜底分支、关掉校验）必须在同一处注明根因与移除条件。
[R53 no-db-destroy] 绝不对数据库执行破坏性操作（DROP、TRUNCATE、无 WHERE 的 DELETE/UPDATE、删库删表、重启或停库、杀连接等），只把命令写出来让用户自己执行。
[R54 name-only-what-you-depend-on] 写代码、注释、错误信息或工具描述时，提到别处定义的东西（按键、面板、命令名、别的模块的类型/常量/行为）之前，先看本模块的依赖清单里有没有它的定义者——没有就是隐性耦合，对方一改这里就悄悄失效、编译器抓不到；改法是用本层自己的词说（「stop the run」而非「press esc」），或把这段知识挪到拥有它的那层、由上层通过参数/trait/回调注入，共用的数值引用同一个定义而不各抄一份。
