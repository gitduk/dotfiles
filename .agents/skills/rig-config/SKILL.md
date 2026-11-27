---
name: rig-config
description: Add, change or repair a tool entry in `~/.rig.toml` — rig, the release installer and zsh loader. Use when the user hands over a repo, release or package and says to write it into rig config ("把这个写进 rig 配置", "加到 rig", "rig 里装个 X"), or when an existing rig entry fails to install or its binary, completions or aliases do not appear. Not for installing something with cargo/npm/apt directly when rig was not mentioned.
paths:
  - ".rig.toml"
  - "**/rig.toml"
---

# rig 配置

一条 entry 描述四件事：版本从哪来、怎么装、装完哪个文件接成命令、怎么接进 zsh。配置是 `~/.rig.toml`，状态在 `~/.local/share/rig/`（`rig.lock`、`init.zsh`、`pkg/<tool>/<version>/`、`completions/`、`plugins/`）。`rig sync` 由配置生成 `init.zsh`，每个新 shell 自动跑一次，所以改完配置新开的 shell 就生效。

## 流程

1. 先拿上游资产的**真实文件名**，别凭印象写 glob：

```sh
curl -sS https://api.github.com/repos/OWNER/REPO/releases/latest \
  | python3 -c 'import json,sys;d=json.load(sys.stdin);print(d["tag_name"]);[print(a["name"]) for a in d["assets"]]'
```

Codeberg 把域名换成 `codeberg.org/api/v1/repos/...`。GitHub 未认证只给 60 次/小时；本机装了 `gh` 且登录过，rig 会自己拿 token。

2. 按「源类型决策」选 section，再定变体：架构、要不要 `-stealth` 这类功能包、要暴露几个 bin。同平台常有 `-gnu` 和 `-musl` 两份，跟同 section 已有条目对齐（本机 fd/bat/delta 走 gnu）；没有先例时选 musl，静态链接不吃宿主 glibc。

3. 写进 `~/.rig.toml` 对应 section，跟该 section 现有条目同风格：`name` 用上游 `owner/repo`，`description` 抄上游一句话。

4. `rig list | grep KEY` 确认配置能解析——TOML 形状错、key 重复、`bpick` 只有 `!` glob，都在这一步报。行首 `○` 未装、`●` 已装。

5. `rig install KEY`（想直白看每步加 `-v`），然后**真跑一次那个命令**验证，别只看 install 成功。

6. `grep -A6 'tool\.KEY' ~/.local/share/rig/rig.lock` 看 version / asset / bins 是否对，再 `rig doctor` 看有没有漂移。

## 源类型决策

从高到低取第一个成立的：预编译包优先于自己编。

全 prerelease 的仓库 `/releases/latest` 返 404，rig 会回退到 `/releases` 列表取最新非 draft，仍写 `[[repo]]`，不要为了这个改 `[[git]]` 去编。

| 上游有什么 | section |
| --- | --- |
| release 里有预编译包 | `[[repo]]` |
| 只有源码，或要自己编 | `[[git]]`（`setup` 跑构建） |
| crates.io 上有 | `[[cargo]]` |
| npm 上有 CLI 包 | `[[node]]` |
| 发行版仓库里有 | `[[apt]]` |
| 只有 install.sh | `[[curl]]` |
| zsh 插件（clone 后 source） | `[[plugin]]` |

## 最常见的两个形状

```toml
# 预编译 tar.gz，一个二进制，归档里自带 _foo 补全
[[repo]]
name = "sharkdp/fd"
bpick = "fd-v*-x86_64-unknown-linux-gnu.tar.gz"
description = "A program to find entries in your filesystem"

# 裸二进制（没有归档可解），加排除项挑掉别的平台
[[repo]]
name = "bahdotsh/feedr"
bpick = "feedr-linux-x86_64"
extract = false
bin = { "feedr*" = "feedr" }
description = "A modern terminal-based RSS/Atom feed reader"
```

其余形状（AppImage、`.deb`、嵌套路径、一个包两个二进制、生成补全、`setup` 里 `setcap`、`lazy` + `bind`、git 构建）抄 `references/recipes.md`。

## 别弄脏自己的环境

想先验证一条 entry 又想隔离，用假 `HOME`，`rig` 的配置、锁、prefix 全跟着 `$HOME` 走：

```sh
HOME=/tmp/rig-try rig install KEY -v
```

## 参考

- `references/schema.md`：每个字段的精确语义与校验规则——`bpick` 列表是「全部命中且全部不命中」的过滤器、`bin` 三种形态、`completions` 四形态、`eval` 的缓存探测、`setup` 的 `sh -ec` 与 cwd、更新判定只看字符串相等。字段该写哪种形态、或者要解释 rig 的行为时读它。
- `references/recipes.md`：真实条目按形态归类，含对应资产名与踩过的坑。写新条目找不到模板时读它。
