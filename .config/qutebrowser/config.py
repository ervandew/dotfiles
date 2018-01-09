# basic config
c.auto_save.session = True
c.url.default_page = 'https://google.com'
c.url.start_pages = ['https://google.com']
c.url.searchengines = {'DEFAULT': 'https://google.com/search?q={}'}
c.editor.command = ['gvim', '-f', '-c "set spell spelllang=en_us"', '{}']
c.aliases.update({
  'h': 'help -t',
  'keyring': 'spawn --userscript keyring',
})

# open
config.bind('O', 'set-cmd-text :open {url:pretty}')

# tabs
config.bind('t', 'set-cmd-text -s :open -t')
config.bind('T', 'set-cmd-text :open -t {url:pretty}')
config.bind('D', 'tab-close')
config.bind('gh', 'tab-prev')
config.bind('gl', 'tab-next')
config.bind('gH', 'tab-move -')
config.bind('gL', 'tab-move +')

# hints
config.bind(';t', 'hint links tab-fg')
config.bind(';i', 'hint inputs')

# yanking
config.bind('yy', 'yank --sel')

# editing
config.bind('<ctrl-i>', 'open-editor', mode='insert')
config.bind('<ctrl-v>', 'insert-text {primary}', mode='insert')

# ui (colors, etc)
green = '#aece91'
red = '#bb4b4b'
yellow = '#e18964'
bg = '#333'
fg = '#dadada'
unfocused_bg = '#777'
unfocused_fg = '#bbb'
selected_bg = '#aaa'
selected_fg = '#222'
c.tabs.title.format = '{index}{perc}: {title}'
c.tabs.width.indicator = 0 # disable the indicator
c.hints.border = '1px solid #8eb157'
c.colors.hints.bg = green
c.colors.hints.fg = 'black'
c.colors.hints.match.fg = 'white'
c.colors.completion.match.fg = green
c.colors.messages.error.bg = red
c.colors.messages.info.bg = bg
c.colors.statusbar.normal.bg = bg
c.colors.statusbar.normal.fg = fg
c.colors.statusbar.command.bg = bg
c.colors.statusbar.command.fg = fg
c.colors.statusbar.progress.bg = unfocused_bg
c.colors.statusbar.url.success.http.fg = fg
c.colors.statusbar.url.success.https.fg = green
c.colors.statusbar.url.error.fg = red
c.colors.statusbar.url.warn.fg = yellow
c.colors.tabs.even.bg = unfocused_bg
c.colors.tabs.even.fg = unfocused_fg
c.colors.tabs.odd.bg = unfocused_bg
c.colors.tabs.odd.fg = unfocused_fg
c.colors.tabs.selected.even.bg = selected_bg
c.colors.tabs.selected.even.fg = selected_fg
c.colors.tabs.selected.odd.bg = selected_bg
c.colors.tabs.selected.odd.fg = selected_fg
