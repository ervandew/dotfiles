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

# allow some hosts that prevent some sites from working properly
allow = str(config.configdir / 'allowlist')
if os.path.isfile(allow):
  with open(allow) as f:
    domains = []
    for line in f.readlines():
      line = line.strip()
      if not line or line.startswith('#'):
        continue
      domains.append(line.strip())
    c.content.host_blocking.whitelist = domains

redirects = str(config.configdir / 'redirects')
if os.path.isfile(redirects):
  redirect_domains = {}
  with open(redirects) as f:
    for line in f.readlines():
      line = line.strip()
      if not line or line.startswith('#'):
        continue

      from_domain, __, to_domain = line.partition(' ')
      redirect_domains[from_domain.strip()] = to_domain.strip()

  from PyQt5.QtCore import QUrl
  from qutebrowser.api import interceptor

  def intercept(info: interceptor.Request):
    redirect = redirect_domains.get(info.request_url.host())
    if redirect:
      new_url = QUrl(info.request_url)
      new_url.setHost(redirect)
      try:
        info.redirect(new_url)
      except interceptors.RedirectFailedException:
        pass

  interceptor.register(intercept)

### M$ Teams BS
# hint that will work for switching between chats
# (team channels already work by default)
c.hints.selectors['all'].append('.cle-title')
# hint to focus chat message input
c.hints.selectors['inputs'].append('.cke_wysiwyg_div')
# stylesheet to make teams bearable
c.content.user_stylesheets = [
  str(config.configdir) + '/styles/msteams.css',
]
###

# workaround for aparent bug where rogue tab keypresses are received and
# causing qutebrowser to scroll to the top of the page when switching
# workspaces, etc.
config.bind('<tab>', ':nop')

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
# the default G/gg and <ctrl-u/d> mappings use :scroll-to-perc and :scroll-page
# respectively, but those don't seem to work on a focused scrolling div, so use
# :scroll instead.
config.bind('gg', 'scroll top')
config.bind('G', 'scroll bottom')
config.bind('<ctrl-u>', 'run-with-count 15 scroll up')
config.bind('<ctrl-d>', 'run-with-count 15 scroll down')
# no default 0/$ scrolling (no begin/end, so use a count of 100)
config.bind('0', 'run-with-count 100 scroll left')
config.bind('$', 'run-with-count 100 scroll right')

# hints
config.bind(';t', 'hint links tab-fg')
config.bind(';T', 'hint links fill :open -t {hint-url}')
config.bind(';O', 'hint links fill :open {hint-url}')
config.bind(';y', 'hint links yank-primary')
config.bind(';i', 'hint inputs')
# open url via xdg-open (useful when using dedicated qutebrowser instance for a
# single web app, but you want the option to open links in your main browser)
config.bind(';x', 'hint links spawn xdg-open {hint-url}')

# yanking
config.bind('yy', 'yank --sel')

# editing
config.bind('<alt-r>*', 'insert-text {primary}', mode='insert')
# no command yet which can insert clipboard text to command line
#config.bind('<alt-r>*', 'insert-text {primary}', mode='command')
config.bind('<ctrl-i>', 'open-editor', mode='insert')
config.bind('<ctrl-i>', 'edit-command', mode='command')

# command history nav
config.bind('<up>', 'command-history-prev', mode='command')
config.bind('<down>', 'command-history-next', mode='command')

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
default_font = '8pt terminus'
c.tabs.title.format = '{index}{perc}: {current_title}'
c.tabs.indicator.width = 0 # disable the indicator
c.hints.border = '1px solid #8eb157'
c.fonts.completion.entry = default_font
c.fonts.debug_console = default_font
c.fonts.downloads = '7pt terminus'
c.fonts.messages.error = default_font
c.fonts.messages.info = default_font
c.fonts.messages.warning = default_font
c.fonts.statusbar = default_font
c.fonts.tabs.selected = default_font
c.fonts.tabs.unselected = default_font
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
