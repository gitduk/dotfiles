#################
### Lazy Load ###
#################
# Lazy-loaded tools (install on first use via command_not_found_handler)
typeset -gA LAZY_REPO LAZY_ICE LAZY_DESC

command_not_found_handler() {
  local repo="${LAZY_REPO[$1]}"
  if [[ -n "$repo" ]]; then
    local desc="${LAZY_DESC[$1]}"
    local _i _e
    [[ -n "$desc" ]] && echo "📦 Installing $1: $desc" >&2

    if [[ "$repo" == curl:* ]]; then
      curl -fsSL "${repo#curl:}" | bash
      rehash
    elif [[ "$repo" == bun:* ]]; then
      bun install -g "${repo#bun:}"
      rehash
    elif [[ "$repo" == cargo:* ]]; then
      cargo install "${repo#cargo:}"
      rehash
    elif [[ "$repo" == apt:* ]]; then
      sudo apt install -y "${repo#apt:}"
      rehash
    else
      local id="${repo##*/}"
      local -a ices=("${(z)LAZY_ICE[$1]}")
      local -a _evals=()
      for _i in "${ices[@]}"; do
        [[ "${(Q)_i}" == eval* ]] && _evals+=("${${(Q)_i}#eval}")
      done
      ices=(${ices:#cmd*})
      ices=(${ices:#env\"*})
      ices=(${ices:#eval\"*})
      (( ${ices[(I)as*]} )) || ices+=(as"program")
      (( ${ices[(I)from*]} )) || ices+=(from"gh-r")
      (( ${ices[(I)atpull*]} )) || ices+=(atpull"%atclone")
      zinit ice lucid id-as"$id" "${(Q@)ices}"
      zinit light "$repo"
      for _e in "${_evals[@]}"; do eval "$(eval "$_e")"; done
    fi
    if (( $+commands[$1] )); then
      unset "LAZY_REPO[$1]" "LAZY_ICE[$1]" "LAZY_DESC[$1]"
      command "$@"
      return $?
    else
      echo "lazy: ✗ installation failed for '$1' — retry by running the command again" >&2
      return 1
    fi
  fi
  echo "zsh: command not found: $1" >&2
  return 127
}

# Parse sbin/cmd ice to extract command names; results returned via reply array
_parse_lazy_cmds() {
  reply=()
  local -a args=("${(Q@)${(z)1}}")
  local arg entry
  for arg in "${args[@]}"; do
    if [[ "$arg" == cmd* ]]; then
      reply+=("${arg#cmd}")
    elif [[ "$arg" == sbin* ]]; then
      for entry in ${(s:;:)${arg#sbin}}; do
        entry="${entry#"${entry%%[![:space:]]*}"}"
        entry="${entry%"${entry##*[![:space:]]}"}"
        if [[ "$entry" == *" -> "* ]]; then
          reply+=("${entry##* -> }")
        else
          reply+=("${entry##*/}")
        fi
      done
    fi
  done
}

# Parse TOML and load tools
_load_lazy_tools() {
  local toml_file="${_LAZY_DIR:-${0:h}}/lazy.toml"
  [[ ! -f "$toml_file" ]] && return

  local in_tool=0 repo="" line
  local -A tool_fields

  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# || -z "$line" ]] && continue

    # Detect [[lazy]] section
    if [[ "$line" == "[[lazy]]" ]]; then
      # Process previous tool if exists
      if [[ -n "$repo" ]]; then
        _process_tool "$repo" tool_fields
      fi
      repo=""
      tool_fields=()
      in_tool=1
      continue
    fi

    # Parse fields
    if [[ "$line" =~ ^([a-z_]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      local key="${match[1]}"
      local value="${match[2]}"

      # Remove quotes (triple-single first to prevent partial stripping)
      if [[ "${value[1,3]}" == "'''" && "${value[-3,-1]}" == "'''" ]]; then
        value="${value[4,-4]}"
      elif [[ "${value[1]}" == "'" && "${value[-1]}" == "'" ]]; then
        value="${value[2,-2]}"
      elif [[ "${value[1]}" == '"' && "${value[-1]}" == '"' ]]; then
        value="${value[2,-2]}"
      fi
      value="${value%[[:space:]]}"
      # Handle TOML array: ["a", "b"] → (a|b) for zinit bpick glob
      if [[ "$value" == \[*\] ]]; then
        local raw="${value[2,-2]}"
        local -a _arr_items=("${(s:,:)raw}")
        local _arr_item _arr_cleaned=()
        for _arr_item in "${_arr_items[@]}"; do
          _arr_item="${_arr_item## }"
          _arr_item="${_arr_item#\"}"
          _arr_item="${_arr_item%\"}"
          _arr_cleaned+=("$_arr_item")
        done
        value="(${(j:|:)_arr_cleaned})"
      fi

      if [[ "$key" == "repo" ]]; then
        repo="$value"
      else
        tool_fields[$key]="$value"
      fi
    fi
  done < "$toml_file"

  # Process last tool
  if [[ -n "$repo" ]]; then
    _process_tool "$repo" tool_fields
  fi
}

# Process a single tool entry
_process_tool() {
  local repo="$1"
  shift
  local -A fields=("${(@kvP)1}")

  # Build ice string from fields
  local ice=""

  # Handle special fields
  [[ -n "${fields[bpick]}" ]] && ice+=" bpick\"${fields[bpick]}\""
  [[ -n "${fields[sbin]}" ]] && ice+=" sbin\"${fields[sbin]}\""
  [[ -n "${fields[cmd]}" ]] && ice+=" cmd\"${fields[cmd]}\""
  [[ "${fields[completions]}" == "true" ]] && ice+=" completions"
  [[ -n "${fields[atclone]}" ]] && ice+=" atclone'${fields[atclone]}'"
  [[ -n "${fields[atpull]}" ]] && ice+=" atpull'${fields[atpull]}'"
  [[ -n "${fields[extract]}" ]] && ice+=" extract\"${fields[extract]}\""
  [[ -n "${fields[as]}" ]] && ice+=" as\"${fields[as]}\""
  [[ -n "${fields[from]}" ]] && ice+=" from\"${fields[from]}\""
  [[ -n "${fields[eval]}" ]] && ice+=" eval\"${fields[eval]}\""
  [[ -n "${fields[env]}" ]] && ice+=" env\"${fields[env]}\""

  ice="${ice# }"  # Remove leading space

  # Process env variables
  if [[ -n "${fields[env]}" ]]; then
    local _v="${fields[env]}"
    export "${_v%%=*}=${${_v#*=}/#\~/$HOME}"
  fi

  # Process eval commands
  local -a _evals=()
  if [[ -n "${fields[eval]}" ]]; then
    _evals+=("${fields[eval]}")
  fi

  # Extract command names (via reply to avoid subshell fork)
  local -a cmds=()
  _parse_lazy_cmds "$ice"
  cmds=("${reply[@]}")
  if (( ${#cmds} == 0 )); then
    typeset name="${repo#*:}"
    name="${name##*/}"
    cmds=("$name")
  fi

  # Execute eval if command already exists
  local cmd
  if (( ${#_evals} )); then
    for cmd in "${cmds[@]}"; do
      if (( $+commands[$cmd] )); then
        for _e in "${_evals[@]}"; do eval "$(eval "$_e")"; done
        break
      fi
    done
  fi

  # Register commands
  for cmd in "${cmds[@]}"; do
    LAZY_REPO[$cmd]="$repo"
    LAZY_ICE[$cmd]="$ice"
    LAZY_DESC[$cmd]="${fields[description]}"
  done
}

_LAZY_DIR="${0:h}"
_load_lazy_tools
