# ###  Config  ################################################################

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

# for gunicorn & flask & celery
export OMP_NUM_THREADS=1

# thefuck
hash thefuck &>/dev/null && eval $(thefuck --alias)

# atuin
hash atuin &>/dev/null && eval "$(atuin init zsh)"

# vfox
hash vfox &>/dev/null && eval "$(vfox activate zsh)"

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

# cargo
[[ -e "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# zoxide
hash zoxide &>/dev/null && eval "$(zoxide init zsh --cmd j)"

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

# Load Angular CLI autocompletion.
source <(ng completion script)

# ###  Token  #################################################################

export ipinfo="c577b3ef143bc3"
export codeium="eyJhbGciOiJSUzI1NiIsImtpZCI6IjY5NjI5NzU5NmJiNWQ4N2NjOTc2Y2E2YmY0Mzc3NGE3YWE5OTMxMjkiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoia2FpZ2Ugd3UiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUNnOG9jSWlpOUpjQXZGekYwRHVESXZBUVF0cXc1LWJQbzdNRkRURWtGb0k2dkphMWlvPXM5Ni1jIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2V4YTItZmIxNzAiLCJhdWQiOiJleGEyLWZiMTcwIiwiYXV0aF90aW1lIjoxNzA3MDk5Mjk2LCJ1c2VyX2lkIjoibWNIN2lBdHlzeGVIbDR5RXBvajIxQnpoSXdWMiIsInN1YiI6Im1jSDdpQXR5c3hlSGw0eUVwb2oyMUJ6aEl3VjIiLCJpYXQiOjE3MDcwOTk5ODYsImV4cCI6MTcwNzEwMzU4NiwiZW1haWwiOiJ3dWthaWdlZUBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwNjI0MzM4NjEzNDI1ODg2OTIyMiJdLCJlbWFpbCI6WyJ3dWthaWdlZUBnbWFpbC5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJnb29nbGUuY29tIn19.KaYvblUqLJ0H_rV_mFQPZ3hdHqnWf5SQbjjJEmDHNUp8EwvRZRLCqUZcc48xdpMppADinv-FdkckcuXGLHB1O7NnCZNrQnZq0Q6H8S2saSidpo80HBnN66Ua_zVZSJdEEdPqRRJ_VPlRjVEi7_j6ZWv1MinnEMFepifEhFdPFKA72Nud2awAxnkvY42LYSrtD-zp_o1a-0lOqTZ6viuzTCpVya3UkEMPCqIStoEcJf5W_dUtPEe7dHnlf2BwuliFf_MCTiemDrVEJmSo2H1sydancIytkNzP70zi0pvlM3YF46F4eUHlyGaqRq4MaK457q5DON0o6X0nRQ3nPj3YcQ"
export xfltd="https://4e27671ecbe40902.cdn.jiashule.com/api/v1/client/subscribe?token=e3b4087faa1bc13b7963f74af7d14cd1"

