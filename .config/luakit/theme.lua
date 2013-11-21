--------------------------
-- Default luakit theme --
--------------------------

local theme = {}

-- Default settings
theme.font = "monospace normal 9"
theme.fg   = "#ccc"
theme.bg   = "#222"

-- Genaral colours
theme.success_fg = "#0f0"
theme.loaded_fg  = "#33AADD"
theme.error_fg = "#FFF"
theme.error_bg = "#F00"

-- Warning colours
theme.warning_fg = "#F00"
theme.warning_bg = "#FFF"

-- Notification colours
theme.notif_fg = "#444"
theme.notif_bg = "#FFF"

-- Menu colours
theme.menu_fg                   = "#ccc"
theme.menu_bg                   = "#222"
theme.menu_selected_fg          = "#000"
theme.menu_selected_bg          = "#c4c466"
theme.menu_title_bg             = "#222"
theme.menu_primary_title_fg     = "#ccc"
theme.menu_secondary_title_fg   = "#ccc"

-- Proxy manager
theme.proxy_active_menu_fg      = '#000'
theme.proxy_active_menu_bg      = '#FFF'
theme.proxy_inactive_menu_fg    = '#888'
theme.proxy_inactive_menu_bg    = '#FFF'

-- Statusbar specific
theme.sbar_fg         = "#ccc"
theme.sbar_bg         = "#222"

-- Downloadbar specific
theme.dbar_fg         = "#ccc"
theme.dbar_bg         = "#222"
theme.dbar_error_fg   = "#F00"

-- Input bar specific
theme.ibar_fg           = "#222"
theme.ibar_bg           = "#ddd"

-- Tab label
theme.tab_fg            = "#666"
theme.tab_bg            = "#222"
theme.tab_ntheme        = "#999"
theme.selected_fg       = "#ccc"
theme.selected_bg       = "#333"
theme.selected_ntheme   = "#aaa"
theme.loading_fg        = "#33AADD"
theme.loading_bg        = "#000"

-- Trusted/untrusted ssl colours
theme.trust_fg          = "#8eb157"
theme.notrust_fg        = "#cf6171"

return theme
-- vim: et:sw=4:ts=8:sts=4:tw=80
