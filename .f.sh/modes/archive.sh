#!/usr/bin/env zsh

function extract {
  local full_path="$1"
  local target_dir="$2"
  local name=${full_path##*/}
  case "${name:l}" in
    *.tar.gz|*.tgz)
      tar zxvf "$full_path" -C "$target_dir"
      ;;
    *.gz)
      gzip -vfdk "$full_path"
      cmdi mv "${full_path:r}" "$target_dir"
      ;;
    *.zip)
      unzip -q "$full_path" -d "$target_dir"
      ;;
    *) echo "$0: '$full_path' cannot be extracted" >&2 ;;
  esac
}

url=$(echo $urls | grep -E "$pattern" | fzf -1)
info "$(blue url): $url"

file_name="${url##*/}"
dir="/tmp/${repo//\//_}"
[[ -e $dir ]] && rm -rf $dir
mkdir -p $dir

# download and extract
aria2c --all-proxy="$http_proxy" "$url" -d "/tmp" -o "$file_name" --allow-overwrite=true
extract "/tmp/$file_name" "$dir"

# process sigle dir
if [[ $(ls $dir |wc -l) -eq 1 ]];then
  file=$dir/$(ls $dir)
  if [[ -d "$file" ]]; then
    mv $file/* $dir/ && rm -rf $file
  fi
fi

# one file
if [[ $(ls $dir |wc -l) -eq 1 ]];then

  file=$dir/$(ls $dir)
  if [[ ! -x "$file" ]];then
    cmdi sudo chmod -R 755 $file
  fi

  cp -v $file $prefix/$cmd
  if [[ ! $? -eq 0 ]];then
    warn "$(yellow cannot copy $file to $prefix, please copy it manually), command:"
    echo "cp -v $file $prefix/$cmd"
  fi

else

  # multiple files
  count=0
  local filename=""
  find "$dir" -type f -executable | while read -r file; do
    cp -v $file $prefix/
    if [[ ! $? -eq 0 ]];then
      warn "$(yellow cannot copy $file to $prefix, please copy it manually), command:"
      echo "cp -v $file $prefix/$cmd"
    fi
    filename=$(basename $file)
    count=$((count+1))
  done

  # rename executable file
  if [[ $count -eq 1 && ! "$filename" == "$cmd" ]]; then
    cmdi mv $prefix/$filename $prefix/$cmd
  fi

  # can not found any executable file
  if [[ $count -eq 0 ]]; then
    warn "$(yellow cannot find any executable file in $dir)"
    exit 1
  fi

fi

