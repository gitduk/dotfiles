-- Keybindings
-- Key name reference: xkbcommon-keysyms.h (segment after XKB_KEY_)
-- Use `wev` to identify key names / keycodes.

local Mod = "ALT"
local Mod_C = "ALT + CTRL"
local Mod_S = "ALT + SHIFT"
local Mod_CS = "ALT + CTRL + SHIFT"

local TERM = "alacritty"

-- inline rules
local popup = "[float; center; size 1000 600]"

-- Window management
hl.bind(Mod .. " + q", hl.dsp.window.close())
hl.bind(Mod_S .. " + q", hl.dsp.window.kill())
hl.bind(Mod .. " + f", hl.dsp.window.fullscreen())
hl.bind(Mod_S .. " + f", hl.dsp.window.float({ action = "toggle" }))

-- Group management
hl.bind(Mod .. " + g", hl.dsp.group.toggle())

-- Terminal
hl.bind(
	Mod .. " + c",
	hl.dsp.exec_cmd(TERM .. " --title terminal -e zellij --layout default attach --create " .. os.getenv("USER"))
)
hl.bind(Mod .. " + minus", hl.dsp.exec_cmd(TERM))
hl.bind(Mod .. " + backslash", hl.dsp.exec_cmd(TERM))

-- Power / session
hl.bind(Mod .. " + BackSpace", hl.dsp.exec_cmd("hyprlock -q"))
hl.bind(Mod_S .. " + BackSpace", hl.dsp.exec_cmd("systemctl suspend"))
hl.bind(Mod_C .. " + BackSpace", hl.dsp.exit())
hl.bind(Mod_CS .. " + BackSpace", hl.dsp.exec_cmd("shutdown now"))

-- Launcher / clipboard / notebook / password
hl.bind(Mod .. " + a", hl.dsp.exec_cmd("tofi-drun --drun-launch=true"))
hl.bind(Mod .. " + semicolon", hl.dsp.exec_cmd(popup .. "foot sh -c '" .. scripts .. "/clipboard.sh'"))
hl.bind(Mod_S .. " + semicolon", hl.dsp.exec_cmd(popup .. "foot bash " .. zdirs .. "/functions/pw -f"))
hl.bind(Mod .. " + n", hl.dsp.exec_cmd(popup .. "foot sh -c 'nvim ~/.nb.md'"))

-- Waybar / mako
hl.bind(Mod .. " + b", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))
hl.bind(Mod_S .. " + r", function()
	hl.dispatch(hl.dsp.exec_cmd("killall -SIGUSR2 waybar"))
	hl.dispatch(hl.dsp.exec_cmd("hyprctl reload"))
end)
hl.bind("CTRL + SHIFT + grave", hl.dsp.exec_cmd("makoctl restore"))
hl.bind("CTRL + grave", hl.dsp.exec_cmd("makoctl dismiss --all"))

