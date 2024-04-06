# 默认配置
: ${DOTENV_FILE:=".env"}
: ${DOTENV_CLEAR_FILE:=".clear"}
: ${DOTENV_TAGS:="venv .git .idea .env .vscode"}
: ${DOTENV_DEBUG:=1}

# 调试信息打印
function dotenv_debug {
  [[ "$DOTENV_DEBUG" -eq 1 ]] && echo "$*"
}

# 加载文件
function zsh_source {
  dotenv_debug "dotenv: load $1"
  zsh -fn "$1" || {
    echo "dotenv: error when load \`$1\`" >&2
    return 1
  }
  source "$1" 2>/dev/null
}

# 递归查找项目根目录
function get_project_root {
  local dir=$1
  local tags=(${(z)DOTENV_TAGS})

  for tag in ${tags}; do
    if [ -f "$dir/$tag" ]; then
      echo $dir
      return
    fi
  done

  local parent=$(dirname $dir)
  if [ "$parent" == "/" ]; then
    return
  fi

  get_project_root $parent
}


function chpwd_hook {
  root="`get_project_root "$PWD"`"
  if [[ "$PWD" = $OLDPWD/* && "$root" && "$PWD" = "$root" ]]; then
    [[ -f "$root/$DOTENV_FILE" ]] && zsh_source "$root/$DOTENV_FILE"
  fi

  oldroot="`get_project_root "$OLDPWD"`"
  [[ "$oldroot" = "$root" ]] && return 0

  if [[ "$root" && "$oldroot" ]]; then
    [[ -f "$oldroot/$DOTENV_CLEAR_FILE" ]] && zsh_source "$oldroot/$DOTENV_CLEAR_FILE"
    [[ -f "$root/$DOTENV_FILE" ]] && zsh_source "$root/$DOTENV_FILE"
  fi

  if [[ "$OLDPWD" = $PWD/* && ! "$root" && "$oldroot" ]]; then
    [[ -f "$oldroot/$DOTENV_CLEAR_FILE" ]] && zsh_source "$oldroot/$DOTENV_CLEAR_FILE"
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd chpwd_hook

