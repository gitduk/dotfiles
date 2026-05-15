--------------------------
------ Window rules ------
--------------------------

-- Get window class: `hyprctl clients | grep class`

-- Browser
hl.window_rule({ match = { class = "(?i)(google-chrome|chromium)" }, workspace = "1" })

-- WeChat
hl.window_rule({ match = { title = "(?i)(weixin)" }, workspace = "3" })
hl.window_rule({ match = { title = "(?i)(weixin)" }, center = true })

-- Code editors (tag then assign workspace)
hl.window_rule({ match = { class = "(?i)(zed|dev.zed.Zed|dev.zed.Zed-Preview|Code)" }, tag = "code" })
hl.window_rule({ match = { tag = "code" }, workspace = "2" })

-- Special workspace apps
hl.window_rule({ match = { class = "(?i)(Yaak-app|Dataflare)" }, workspace = "special" })
hl.window_rule({ match = { class = "(?i)(Yaak-app|Dataflare)" }, float = false })

-- Float anonymous / empty-class windows (Chrome notifications, etc.)
hl.window_rule({ match = { class = "^$" }, float = true })
hl.window_rule({ match = { title = "^$" }, float = true })
hl.window_rule({ match = { initial_class = "^$" }, float = true })
hl.window_rule({ match = { initial_title = "^$" }, float = true })

-- Ignore maximize requests from all apps. You'll probably like this.
hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-----------------------------
------ Workspace rules ------
-----------------------------

hl.workspace_rule({ workspace = "1", persistent = true })
hl.workspace_rule({ workspace = "2", persistent = true })
hl.workspace_rule({ workspace = "3", persistent = true })
hl.workspace_rule({ workspace = "special", animation = "fade" })
hl.workspace_rule({ workspace = "special", gaps_in = 0, gaps_out = 0 })

-------------------------
------ Layer rules ------
-------------------------

hl.layer_rule({ match = { namespace = "rofi" }, blur = true })
hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
hl.layer_rule({ match = { namespace = "launcher" }, blur = true })
hl.layer_rule({ match = { namespace = "overview" }, blur = true })

hl.layer_rule({
	name = "no-anim-for-selection",
	match = { namespace = "selection" },
	no_anim = true,
})
