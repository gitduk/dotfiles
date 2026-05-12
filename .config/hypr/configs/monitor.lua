-- Monitor configuration
-- Run `hyprctl monitors` for available outputs.

-- Fallback: any unmatched monitor gets preferred mode
hl.monitor({ output = "",      mode = "preferred", position = "auto", scale = 1 })
-- Internal laptop display (HiDPI at 2x scale)
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 2 })

-- Uncomment and adjust as needed:
-- hl.monitor({ output = "eDP-1",   mode = "2560x1440@165", position = "0x0",  scale = 1 })
-- hl.monitor({ output = "DP-3",    mode = "1920x1080@240", position = "auto", scale = 1 })
-- hl.monitor({ output = "DP-1",    mode = "preferred",     position = "auto", scale = 1 })
-- hl.monitor({ output = "HDMI-A-1",mode = "preferred",     position = "auto", scale = 1 })

-- Mirror example:
-- hl.monitor({ output = "DP-3", mode = "1920x1080@60", position = "0x0", scale = 1, mirror = "DP-2" })

-- QEMU / virtual machines:
-- hl.monitor({ output = "Virtual-1", mode = "1920x1080@60", position = "auto", scale = 1 })
