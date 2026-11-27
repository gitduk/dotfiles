# rig 配置字段语义

来源：`~/rig/src/config.rs`、`src/sources/repo.rs`、`src/sources/mod.rs`、`src/version/github.rs`。行为描述以这些代码为准。

## [settings]

| 字段 | 默认 | 说明 |
| --- | --- | --- |
| `prefix` | `~/.local` | 安装根，命令链接到 `<prefix>/bin` |
| `parallel` | `8` | `rig install` 并发工具数，`1` = 串行 |

`[settings]` 整段可省，省了就是上表默认值。

## 共享字段（repo / git / cargo / node / apt / curl）

| 字段 | 形态 | 语义 |
| --- | --- | --- |
| `description` | 字符串 | `rig list` 显示 |
| `bin` | 字符串 / 列表 / map | 见下 |
| `env` | `{ K = "V" }` | 写进 `init.zsh` 的导出；`~` 会展开。`lazy` 时推迟到首次使用 |
| `eval` | 字符串 或 `{ cmd, cache = bool }` | shell 启动时执行的命令（`zoxide init zsh` 这类）。rig 探测其输出是否依赖 cwd / `TERM` / `PATH` / `SHLVL`，稳定就把输出内联进 `init.zsh` 缓存，不稳定就每次启动现跑；`cache` 可强制判定，`rig sync --force` 重探 |
| `run` | 字符串 / 列表 / `'''` 块 | 原样执行的 shell 文本（alias、export），**不捕获输出**，所以永远内联。`'''` 块按行拆、丢空行 |
| `completions` | 见下 | 默认 `true` |
| `setup` | 字符串 / 列表 / `{ install, update }` | 安装钩子：`sh -ec <cmd>`，cwd 是解包（repo/git 为 clone）根，`-e` 保证多步里第一步失败就失败。同一次安装里 `bin` 被解析之前跑 |
| `lazy` | bool | 把 `env`/`eval`/`run` 推迟到该工具命令首次调用。必须在 shell 启动就观察事件的工具不能开 |
| `bind` | `"key:函数名"` | 仅配 `lazy` 用：该键先跑一次占位 ZLE 函数完成延迟初始化，再绑到真函数 |

### bin 的三种形态

- `bin = "rg"`：命令名 `rg`，在解包树里找**文件名为 `rg`** 的文件，任意深度都算；找不到或找到多个都报错（报错里会列出实际文件名，照它改）。
- `bin = ["yazi", "ya"]`：多个命令名，各自同名查找。
- `bin = { "target/release/wallust" = "wallust" }`：key 是**相对解包根**的路径 glob（只支持 `*`），value 是落地的命令名。同名文件在多处、或文件在上游原名下（裸二进制、AppImage）时用这个，必要时配 `extract = false`。

省略 `bin` 时命令名 = `name` 最后一段（`BurntSushi/ripgrep` → `ripgrep`，所以想叫 `rg` 就必须写 `bin`）。

### completions 的四形态

- `true`（默认）：把解包树里所有 `_*` 文件链进 `~/.local/share/rig/completions/`（递归全树，`autocomplete/_foo` 这种子目录里的也算）。上游附带的 `_foo.ps1` 也会被链上，本机那目录里已有多个同款，属惯例，不必为此收紧。
- `false`：什么都不链。
- `{ path = "completions/_foo" }`：只链这一个，路径相对安装根。
- `{ generate = "./uv generate-shell-completion zsh > _uv" }`：在**二进制所在目录**跑这条命令（不总是归档根——嵌套 `bin` 时取二进制父目录），跑完仍按 `_*` 链接。上游不提供补全文件时用这个；命令得自己写文件。

## [[repo]] 专属

| 字段 | 说明 |
| --- | --- |
| `name` | `owner/repo` |
| `host` | `github`（默认）/ `codeberg` |
| `bpick` | 单个 glob 或列表，见下 |
| `extract` | 缺省自动识别；`false` = 当裸二进制直接拷，文件名保持上游原名 |

