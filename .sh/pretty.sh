#!/usr/bin/env zsh

declare -A colors=(
  [black]="30m"
  [red]="31m"
  [green]="32m"
  [yellow]="33m"
  [blue]="34m"
  [purple]="35m"
  [cyan]="36m"
  [white]="37m"
  [bblack]="40m"
  [bred]="41m"
  [bgreen]="42m"
  [byellow]="43m"
  [bblue]="44m"
  [bpurple]="45m"
  [bcyan]="46m"
  [bwhite]="47m"
  [iblack]="90m"
  [ired]="91m"
  [igreen]="92m"
  [iyellow]="93m"
  [iblue]="94m"
  [ipurple]="95m"
  [icyan]="96m"
  [iwhite]="97m"
  [hblack]="100m"
  [hred]="101m"
  [hgreen]="102m"
  [hyellow]="103m"
  [hblue]="104m"
  [hpurple]="105m"
  [hcyan]="106m"
  [hwhite]="107m"
)

declare -A styles=(
  [n]="0"
  [b]="1"
  [u]="4"
)

reset="\033[0m"

if [[ -t 1 ]]; then
  fmt() { printf "\033[${styles[$1]};${colors[$2]}" }
else
  fmt() { :; }
fi

function picker {
  printf "%s" "$1"
  shift
  for arg in "$@"
  do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

red() { printf "$(fmt n red)%s${reset}" "$(picker "$@")" }
green() { printf "$(fmt n green)%s${reset}" "$(picker "$@")" }
yellow() { printf "$(fmt n yellow)%s${reset}" "$(picker "$@")" }
blue() { printf "$(fmt n blue)%s${reset}" "$(picker "$@")" }
underline() { printf "$(fmt u white)%s${reset}" "$(picker "$@")" }

ok() { printf "$(fmt n green)%s${reset} %s\n" "✔" "$(picker "$@")" }
info() { printf "$(fmt n blue)%s${reset} %s\n" "➭" "$(picker "$@")" }
warn() { printf "$(fmt n yellow)%s${reset} %s\n" "⚠" "$(picker "$@")" }
error() { printf "$(fmt n red)%s${reset} %s\n" "✘" "$(picker "$@")" }

function cmdi {
  command_string="$(picker "$@")"
  printf "$(fmt n yellow)%s${reset} %s\n" "♯" "$command_string"
  sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" <<< "$command_string" | bash
}

function bar {
  string="$(picker "${@}")"
  [[ "$1" == "-" ]] && char="$2" && string="$(picker "${@:3}")"
  line_size=$(( $(tput cols) / 2 - ${#string} ))
  half_line="$(printf -- "${char:-#}%.0s" {1..$line_size})"
  echo -n "$(fmt n blue)# ### $string $half_line${reset}\n"
}

