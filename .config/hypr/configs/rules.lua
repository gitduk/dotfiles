--------------------------
------ Window rules ------
--------------------------

-- Get window class: `hyprctl clients | grep class`

-- opacity
hl.window_rule({ match = { fullscreen = true }, opacity = "1.0" })

-- Chrome
hl.window_rule({ match = { class = "(?i).*chrome.*" }, workspace = "special" })

-- Hyprland matches RE2 FullMatch: patterns must cover the whole title/class
-- WeChat
hl.window_rule({ match = { title = "(?i).*weixin.*" }, workspace = "special" })
hl.window_rule({ match = { title = "(?i).*weixin.*" }, center = true })

-- Obsidian
hl.window_rule({ match = { class = "(?i).*obsidian.*" }, workspace = "special" })

-- Code editors
hl.window_rule({ match = { class = "(?i)(.*zed.*|code)" }, workspace = "2" })

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
