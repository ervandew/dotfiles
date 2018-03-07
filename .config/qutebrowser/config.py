import os

# basic config
c.auto_save.session = True
c.search.incremental = True
c.url.default_page = 'https://google.com'
c.url.start_pages = ['https://google.com']
c.url.searchengines = {'DEFAULT': 'https://google.com/search?q={}'}
c.editor.command = [
  'gvim',
  '-f',
  '-c',
  'set spell spelllang=en_us | silent! call cursor({line}, {column})',
  '{}',
]
c.aliases.update({
  'h': 'help -t',
  'keyring': 'spawn --userscript keyring',
})
# requires running: $ sudo /usr/share/qutebrowser/script/install_dict.py en-US
c.spellcheck.languages = ['en-US']

# whitelist some hosts that prevent some sites from working properly
whitelist = str(config.configdir / 'whitelist')
if os.path.isfile(whitelist):
  with open(whitelist) as f:
    domains = []
    for line in f.readlines():
      if line.startswith('#'):
        continue
      domains.append(line.strip())
    c.content.host_blocking.whitelist = domains

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

# scrolling
# the default G/gg mappings use :scroll-to-perc, but that doesn't seem to work
# on a focused scrolling div, so use :scroll instead.
config.bind('gg', 'scroll top')
config.bind('G', 'scroll bottom')

# hints
config.bind(';t', 'hint links tab-fg')
config.bind(';i', 'hint inputs')

# yanking
config.bind('yy', 'yank --sel')

# editing
config.bind('<ctrl-i>', 'open-editor', mode='insert')
config.bind('<ctrl-v>', 'insert-text {primary}', mode='insert')

# ui (colors, etc)
magenta = '#cf9ebe'
green = '#aece91'
red = '#bb4b4b'
yellow = '#e18964'
bg = '#333'
fg = '#dadada'
unfocused_bg = '#777'
unfocused_fg = '#bbb'
selected_bg = '#aaa'
selected_fg = '#222'
default_font = '8pt monospace'
c.tabs.title.format = '{index}{perc}: {title}'
c.tabs.indicator.width = 0 # disable the indicator
c.hints.border = '1px solid #8eb157'
c.fonts.completion.entry = default_font
c.fonts.debug_console = default_font
c.fonts.downloads = '7pt monospace'
c.fonts.messages.error = default_font
c.fonts.messages.info = default_font
c.fonts.messages.warning = default_font
c.fonts.statusbar = default_font
c.fonts.tabs = default_font
c.colors.hints.bg = green
c.colors.hints.fg = 'black'
c.colors.hints.match.fg = 'white'
c.colors.completion.even.bg = '#333'
c.colors.completion.odd.bg = '#303030'
c.colors.completion.match.fg = green
c.colors.completion.item.selected.bg = '#444'
c.colors.completion.item.selected.fg = fg
c.colors.completion.item.selected.border.top = '#555'
c.colors.completion.item.selected.border.bottom = '#555'
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
c.colors.statusbar.url.hover.fg = magenta
c.colors.tabs.even.bg = unfocused_bg
c.colors.tabs.even.fg = unfocused_fg
c.colors.tabs.odd.bg = unfocused_bg
c.colors.tabs.odd.fg = unfocused_fg
c.colors.tabs.selected.even.bg = selected_bg
c.colors.tabs.selected.even.fg = selected_fg
c.colors.tabs.selected.odd.bg = selected_bg
c.colors.tabs.selected.odd.fg = selected_fg
