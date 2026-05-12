-- Hyprland 0.55+ Lua configuration
-- Entry point

home = os.getenv("HOME")
waybar = home .. "/.config/waybar"
scripts = home .. "/.config/hypr/scripts"
wallpapers = home .. "/Pictures/wallpapers"
zdirs = home .. "/.zsh.d"

require("configs.colors")
require("configs.settings")
require("configs.monitor")
require("configs.keybinds")
require("configs.rules")
