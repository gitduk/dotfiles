##########################
### MesloLGM Nerd Font ###
##########################

# fc-list command is not found
hash fc-list &>/dev/null || return 1

# ensure font dir
[[ ! -e "$HOME/.local/share/fonts" ]] && mkdir -p $HOME/.local/share/fonts

# update var
updated=0

fc_list=(
  "Meslo"
  "JetBrainsMono"
)

installed="$(fc-list | awk -F': ' '{print $NF}' | cut -d ':' -f1)"

for fc in "${fc_list[@]}"; do
  if [[ -z "$(echo $installed | grep -i "$fc")" ]]; then
    curl --proxy http://127.0.0.1:7890 -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$fc.tar.xz
    mv $fc.tar.xz /tmp && tar -xvf /tmp/$fc.tar.xz -C $HOME/.local/share/fonts/ && updated=1
  fi
done

[[ $updated -eq 1 ]] && fc-cache -fv
