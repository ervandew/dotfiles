import os

# don't load settings configured from the gui, only from this file.
config.load_autoconfig(False)

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
# requires running (as regular user):
#   $ /usr/share/qutebrowser/scripts/dictcli.py install en-US
# Note: for profiles other than the default, symlink the installed dict
#   $ cd ~/.config/qutebrowser/<profile_dir>/data
#   $ ln -s ~/.local/share/qutebrowser/qtwebengine_dictionaries/ .
c.spellcheck.languages = ['en-US']

# when using multiple windows, always open tabs in the first window
# useful when using secondary windows for single page apps (music, etc)
c.new_instance_open_target_window = 'first-opened'

# disable scrolling through tabs via mouse wheel
c.tabs.mousewheel_switching = False

# prevent sites from triggering protocol handler prompts
# eg. for mailto:// links
c.content.register_protocol_handler = False

# Note: to get the best ad blocking install python-adblock (Brave's adblocker),
# then in qutebrowser run: :adblock-update
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
    c.content.blocking.whitelist = domains

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

# load any custome stylesheets
styles = str(config.configdir) + '/styles'
if os.path.exists(styles):
  c.content.user_stylesheets = [
    '%s/%s' % (styles, f) for f in os.listdir(styles)
  ]

### M$ Teams BS
# hint that will work for switching between chats
# (team channels already work by default)
c.hints.selectors['all'].append('.cle-title')
# hint to focus chat message input
c.hints.selectors['inputs'].append('.cke_wysiwyg_div')
###

### Example setting user agent when needed (spoofing osx here)
#c.content.headers.user_agent = \
#  'Mozilla/5.0 (Macintosh; Intel Mac OS X 11_3_1) ' \
#  'AppleWebKit/{webkit_version} (KHTML, like Gecko) ' \
#  '{qt_key}/{qt_version} ' \
#  '{upstream_browser_key}/{upstream_browser_version} ' \
#  'Safari/{webkit_version}'
###

### unbind some commands
# tabs
config.unbind('d', mode='normal')
# quickmarks
config.unbind('m', mode='normal')
config.unbind('b', mode='normal')
config.unbind('B', mode='normal')
config.unbind('wb', mode='normal')

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
for i in range(10):
  config.bind('<ctrl-%s>' % i, 'tab-focus %s' % i)

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
# best available command for custom binding to paste text into the command
# line, but unfortunately always appends (fine most of the time)
config.bind('<alt-r>*', 'set-cmd-text --append {primary}', mode='command')
config.bind('<ctrl-i>', 'edit-text', mode='insert')
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
c.fonts.default_size = '8pt'
c.fonts.default_family = 'sans-serif'
c.tabs.title.format = '{index}{perc}: {current_title}'
c.tabs.indicator.width = 0 # disable the indicator
c.hints.border = '1px solid #8eb157'
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
c.colors.tabs.pinned.even.bg = unfocused_bg
c.colors.tabs.pinned.even.fg = unfocused_fg
c.colors.tabs.pinned.odd.bg = unfocused_bg
c.colors.tabs.pinned.odd.fg = unfocused_fg
c.colors.tabs.pinned.selected.even.bg = selected_bg
c.colors.tabs.pinned.selected.even.fg = selected_fg
c.colors.tabs.pinned.selected.odd.bg = selected_bg
c.colors.tabs.pinned.selected.odd.fg = selected_fg
