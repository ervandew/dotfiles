-- Global variables for luakit
globals = {
  homepage            = "about:blank",
  scroll_step         = 40,
  zoom_step           = 0.1,
  max_cmd_history     = 100,
  max_srch_history    = 100,
  default_window_size = "800x600",
}

-- Make useragent
local _, arch = luakit.spawn_sync("uname -sm")
-- fake chrome version so sites treate luakit as a modern browser
local chrome_version = "29.0.1547.72"
globals.useragent = string.format(
  "Mozilla/5.0 (X11; %s) AppleWebKit/%s (KHTML, like Gecko) Chrome/%s Safari/%s",
  string.sub(arch, 1, -2),
  luakit.webkit_user_agent_version,
  chrome_version,
  luakit.webkit_user_agent_version)

-- Search common locations for a ca file which is used for ssl connection validation.
local ca_files = {
  luakit.data_dir .. "/ca-certificates.crt",
  "/etc/certs/ca-certificates.crt",
  "/etc/ssl/certs/ca-certificates.crt",
}
-- Use the first ca-file found
for _, ca_file in ipairs(ca_files) do
  if os.exists(ca_file) then
    soup.ssl_ca_file = ca_file
    break
  end
end

-- Change to stop navigation sites with invalid or expired ssl certificates
soup.ssl_strict = false

-- Set cookie acceptance policy
cookie_policy = { always = 0, never = 1, no_third_party = 2 }
soup.accept_policy = cookie_policy.always

search_engines = {
  google      = "https://google.com/search?q=%s",
  amazon      = "http://amazon.com/s?url=search-alias%%3Daps&field-keywords=%s",
  github      = "https://github.com/search?q=%s",
  wikipedia   = "https://en.wikipedia.org/wiki/Special:Search?search=%s",
  weather     = "http://wunderground.com/cgi-bin/findweather/getForecast?query=%s",
}

search_engines.default = search_engines.google

domain_props = {}
