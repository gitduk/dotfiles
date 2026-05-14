-- Environment
hl.env("HYPRCURSOR_SIZE", "16")
hl.env("HYPRCURSOR_THEME", "Vimix")

-- Autostart
hl.on("hyprland.start", function()
	-- cursor
	hl.exec_cmd("hyprctl setcursor Vimix 16")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 16")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme Vimix")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")

	-- system env propagation (skip if using HYPRLAND_NO_SD_VARS)
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
	hl.exec_cmd(
		"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE"
	)

	-- services
	hl.exec_cmd("mako")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("waybar & hyprpaper")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("fcitx5 -d")

	-- wallpaper (slight delay so hyprpaper is ready)
	hl.exec_cmd("sleep 0.2 && " .. waybar .. "/scripts/wallpaper.sh random")
end)

-- All settings
hl.config({
	general = {
		border_size = 0,
		gaps_in = 6,
		gaps_out = 12,
		resize_on_border = false,
		allow_tearing = false,
		layout = "master",
	},

	decoration = {
		rounding = 5,
		rounding_power = 2.0,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		fullscreen_opacity = 1.0,
		dim_inactive = true,
		dim_strength = 0.1,
		dim_special = 0.3,
		dim_around = 0.4,
		blur = {
			enabled = true,
			size = 6,
			passes = 2,
			vibrancy = 0.1696,
			ignore_opacity = true,
			special = true,
		},
		shadow = { enabled = false },
		glow = { enabled = false, color = color15, color_inactive = color0, range = 15, render_power = 3 },
	},

	animations = { enabled = true },

	input = {
		kb_layout = "us",
		repeat_rate = 50,
		repeat_delay = 300,
		numlock_by_default = true,
		follow_mouse_shrink = 0,
		follow_mouse_threshold = 0.0,
		touchpad = {
			disable_while_typing = true,
			natural_scroll = true,
			clickfinger_behavior = false,
			middle_button_emulation = true,
			tap_to_click = true,
			drag_lock = false,
		},
		touchdevice = { enabled = true },
		tablet = {
			transform = 0,
			left_handed = false,
		},
	},

	gestures = {
		workspace_swipe_distance = 500,
		workspace_swipe_invert = true,
		workspace_swipe_min_speed_to_force = 30,
		workspace_swipe_cancel_ratio = 0.5,
		workspace_swipe_create_new = true,
		workspace_swipe_forever = true,
	},

	group = {
		insert_after_current = true,
		col = { border_active = color15 },
		groupbar = {
			enabled = true,
			render_titles = false,
			text_color = foreground,
			col = { active = color7, inactive = color0 },
			middle_click_close = true,
			scrolling = true,
		},
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		mouse_move_enables_dpms = true,
		enable_swallow = true,
		swallow_regex = "^(kitty|foot|Alacritty)$",
		focus_on_activate = false,
		initial_workspace_tracking = 0,
		middle_click_paste = false,
		force_default_wallpaper = -1,
		allow_session_lock_restore = true,
		key_press_enables_dpms = true,
	},

	binds = {
		workspace_back_and_forth = false,
		allow_workspace_cycles = true,
		pass_mouse_when_bound = false,
	},

	xwayland = {
		enabled = true,
		force_zero_scaling = true,
	},

	cursor = {
		no_hardware_cursors = 1,
		enable_hyprcursor = true,
		warp_on_change_workspace = true,
		hide_on_key_press = true,
		inactive_timeout = 3,
		zoom_factor = 1.0, -- live pinch-to-zoom via touchpad (0.55+ gesture)
		zoom_rigid = false, -- false = zoom follows cursor position
	},

	master = {
		new_status = "slave",
		new_on_top = false,
		mfact = 0.65,
		special_scale_factor = 1.0,
	},

	dwindle = {
		preserve_split = true,
		special_scale_factor = 1.0,
	},

	render = {
		cm_auto_hdr = 0,
	},

	debug = {
		overlay = false,
		disable_logs = false,
		vfr = true, -- variable framerate: throttles render when idle, saves power (default true, moved here from misc in 0.55)
	},
})

-- Bezier curves — macOS feel
hl.curve("macOpen", { type = "bezier", points = { { 0.16, 1.0 }, { 0.3, 1.0 } } }) -- easeOutExpo: fast start, smooth land
hl.curve("macClose", { type = "bezier", points = { { 0.4, 0.0 }, { 1.0, 1.0 } } }) -- easeInQuad: quick fade-out
hl.curve("macSwipe", { type = "bezier", points = { { 0.25, 0.46 }, { 0.45, 0.94 } } }) -- easeOutQuad: Spaces-style slide
hl.curve("macFade", { type = "bezier", points = { { 0.0, 0.0 }, { 0.0, 1.0 } } }) -- pure ease-out for opacity

-- Spring: slight underdamp → window-drag inertia like macOS
hl.curve("macSpring", { type = "spring", mass = 1, stiffness = 180, dampening = 26 })

-- Animations
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "macOpen", style = "popin 80%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.5, bezier = "macOpen", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "macClose", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, spring = "macSpring" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "macFade" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 2.5, bezier = "macFade" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "macOpen", style = "slide" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "macOpen", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "macClose" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.5, bezier = "macSwipe", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "macOpen", style = "slidevert" })
