#################
### Lazy Load ###
#################
# Lazy-loaded tools (install on first use via command_not_found_handler)
typeset -gA LAZY_REPO LAZY_ICE LAZY_DESC LAZY_EVAL LAZY_BPICK

command_not_found_handler() {
  local repo="${LAZY_REPO[$1]}"
  if [[ -n "$repo" ]]; then
    local desc="${LAZY_DESC[$1]}"
    local installer
    case "$repo" in
      curl:*)  installer="curl"  ;;
      bun:*)   installer="bun"   ;;
      cargo:*) installer="cargo" ;;
      apt:*)   installer="apt"   ;;
      deb:*)   installer="deb"   ;;
      *)       installer="zinit" ;;
    esac
    [[ -n "$desc" ]] && echo "[$installer] Installing $1: $desc" >&2

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
    elif [[ "$repo" == deb:* ]]; then
      local gh_repo="${repo#deb:}"
      local bpick="${LAZY_BPICK[$1]}"
      local tmpdir
      tmpdir="$(mktemp -d)"
      local -a dl_args=(--repo "$gh_repo" --dir "$tmpdir")
      [[ -n "$bpick" ]] && dl_args+=(--pattern "$bpick")
      gh release download "${dl_args[@]}"
      sudo dpkg -i "$tmpdir"/*.deb
      rm -rf "$tmpdir"
      rehash
    else
      local id="${repo##*/}"
      local -a ices=("${(Q@)${(z)LAZY_ICE[$1]}}")
      (( ${ices[(I)as*]} )) || ices+=(as"program")
      (( ${ices[(I)from*]} )) || ices+=(from"gh-r")
      (( ${ices[(I)atpull*]} )) || ices+=(atpull"%atclone")
      zinit ice lucid id-as"$id" "${ices[@]}"
      zinit light "$repo"
      local eval_cmd="${LAZY_EVAL[$1]}"
      [[ -n "$eval_cmd" ]] && eval "$(eval "$eval_cmd")"
    fi
    if (( $+commands[$1] )); then
      unset "LAZY_REPO[$1]" "LAZY_ICE[$1]" "LAZY_DESC[$1]" "LAZY_EVAL[$1]" "LAZY_BPICK[$1]"
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

# Parse sbin value into command names; results returned in _lazy_cmds
_parse_lazy_cmds() {
  _lazy_cmds=()
  local entry
  for entry in ${(s:;:)1}; do
    entry="${entry#"${entry%%[![:space:]]*}"}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    if [[ "$entry" == *" -> "* ]]; then
      _lazy_cmds+=("${entry##* -> }")
    else
      _lazy_cmds+=("${entry##*/}")
    fi
  done
}

_load_lazy_tools() {
  setopt local_options extendedglob
  local toml_file="${_LAZY_DIR:-${${(%):-%x}:h}}/lazy.toml"
  [[ ! -f "$toml_file" ]] && return

  local repo="" line key value
  local -A tool_fields

  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# || -z "$line" ]] && continue

    if [[ "$line" == "[[lazy]]" ]]; then
      [[ -n "$repo" ]] && _process_tool "$repo" tool_fields
      repo=""
      tool_fields=()
      continue
    fi

    if [[ "$line" =~ ^([a-z_-]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      key="${match[1]}"
      value="${match[2]}"

      if [[ "${value[1,3]}" == "'''" && "${value[-3,-1]}" == "'''" ]]; then
        value="${value[4,-4]}"
      elif [[ "${value[1]}" == "'" && "${value[-1]}" == "'" ]]; then
        value="${value[2,-2]}"
      elif [[ "${value[1]}" == '"' && "${value[-1]}" == '"' ]]; then
        value="${value[2,-2]}"
      fi
      value="${value%%[[:space:]]#}"

      if [[ "$value" == \[*\] ]]; then
        local raw="${value[2,-2]}"
        local -a _arr_items=("${(s:,:)raw}")
        local _arr_item _arr_cleaned=()
        for _arr_item in "${_arr_items[@]}"; do
          _arr_item="${_arr_item##[[:space:]]#}"
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

  [[ -n "$repo" ]] && _process_tool "$repo" tool_fields
}

_process_tool() {
  local repo="$1"
  shift
  local -A fields=("${(@kvP)1}")

  local ice=""
  [[ -n "${fields[bpick]}" ]] && ice+=" bpick\"${fields[bpick]}\""
  [[ -n "${fields[sbin]}" ]] && ice+=" sbin\"${fields[sbin]}\""
  [[ "${fields[completions]}" == "true" ]] && ice+=" completions"
  [[ -n "${fields[atclone]}" ]] && ice+=" atclone'${fields[atclone]}'"
  [[ -n "${fields[atpull]}" ]] && ice+=" atpull'${fields[atpull]}'"
  [[ -n "${fields[extract]}" ]] && ice+=" extract\"${fields[extract]}\""
  [[ -n "${fields[as]}" ]] && ice+=" as\"${fields[as]}\""
  [[ -n "${fields[from]}" ]] && ice+=" from\"${fields[from]}\""
  ice="${ice# }"

  if [[ -n "${fields[env]}" ]]; then
    local _v="${fields[env]}"
    export "${_v%%=*}=${${_v#*=}/#\~/$HOME}"
  fi

  local -a cmds=()
  [[ -n "${fields[cmd]}" ]] && cmds+=("${fields[cmd]}")
  if [[ -n "${fields[sbin]}" ]]; then
    _parse_lazy_cmds "${fields[sbin]}"
    cmds+=("${_lazy_cmds[@]}")
  fi
  if (( ${#cmds} == 0 )); then
    local name="${repo#*:}"
    name="${name##*/}"
    cmds=("$name")
  fi

  local cmd
  if [[ -n "${fields[eval]}" ]]; then
    for cmd in "${cmds[@]}"; do
      if (( $+commands[$cmd] )); then
        eval "$(eval "${fields[eval]}")"
        break
      fi
    done
  fi

  for cmd in "${cmds[@]}"; do
    (( $+commands[$cmd] )) && continue
    LAZY_REPO[$cmd]="$repo"
    LAZY_ICE[$cmd]="$ice"
    LAZY_DESC[$cmd]="${fields[description]}"
    LAZY_EVAL[$cmd]="${fields[eval]}"
    LAZY_BPICK[$cmd]="${fields[bpick]}"
  done
}

_LAZY_DIR="${${(%):-%x}:h}"
_load_lazy_tools
