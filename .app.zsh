# Xresources
[[ -f "$HOME/.Xresources" ]] && xrdb -merge "$HOME/.Xresources" 2>/dev/null

# rofi
export ROFITHEMES=$HOME/.config/rofi/themes

# navi
export NAVI_PATH=$HOME/.cheats
export NAVI_CONFIG=$HOME/.config/navi/config.yaml

# tmuxp
export TMUXP_CONFIGDIR=$HOME/.tmuxp
export DISABLE_AUTO_TITLE='true'

# mpd
export MPDCONF=$HOME/.mpdconf

# execjs
export EXECJS_RUNTIME=$HOME/.local/nodejs/bin/node
export NODE_PATH=$HOME/.local

# dotnet
export DOTNET_ROOT=$HOME/.dotnet

# cuda path
export CUDA_HOME="/usr/local/cuda"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}/usr/local/cuda/lib64"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}/usr/local/cuda/targets/x86_64-linux/lib"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}/usr/local/cuda/targets/x86_64-linux/lib/stubs"

# for gunicorn & flask & celery
export OMP_NUM_THREADS=1

# thefuck
hash thefuck &> /dev/null && eval $(thefuck --alias)

# atuin
hash atuin &> /dev/null && eval "$(atuin init zsh)"

# nvm
export NVM_DIR="$HOME/.nvm"
if [[ -e "$NVM_DIR" ]]; then
  [[ -e "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"  # This loads nvm
  [[ -e "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# Gitlab
export GITLAB_HOME="$HOME/.docker/gitlab"

# Rye
[[ -f "$HOME/.rye/env" ]] && source "$HOME/.rye/env"

# resend
export RESEND_API_KEY="re_9VuhDaWV_Hf3oZ8xGrx5aVeUHV1XXvFeC"
export POP_FROM="mail@wukaige.com"

# conda
# CONDA_HOME="/home/Public/anaconda3"
# __conda_setup="$($CONDA_HOME'/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#     eval "$__conda_setup"
# else
#     if [ -f "$CONDA_HOME/etc/profile.d/conda.sh" ]; then
#       . "$CONDA_HOME/etc/profile.d/conda.sh"  # commented out by conda initialize
#     else
#       export PATH="$CONDA_HOME/bin:$PATH"  # commented out by conda initialize
#     fi
# fi
# unset __conda_setup

