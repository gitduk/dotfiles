---
description: 把 `$HOME` 里的配置（`.pi/`、`.zsh.d/`、`.tmux.conf` 等）同步进裸仓库 `~/.dotfiles.git`：精确 stage、文件名 + 内容两道密钥闸、拟提交信息、确认、提交并推送。用户说「同步 dotfiles」「提交配置」「dotfiles push」时加载。
---

# dotfiles 仓库

裸仓库 `~/.dotfiles.git`，worktree 是 `$HOME`，origin 为 `https://github.com/gitduk/dotfiles.git`，默认分支 `master`。所有 git 操作走 `c`（`~/.local/bin/c`，bash 脚本，行为拿不准就直接读它）：

- `c add` — 无参数时自动 stage 所有已修改的跟踪文件；带路径则是 git 透传。
- `c status` — 无参数时等同 `git status`。
- `c commit`、`c push`、`c diff` — 原样透传给 git。
- `c restore` — 有未暂存改动时按工作区恢复（**丢弃这些改动**），全部已暂存时只取消暂存。

`c` 内部钉的是 `--work-tree=$HOME --git-dir=$HOME/.dotfiles.git`，但 pathspec 仍按 cwd 解析：所有命令在 `$HOME` 下跑（bash 传 `cwd: /home/user`），不要靠 `cd`。仓库 config 里 `status.showUntrackedFiles = no`，所以不带 `-u` 的状态天然只列跟踪文件。

模式：用户消息里带 `push`（或说「直接推」）→ 跳过 Step 2 的确认；否则默认先确认。

## Step 1 — 先看，再精确 stage

不要用裸 `c add`：它会把 `$HOME` 下**所有已修改的跟踪文件**一次 stage 进来，不只是这次动过的。

```bash
c status --porcelain -uno
```

要列新增文件时必须带 pathspec 限定，否则 120 万条未跟踪条目（缓存、容器存储、项目目录）会淹掉输出：

```bash
c status --porcelain -uall -- .pi .zsh.d .tmux.conf
```

从上面的输出里挑出真正属于 dotfile 的路径，只显式 stage 这些：

```bash
c add -A -- .pi/AGENTS.md .zsh.d/alias.zsh
```

然后跑密钥闸，**命中任一条就停下报告，不提交**。

文件名扫（凭据形状的路径）：

```bash
c diff --cached --name-only | grep -iE 'token|secret|password|credential|\.env|\.pem|\.key|\.p12|\.p8'
```

内容扫（普通文件名里藏着的真密钥）：

```bash
c diff --cached | grep -aiE 'BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[0-9A-Za-z-]{10,}'
```

两条都是 `grep` 的 `rc=1` 才算通过（无命中）。

新增的 extension / prompt 要在报告里点名，让用户知道它进了这次提交：

```bash
c status --porcelain -uall -- .pi | grep -E '^\?\? .pi/(agent/)?(extensions|prompts)/'
```

`c add` 之后若上面仍列着 `??` 条目（`c add` 只提示不 stage 未跟踪文件），用 git 直接补：

```bash
git --git-dir="$HOME/.dotfiles.git" --work-tree="$HOME" add <missed-path>
```

## Step 2 — 拟提交信息

格式 `<type>[scope]: <imperative summary>`，≤72 字符。

- 默认模式：给出已 stage 清单 + 拟定的信息，等用户确认。
- `push` 模式：直接进 Step 3。

## Step 3 — 提交并推

```bash
c commit -m "<message>" && c push
```

只有 `c status --short` 打印不出东西才算成功；还有剩余路径就逐条列出来，不要说已完成。

## 约束

- Step 1 的密钥闸是必做项，绝不提交 token / 凭据。
- 不要用 `c restore` 清场：它会 `git restore --worktree` 丢掉未暂存改动。真要动用前先按 [R05] 看清 `c status` + `c diff` 掉了什么，需要时先 `git stash push` 或拿到用户明确同意。
- 若这次变更集里包含 `~/.pi/skills/dotfiles/SKILL.md` 本身，本次运行不作为权威，另起新会话重跑一遍。
