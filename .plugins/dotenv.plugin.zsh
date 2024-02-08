## Settings

# Filename of the dotenv file to look for
: ${ZSH_DOTENV_FILE:=.env}
: ${ZSH_CLEAR_FILE:=.clear}

: ${PROJECT_TAG:=("venv" ".git" ".idea" ".env" ".vscode")}

function in_project {
  local DIRS=(${(s:/:)1})
  local index=-1
  while [[ $index -gt -${#DIRS} ]]; do
    PROJECT=${(j:/:)DIRS[1,$index]}
    for tag in $PROJECT_TAG; do
      if [[ -e "/$PROJECT/$tag" ]]; then
        echo "/$PROJECT"
        return 0
      fi
    done
    ((index--))
  done
  return 1
}

function source_file {
  zsh -fn "$1" || {
    echo "dotenv: error when sourcing '$1' file" >&2
    return 1
  }
  source "$1" 2>/dev/null
}

function source_env {
  PROJECT="`in_project "$PWD"`"
  if [[ "$PWD" = $OLDPWD/* && "$PROJECT" && "$PWD" = "$PROJECT" ]]; then
    [[ -f "$PROJECT/$ZSH_DOTENV_FILE" ]] && source_file "$PROJECT/$ZSH_DOTENV_FILE"
  fi

  OLDPROJECT="`in_project "$OLDPWD"`"
  [[ "$OLDPROJECT" = "$PROJECT" ]] && return 0

  if [[ "$PROJECT" && "$OLDPROJECT" ]]; then
    [[ -f "$OLDPROJECT/$ZSH_CLEAR_FILE" ]] && source_file "$OLDPROJECT/$ZSH_CLEAR_FILE"
    [[ -f "$PROJECT/$ZSH_DOTENV_FILE" ]] && source_file "$PROJECT/$ZSH_DOTENV_FILE"
  fi

  if [[ "$OLDPWD" = $PWD/* && ! "$PROJECT" && "$OLDPROJECT" ]]; then
    [[ -f "$OLDPROJECT/$ZSH_CLEAR_FILE" ]] && source_file "$OLDPROJECT/$ZSH_CLEAR_FILE"
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd source_env