-- Media / special keys
hl.bind("xf86AudioMicMute", hl.dsp.exec_cmd(waybar .. "/scripts/volume.sh --toggle-mic"), { locked = true })
hl.bind(
	"xf86AudioRaiseVolume",
	hl.dsp.exec_cmd(waybar .. "/scripts/volume.sh --inc"),
	{ locked = true, repeating = true }
)
hl.bind(
	"xf86AudioLowerVolume",
	hl.dsp.exec_cmd(waybar .. "/scripts/volume.sh --dec"),
	{ locked = true, repeating = true }
)
hl.bind("xf86AudioMute", hl.dsp.exec_cmd(waybar .. "/scripts/volume.sh --toggle"), { locked = true })
hl.bind("xf86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })
hl.bind("xf86Rfkill", hl.dsp.exec_cmd("rfkill toggle wifi"), { locked = true })

-- Focus (H/L also toggle group)
hl.bind(Mod .. " + j", hl.dsp.focus({ direction = "d" }))
hl.bind(Mod .. " + k", hl.dsp.focus({ direction = "u" }))
hl.bind(Mod .. " + h", hl.dsp.focus({ direction = "l" }))
hl.bind(Mod .. " + l", hl.dsp.focus({ direction = "r" }))

-- Move windows (J/K also manage group membership)
hl.bind(Mod_S .. " + j", function()
	hl.dispatch(hl.dsp.window.move({ direction = "d" }))
	hl.dispatch(hl.dsp.group.lock_active({ action = "toggle" }))
end)
hl.bind(Mod_S .. " + k", function()
	hl.dispatch(hl.dsp.window.move({ direction = "u" }))
	hl.dispatch(hl.dsp.window.move({ out_of_group = true }))
end)
hl.bind(Mod_S .. " + h", function()
	hl.dispatch(hl.dsp.window.move({ direction = "l" }))
	hl.dispatch(hl.dsp.window.move({ into_group = "r" }))
	hl.dispatch(hl.dsp.group.prev()) -- changegroupactive backward
end)
hl.bind(Mod_S .. " + l", function()
	hl.dispatch(hl.dsp.window.move({ direction = "r" }))
	hl.dispatch(hl.dsp.window.move({ into_group = "l" }))
	hl.dispatch(hl.dsp.group.next()) -- changegroupactive forward
end)

-- Switch workspaces (code:10 = 1, code:11 = 2, …)
for i = 1, 10 do
	local code = "code:" .. (9 + i)
	hl.bind(Mod .. " + " .. code, hl.dsp.focus({ workspace = tostring(i) }))
	hl.bind(Mod_S .. " + " .. code, hl.dsp.window.move({ workspace = tostring(i) }))
	hl.bind(Mod_C .. " + " .. code, hl.dsp.window.move({ workspace = tostring(i), follow = false }))
end

-- Relative workspace navigation
hl.bind(Mod_S .. " + bracketleft", hl.dsp.window.move({ workspace = "-1" }))
hl.bind(Mod_S .. " + bracketright", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(Mod_C .. " + bracketleft", hl.dsp.window.move({ workspace = "-1", follow = false }))
hl.bind(Mod_C .. " + bracketright", hl.dsp.window.move({ workspace = "+1", follow = false }))

-- Workspace cycling
hl.bind(Mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(Mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(Mod .. " + period", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(Mod .. " + comma", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(Mod .. " + p", hl.dsp.focus({ workspace = "previous" }))
hl.bind(Mod_C .. " + l", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(Mod_C .. " + h", hl.dsp.focus({ workspace = "m-1" }))

-- Mouse move / resize
hl.bind(Mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(Mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Special workspace (scratchpad)
hl.bind(Mod .. " + Tab", hl.dsp.workspace.toggle_special("special"))
hl.bind(Mod_S .. " + Tab", hl.dsp.window.move({ workspace = "special" }))

-- Master layout helpers
hl.bind(Mod .. " + i", function()
	hl.dispatch(hl.dsp.layout("rollnext"))
	hl.dispatch(hl.dsp.layout("focusmaster master"))
end)
hl.bind(Mod .. " + o", function()
	hl.dispatch(hl.dsp.layout("rollprev"))
	hl.dispatch(hl.dsp.layout("focusmaster master"))
end)

-- Submaps ----------------------------------------------------------------

-- Dispatch any action then exit the current submap
local function with_reset(action)
	return function()
		hl.dispatch(action)
		hl.dispatch(hl.dsp.submap("reset"))
	end
end

-- Settings submap
hl.bind(Mod_S .. " + s", hl.dsp.submap("settings"))
hl.define_submap("settings", function()
	hl.bind(
		"m",
		hl.dsp.exec_cmd(
			"hyprctl keyword general:layout $(printf 'master\\ndwindle' | grep -v \"$(hyprctl -j getoption general:layout | jq -r .str)\")"
		)
	)
	hl.bind(
		"m",
		hl.dsp.exec_cmd('sleep 0.1 && notify-send "Layout: $(hyprctl -j getoption general:layout | jq -r .str)"')
	)
	hl.bind("s", hl.dsp.submap("reset"))
	hl.bind("b", hl.dsp.submap("reset"))
	hl.bind("q", hl.dsp.submap("reset"))
end)

-- Master orientation submap
hl.bind(Mod .. " + m", hl.dsp.submap("master"))
hl.define_submap("master", function()
	hl.bind("h", hl.dsp.layout("orientationleft"))
	hl.bind("l", hl.dsp.layout("orientationright"))
	hl.bind("k", hl.dsp.layout("orientationtop"))
	hl.bind("j", hl.dsp.layout("orientationbottom"))
	hl.bind("s", hl.dsp.layout("orientationcenter"))
	hl.bind("q", hl.dsp.submap("reset"))
	hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- Resize submap
hl.bind(Mod .. " + r", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
	hl.bind("l", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
	hl.bind("h", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
	hl.bind("k", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
	hl.bind("j", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })
	hl.bind("m", hl.dsp.exec_cmd("hyprctl dispatch splitratio 0.4"))
	hl.bind("q", hl.dsp.submap("reset"))
	hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- Music submap
hl.bind(Mod .. " + u", hl.dsp.submap("music"))
hl.define_submap("music", function()
	hl.bind("a", hl.dsp.exec_cmd(popup .. "foot sh -c '" .. waybar .. "/scripts/mpd.sh -s'"))
	hl.bind("u", hl.dsp.exec_cmd(popup .. "foot sh -c '" .. waybar .. "/scripts/mpd.sh -u'"))
	hl.bind("s", hl.dsp.exec_cmd("mpc single"))
	hl.bind("r", hl.dsp.exec_cmd("mpc random"))
	hl.bind("c", hl.dsp.exec_cmd("mpc consume"))
	hl.bind("p", hl.dsp.exec_cmd("mpc repeat"))
	hl.bind("j", hl.dsp.exec_cmd(scripts .. "/volume.sh --dec"))
	hl.bind("k", hl.dsp.exec_cmd(scripts .. "/volume.sh --inc"))
	hl.bind("space", hl.dsp.exec_cmd("mpc toggle"))
	hl.bind("l", hl.dsp.exec_cmd("mpc next"))
	hl.bind("h", hl.dsp.exec_cmd("mpc prev"))
	hl.bind("a", hl.dsp.submap("reset"))
	hl.bind("q", hl.dsp.submap("reset"))
	hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- Screenshot submap
hl.bind(Mod .. " + s", hl.dsp.submap("screenshot"))
hl.define_submap("screenshot", function()
	hl.bind("a", hl.dsp.exec_cmd(scripts .. "/screenshot.sh --area"))
	hl.bind("n", hl.dsp.exec_cmd(scripts .. "/screenshot.sh --now"))
	hl.bind("s", hl.dsp.exec_cmd(scripts .. "/screenshot.sh --swappy"))
	hl.bind("w", hl.dsp.exec_cmd(scripts .. "/screenshot.sh --active"))
	hl.bind("q", hl.dsp.submap("reset"))
	hl.bind("Escape", hl.dsp.submap("reset"))
	hl.bind("catchall", hl.dsp.submap("reset"))
end)

-- Wallpaper submap
hl.bind(Mod .. " + w", hl.dsp.submap("wallpaper"))
hl.define_submap("wallpaper", function()
	hl.bind(
		"a",
		with_reset(
			hl.dsp.exec_cmd(
				"kitty --title img sh -c '" .. waybar .. "/scripts/wallpaper.sh select " .. wallpapers .. "'"
			)
		)
	)
	hl.bind("d", with_reset(hl.dsp.exec_cmd("pkill hyprpaper")))
	hl.bind("r", hl.dsp.exec_cmd(waybar .. "/scripts/wallpaper.sh random " .. wallpapers))
	hl.bind("q", hl.dsp.submap("reset"))
	hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- Input submap
hl.bind(Mod_S .. " + i", hl.dsp.submap("input"))
hl.define_submap("input", function()
	hl.bind("d", with_reset(hl.dsp.exec_cmd("date '+%F %T' | tr -d '\\n' | wl-copy")))
	hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- Nokey submap (captures all input)
hl.bind(Mod_S .. " + n", hl.dsp.submap("nokey"))
hl.define_submap("nokey", function()
	hl.bind("Escape", hl.dsp.submap("reset"))
end)
