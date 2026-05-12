-- Window rules
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

-- Floating popups (tag c1 = mpd, notebook, clipboard)
hl.window_rule({ match = { title = "^(mpd|nb|clipboard)$" }, tag = "c1" })
hl.window_rule({ match = { tag = "c1" }, float = true })
hl.window_rule({ match = { tag = "c1" }, center = true })
hl.window_rule({ match = { tag = "c1" }, size = { "window_w * 1.2", "window_h" } })

-- Float anonymous / empty-class windows (Chrome notifications, etc.)
hl.window_rule({ match = { class = "^$" }, float = true })
hl.window_rule({ match = { title = "^$" }, float = true })
hl.window_rule({ match = { initial_class = "^$" }, float = true })
hl.window_rule({ match = { initial_title = "^$" }, float = true })

-- Workspace animation overrides (0.55+: per-workspace animation style)
hl.workspace_rule({ workspace = "special", animation = "fade" }) -- fade feels more overlay-like than slidevert

-- Layer rules
hl.layer_rule({ match = { namespace = "rofi" }, blur = true })
hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
hl.layer_rule({ match = { namespace = "launcher" }, blur = true })
hl.layer_rule({ match = { namespace = "overview" }, blur = true })

hl.layer_rule({
	name = "no-anim-for-selection",
	match = { namespace = "selection" },
	no_anim = true,
})
