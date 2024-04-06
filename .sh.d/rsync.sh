#!/usr/bin/env zsh

source $HOME/.pretty.zsh

source_dir="$HOME/.etc"
target_dir="/etc"

if [[ -e "$source_dir" ]]; then
  inotifywait -mrq --format '%Xe %w%f' -e modify,create "$source_dir" | while read file; do
    file_path="${file/MODIFY /}"
    file_name="${file_path##*/}"

    sudo rsync -aq "$file_path" "$target_dir/$file_name"
    [[ $? = 0 ]] && info "Sync $file_path" || warn "Sync faild $file_path"
  done
fi

