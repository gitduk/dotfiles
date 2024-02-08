#!/usr/bin/env zsh

# cat ~/.todo.txt | jq -Rcs --unbuffered '
#   split("\n") |
#   map(select(length > 0)) |
#   map(split(": "))
#   | map({(.[0] | gsub(" "; "")): .[1]})
#   | add'

[[ -e ~/.todo.txt ]] || touch ~/.todo.txt

COUNT=$(cat ~/.todo.txt | sed '/^$/d' | wc -l)
TODOS=$(cat ~/.todo.txt | head -c -1 - | sed -z 's/\n/\\n/g')

printf '{"text": "%s", "tooltip": "%s"}\n' "$COUNT" "$TODOS"