**`bpick` 是过滤器，不是候选集**：列表里每个普通 glob 都必须命中，每个 `!` 前缀的都必须不命中。必须至少有一个普通 glob（只有 `!` 会被拒绝，因为那等于「排除剩下的全要」）。glob 只支持 `*`，`?` 和字符类不支持。

**不写 `bpick`** 时会拿 `name` 里同时含架构（`x86_64`/`aarch64`）和系统（`linux`/`darwin`）的资产；命中多个会交互式让你选，非 TTY 直接报错。所以一个 release 里有同平台多个变体（`-stealth`/`-no-render`/架构与平台分开命名）时，一定显式写 `bpick`。

版本取 `/releases/latest`——不含 prerelease 和 draft，也不能钉某个版本。整个仓库只有 prerelease 时该端点返 404，rig 回退到 `/releases` 列表里第一个非 draft 条目，所以全 prerelease 的项目照样能装。

**解包**：`.tar.gz`/`.tgz`、`.zip`、`.deb`（走 `dpkg-deb -x`，不碰系统包库，路径保留 `usr/bin/...`）。其他后缀会要求 `extract = false`。解完若只剩一个顶层目录就上提一层；`__MACOSX`、`.DS_Store`、`Thumbs.db` 当垃圾删掉。

## [[git]]

clone 后跑 `setup` 构建，`bin` 相对 clone 根（`{ "target/release/foo" = "foo" }`）。版本 = HEAD sha。上游不给预编译包时用这个，`host` 同样支持 codeberg。

## 其余 section

- `[[cargo]]`：`cargo install <name>`，版本查 crates.io。名字就是 crate 名。
- `[[node]]`：`manager = auto`（先 bun 后 npm）/ `bun` / `npm`；显式指定的不回退。
- `[[apt]]`：`apt-get install`，版本用 dpkg 报告的。需要 `sudo`，所以 apt 条目最先跑且串行；`rig update` 里 candidate 变了才重装。
- `[[curl]]`：拉 `url` 当脚本跑，版本记 `unversioned`。**整体 `rig update` 跳过它**，只有点名 `rig update <tool>` 才重跑。
- `[[plugin]]`：clone 到 `plugins/`，zsh `source` 掉 `source` 字段指的文件，紧接着跑 `run`。没有 `bin`/`eval`/`setup`/`lazy`（插件不按命令名调用），`run` 是它唯一和 Common 同形的字段。

## 身份、校验、更新判定

- 工具 key = `name` 最后一段；`[[node]]` 例外，用完整包名（含 scope），因为 npm 就这么键。`rig install/update/remove/which` 三种写法都认：key、完整 name、声明的 bin 名。`rig which rg` 打印的是工具 key（`ripgrep`），不是 `owner/repo`。
- 跨 section 的 key 重复直接解析失败——`rig.lock` 按 key 存，两条会互相覆盖。
- 更新只看相等：锁里的版本字符串和上游 tag 逐字节比，不做 semver 排序。所以 per-build tag（`<ver>-<runid>`）可能被判成「有新版」而实际是老 minor；tag 换了形状会触发一次重装。
- `rig update --check` 只报告、不装，有新版退出码 2。

## 报错怎么读

| 报错 | 动作 |
| --- | --- |
| `no release asset matches bpick` / `no release asset auto-matches your platform` | 重跑流程第 1 步，照真实资产名写 `bpick` |
| `bpick matches multiple assets` | 加 `!*别的平台*` 或把 glob 写窄 |
| `no file named X found in the unpacked archive` | 报错列出实际文件；用 map 形态的 `bin` 指到真实路径 |
| `no file matches \`pattern\` in the unpacked archive` | 同上，路径 glob 相对解包根写错 |
| `GitHub API rate limit likely exhausted` | `gh auth login` 或设 `GITHUB_TOKEN` |
