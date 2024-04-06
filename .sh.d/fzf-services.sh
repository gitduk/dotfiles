#!/usr/bin/env zsh

selected_service=$({
  systemctl --user list-units --no-pager --type=service --no-legend --all
  systemctl --system list-units --no-pager --type=service --no-legend --all
} | while read -r raw
do
  if [[ "$raw" = ●* ]]; then
    stat="✘"
    read _ name load active run comment <<<  "$(echo "$raw" | awk '{print $1, $2, $3, $4, $5}')"
  else
    stat="✔"
    read name load active run comment <<<  "$(echo "$raw" | awk '{print $1, $2, $3, $4, $5}')"
  fi
  [[ ${#name} -gt 30 ]] && name="${name:0:28}.."
  printf "%s %-30s %-10s %-10s %-10s %s\n" $stat $name $load $active $run $comment
done | fzf --exact --preview 'systemctl status $(cut -d " " -f2 <<< "{}") 2>/dev/null || systemctl --user status $(cut -d " " -f2 <<< "{}")')

