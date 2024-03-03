#!/usr/bin/env zsh

local repo=$1
local dir=$2

if [[ -n "$dir" ]]; then
	git clone --depth=1 "https://github.com/$repo.git" "$dir"
else
	git clone --depth=1 "https://github.com/$repo.git"
fi
