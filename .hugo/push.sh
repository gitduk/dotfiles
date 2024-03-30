#!/usr/bin/env zsh

cd $HOME/.hugo && hugo
cd public/
git add .
git commit -m "`date`"
git push
