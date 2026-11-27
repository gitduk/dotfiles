# rig 条目模板（按形态归类）

全部取自 `~/.rig.toml` 的真实条目，可直接改名字复用。资产名是当时的上游文件名；新工具仍要按 SKILL.md 流程第 1 步重新拉一次。

## 1. tar.gz，一个二进制，归档自带 `_*` 补全

```toml
[[repo]]
name = "sharkdp/fd"
bpick = "fd-v*-x86_64-unknown-linux-gnu.tar.gz"
description = "A program to find entries in your filesystem"

[[repo]]
name = "BurntSushi/ripgrep"
bpick = "ripgrep-*-x86_64-unknown-linux-musl.tar.gz"
bin = "rg"                               # 上游叫 ripgrep，要 rg
description = "ripgrep recursively searches directories for a regex pattern"
```

`completions` 省略即 `true`，归档里若有 `_fd` 之类会被自动链上。

## 2. 二进制在嵌套路径里（`usr/bin/`、`target/release/`）

```toml
[[repo]]
name = "fastfetch-cli/fastfetch"
bpick = "fastfetch-linux-amd64.tar.gz"
bin = { "usr/bin/fastfetch" = "fastfetch" }
run = "alias ff='fastfetch'"
description = "A neofetch-like tool for fetching system information"
```

key 是相对解包根的路径 glob，只支持 `*`。

## 3. 裸二进制（没有归档可解）

```toml
[[repo]]
name = "bahdotsh/feedr"
bpick = "feedr-linux-x86_64"
extract = false
bin = { "feedr*" = "feedr" }             # 落地文件名带平台后缀，必须用 glob 指
description = "A modern terminal-based RSS/Atom feed reader"

[[repo]]
name = "antonmedv/fx"
bpick = "fx_linux_amd64"
extract = false
bin = { "fx*" = "fx" }
completions = { generate = "./fx_linux_amd64 --comp zsh > _fx" }
description = "Terminal JSON viewer"
```

`extract = false` 时文件保留上游原名，所以 `bin` 几乎总要写成 map + glob。

## 4. 一个 release 里同平台多个资产：用 `!` 排除

```toml
[[repo]]
name = "obsidianmd/obsidian-releases"
bpick = ["Obsidian-*.AppImage", "!*arm64*"]
extract = false
bin = { "Obsidian-*" = "obsidian" }
description = "Markdown-based knowledge base on top of local files"

# .deb 走 dpkg-deb -x 解包，不进系统包库
[[repo]]
name = "t8y2/dbx"
bpick = ["DBX_*_amd64.deb", "!*beta*"]
description = "lightweight cross-platform database client"
```

列表是「全部命中且全部不命中」，不是候选集。

## 5. AppImage

```toml
[[repo]]
name = "mountain-loop/yaak"
bpick = "yaak_*_amd64.AppImage"
extract = false
bin = { "yaak*" = "yaak" }
description = "Desktop API client for REST, GraphQL, and gRPC"
```

## 6. 一个包两个二进制

```toml
[[repo]]
name = "h4ckf0r0day/obscura"
bpick = "obscura-x86_64-linux-stealth.tar.gz"   # 变体：渲染 + 反检测
bin = ["obscura", "obscura-worker"]              # worker 给 scrape 并行用
description = "The headless browser for AI agents and web scraping"

[[repo]]
name = "Nukesor/pueue"
bpick = ["pueue-x86_64-unknown-linux-musl", "pueued-x86_64-unknown-linux-musl"]
extract = false
bin = { "pueue*-musl" = "pueue", "pueued*-musl" = "pueued" }
completions = { generate = "./pueue-x86_64-unknown-linux-musl completions zsh > _pueue" }
description = "Interact with the Pueue daemon - a command-line task management tool"
```

## 7. 上游不给补全文件：自己生成

```toml
[[repo]]
name = "casey/just"
completions = { generate = "./just --completions zsh > _just" }
run = "alias js='just'"
description = "Just a command runner"

[[repo]]
name = "astral-sh/uv"
bpick = "uv-x86_64-unknown-linux-gnu.tar.gz"
completions = { generate = "./uv generate-shell-completion zsh > _uv" }
description = "An extremely fast Python package manager"
```

`generate` 在二进制所在目录跑，且要自己写 `_名字` 文件。

## 8. `setup` 做安装后修整

```toml
[[repo]]
name = "SagerNet/sing-box"
bpick = "sing-box-*-linux-amd64.tar.gz"
setup = "sudo setcap cap_net_admin=+ep sing-box"   # 提权会打警告，但仍执行
description = "The universal proxy platform"

[[repo]]
name = "Canop/dysk"
bpick = "dysk_*.zip"
setup = "mv completion/_dysk .; mv x86_64-unknown-linux-musl/dysk .; rm -rf */"
description = "dysk displays filesystem information in a pretty table"
```

`setup` 是 `sh -ec`，cwd 为解包根；重排目录、生成文件、改权限都放这里。

## 9. `env` + `run` 一起用

```toml
[[repo]]
name = "Giammarco-Ferranti/deja"
bpick = "deja_*_linux_amd64.tar.gz"
eval = "deja init zsh"
env = { DEJA_CYCLE_KEY = "", DEJA_FUZZY_SEPARATOR = "  " }
description = "Predictive inline shell autosuggestions for zsh"
```

`eval` 是「要跑一条命令拿到 shell 代码」，`run` 是「直接执行这段文本」；拿不准就试 `eval`，rig 会探测能不能缓存。

## 10. `lazy` + `bind`（启动开销大、要按键触发）

```toml
[[repo]]
name = "denisidoro/navi"
setup = "mkdir -p ~/.config/navi/cheats; ./navi info config-example > ~/.config/navi/config.yaml"
env = { NAVI_PATH = "~/.config/navi/cheats", NAVI_CONFIG = "~/.config/navi/config.yaml" }
eval = "navi widget zsh"
bind = "^E:_navi_widget"
lazy = true
description = "An interactive cheatsheet tool for the command-line"
```

## 11. 源码构建

```toml
[[git]]
name = "explosion-mental/wallust"
host = "codeberg"
setup = "cargo +nightly build --release"
bin = { "target/release/wallust" = "wallust" }
description = "A tool to generate color schemes from an image"
```

`setup` 只负责构建（要 `export PATH="$HOME/.cargo/bin:$PATH"` 就写进去），rig 负责把 `bin` 链出去。

## 12. 只有安装脚本

```toml
[[curl]]
name = "direnv/direnv"
url = "https://direnv.net/install.sh"
env = { bin_path = "~/.local/bin" }
eval = "direnv hook zsh"
description = "unclutter your .profile"
```

脚本可能等确认（rustup 那种），单独 `rig i <tool>` 跑，别混进并行批次。整体 `rig update` 会跳过 curl。

## 13. zsh 插件

```toml
[[plugin]]
name = "zsh-users/zsh-completions"
source = "zsh-completions.plugin.zsh"
```

只 clone + `source`，不构建、不链 bin。

## 14. apt，且命令名和包名不同

```toml
[[apt]]
name = "docker-compose-v2"
bin = "/usr/libexec/docker/cli-plugins/docker-compose"   # dpkg 自己放文件，bin 只用来记路径/查名
description = "Docker Compose v2 plugin for the docker CLI"
```
