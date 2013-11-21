-- load the default config first
dofile("/etc/xdg/luakit/rc.lua")

-- Bindings {{{
local key, buf = lousy.bind.key, lousy.bind.buf

add_binds("normal", {

  key({}, "D", "Close current tab (or `[count]` tabs).",
    function (w, m) for i=1,m.count do w:close_tab() end end, {count=1}),

  buf("^gh$", "Go to previous tab.",
    function (w) w:prev_tab() end),

  buf("^gl$", "Go to next tab (or `[count]` nth tab).",
    function (w, b, m)
      if not w:goto_tab(m.count) then w:next_tab() end
    end,
    {count=0}
  ),

  buf("^gH$", "Reorder tab left `[count=1]` positions.",
    function (w, b, m)
      w.tabs:reorder(w.view, w.tabs:current() - m.count)
    end,
    {count=1}
  ),

  buf("^gL$", "Reorder tab right `[count=1]` positions.",
    function (w, b, m)
      w.tabs:reorder(w.view, (w.tabs:current() + m.count) % w.tabs:count())
    end,
    {count=1}
  ),

  key({"Control"}, "l", "",
    function (w, m) w:clear_search() end),

}, true)

-- }}}

-- Settings {{{

require "cookies"
cookies.session_timeout = 60 * 60 * 24 * 7
cookies.store_session_cookies = true

-- Use a custom charater set for hint labels
local s = follow.label_styles
follow.label_maker = s.sort(s.reverse(s.charset("sdfghjkl")))

-- Customize some of the hint styles
follow.stylesheet = follow.stylesheet .. [===[
#luakit_follow_overlay .hint_label {
    background-color: #555;
    color: #ccc;
    opacity: 1;
    padding: 1px;
}
]===]

-- }}}

-- vim:fdm=marker
