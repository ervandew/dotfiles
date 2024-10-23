# Configuration file for ipython.
import sys

#------------------------------------------------------------------------------
# InteractiveShellApp(Configurable) configuration
#------------------------------------------------------------------------------

## A Mixin for applications that start InteractiveShell instances.
#
#  Provides configurables for loading extensions and executing files as part of
#  configuring a Shell environment.
#
#  The following methods should be called by the :meth:`initialize` method of the
#  subclass:
#
#    - :meth:`init_path`
#    - :meth:`init_shell` (to be implemented by the subclass)
#    - :meth:`init_gui_pylab`
#    - :meth:`init_extensions`
#    - :meth:`init_code`

## Execute the given command string.
#c.InteractiveShellApp.code_to_run = ''

## Run the file referenced by the PYTHONSTARTUP environment variable at IPython
#  startup.
#c.InteractiveShellApp.exec_PYTHONSTARTUP = True

## List of files to run at IPython startup.
#c.InteractiveShellApp.exec_files = []

## lines of code to run at IPython startup.
#c.InteractiveShellApp.exec_lines = []

## A list of dotted module names of IPython extensions to load.
c.InteractiveShellApp.extensions = ['autoreload']

## dotted module name of an IPython extension to load.
#c.InteractiveShellApp.extra_extension = ''

## A file to be run
#c.InteractiveShellApp.file_to_run = ''

## Enable GUI event loop integration with any of ('glut', 'gtk', 'gtk2', 'gtk3',
#  'osx', 'pyglet', 'qt', 'qt4', 'qt5', 'tk', 'wx', 'gtk2', 'qt4').
#c.InteractiveShellApp.gui = None

## Should variables loaded at startup (by startup files, exec_lines, etc.) be
#  hidden from tools like %who?
#c.InteractiveShellApp.hide_initial_ns = True

## Configure matplotlib for interactive use with the default matplotlib backend.
#c.InteractiveShellApp.matplotlib = None

## Run the module as a script.
#c.InteractiveShellApp.module_to_run = ''

## Pre-load matplotlib and numpy for interactive use, selecting a particular
#  matplotlib backend and loop integration.
#c.InteractiveShellApp.pylab = None

## If true, IPython will populate the user namespace with numpy, pylab, etc. and
#  an ``import *`` is done from numpy and pylab, when using pylab mode.
#
#  When False, pylab mode should not import any names into the user namespace.
#c.InteractiveShellApp.pylab_import_all = True

## Reraise exceptions encountered loading IPython extensions?
#c.InteractiveShellApp.reraise_ipython_extension_failures = False

#------------------------------------------------------------------------------
# Application(SingletonConfigurable) configuration
#------------------------------------------------------------------------------

## This is an application.

## The date format used by logging formatters for %(asctime)s
#c.Application.log_datefmt = '%Y-%m-%d %H:%M:%S'

## The Logging format template
#c.Application.log_format = '[%(name)s]%(highlevel)s %(message)s'

## Set the log level by value or name.
#c.Application.log_level = 30

#------------------------------------------------------------------------------
# BaseIPythonApplication(Application) configuration
#------------------------------------------------------------------------------

## IPython: an enhanced interactive Python shell.

## Whether to create profile dir if it doesn't exist
#c.BaseIPythonApplication.auto_create = False

## Whether to install the default config files into the profile dir. If a new
#  profile is being created, and IPython contains config files for that profile,
#  then they will be staged into the new directory.  Otherwise, default config
#  files will be automatically generated.
#c.BaseIPythonApplication.copy_config_files = False

## Path to an extra config file to load.
#
#  If specified, load this config file in addition to any other IPython config.
#c.BaseIPythonApplication.extra_config_file = u''

## The name of the IPython directory. This directory is used for logging
#  configuration (through profiles), history storage, etc. The default is usually
#  $HOME/.ipython. This option can also be specified through the environment
#  variable IPYTHONDIR.
#c.BaseIPythonApplication.ipython_dir = u''

## Whether to overwrite existing config files when copying
#c.BaseIPythonApplication.overwrite = False

## The IPython profile to use.
#c.BaseIPythonApplication.profile = u'default'

## Create a massive crash report when IPython encounters what may be an internal
#  error.  The default is to append a short message to the usual traceback
#c.BaseIPythonApplication.verbose_crash = False

#------------------------------------------------------------------------------
# TerminalIPythonApp(BaseIPythonApplication,InteractiveShellApp) configuration
#------------------------------------------------------------------------------

## Whether to display a banner upon starting IPython.
#c.TerminalIPythonApp.display_banner = True

## If a command or file is given via the command-line, e.g. 'ipython foo.py',
#  start an interactive shell after executing the file or command.
#c.TerminalIPythonApp.force_interact = False

## Class to use to instantiate the TerminalInteractiveShell object. Useful for
#  custom Frontends
#c.TerminalIPythonApp.interactive_shell_class = 'IPython.terminal.interactiveshell.TerminalInteractiveShell'

## Start IPython quickly by skipping the loading of config files.
#c.TerminalIPythonApp.quick = False

#------------------------------------------------------------------------------
# InteractiveShell(SingletonConfigurable) configuration
#------------------------------------------------------------------------------

## An enhanced, interactive shell for Python.

## 'all', 'last', 'last_expr' or 'none', specifying which nodes should be run
#  interactively (displaying output from expressions).
#c.InteractiveShell.ast_node_interactivity = 'last_expr'

## A list of ast.NodeTransformer subclass instances, which will be applied to
#  user input before code is run.
#c.InteractiveShell.ast_transformers = []

## Make IPython automatically call any callable object even if you didn't type
#  explicit parentheses. For example, 'str 43' becomes 'str(43)' automatically.
#  The value can be '0' to disable the feature, '1' for 'smart' autocall, where
#  it is not applied if there are no more arguments on the line, and '2' for
#  'full' autocall, where all callable objects are automatically called (even if
#  no arguments are present).
#c.InteractiveShell.autocall = 0

## Autoindent IPython code entered interactively.
#c.InteractiveShell.autoindent = True

## Enable magic commands to be called without the leading %.
#c.InteractiveShell.automagic = True

## The part of the banner to be printed before the profile
#c.InteractiveShell.banner1 = 'Python 2.7.16 (default, Mar 11 2019, 18:59:25) \nType "copyright", "credits" or "license" for more information.\n\nIPython 5.4.1 -- An enhanced Interactive Python.\n?         -> Introduction and overview of IPython\'s features.\n%quickref -> Quick reference.\nhelp      -> Python\'s own help system.\nobject?   -> Details about \'object\', use \'object??\' for extra details.\n'

## The part of the banner to be printed after the profile
#c.InteractiveShell.banner2 = ''

## Set the size of the output cache.  The default is 1000, you can change it
#  permanently in your config file.  Setting it to 0 completely disables the
#  caching system, and the minimum value accepted is 20 (if you provide a value
#  less than 20, it is reset to 0 and a warning is issued).  This limit is
#  defined because otherwise you'll spend more time re-flushing a too small cache
#  than working
#c.InteractiveShell.cache_size = 1000

## Use colors for displaying information about objects. Because this information
#  is passed through a pager (like 'less'), and some pagers get confused with
#  color codes, this capability can be turned off.
#c.InteractiveShell.color_info = True

## Set the color scheme (NoColor, Neutral, Linux, or LightBG).
#c.InteractiveShell.colors = 'Neutral'

##
#c.InteractiveShell.debug = False

## **Deprecated**
#
#  Will be removed in IPython 6.0
#
#  Enable deep (recursive) reloading by default. IPython can use the deep_reload
#  module which reloads changes in modules recursively (it replaces the reload()
#  function, so you don't need to change anything to use it). `deep_reload`
#  forces a full reload of modules whose code may have changed, which the default
#  reload() function does not.  When deep_reload is off, IPython will use the
#  normal reload(), but deep_reload will still be available as dreload().
#c.InteractiveShell.deep_reload = False

## Don't call post-execute functions that have failed in the past.
#c.InteractiveShell.disable_failing_post_execute = False

## If True, anything that would be passed to the pager will be displayed as
#  regular output instead.
#c.InteractiveShell.display_page = False

## (Provisional API) enables html representation in mime bundles sent to pagers.
#c.InteractiveShell.enable_html_pager = False

## Total length of command history
#c.InteractiveShell.history_length = 10000

## The number of saved history entries to be loaded into the history buffer at
#  startup.
#c.InteractiveShell.history_load_length = 1000

##
#c.InteractiveShell.ipython_dir = ''

## Start logging to the given file in append mode. Use `logfile` to specify a log
#  file to **overwrite** logs to.
#c.InteractiveShell.logappend = ''

## The name of the logfile to use.
#c.InteractiveShell.logfile = ''

## Start logging to the default log file in overwrite mode. Use `logappend` to
#  specify a log file to **append** logs to.
#c.InteractiveShell.logstart = False

##
#c.InteractiveShell.object_info_string_level = 0

## Automatically call the pdb debugger after every exception.
#c.InteractiveShell.pdb = False

## Deprecated since IPython 4.0 and ignored since 5.0, set
#  TerminalInteractiveShell.prompts object directly.
#c.InteractiveShell.prompt_in1 = 'In [\\#]: '

## Deprecated since IPython 4.0 and ignored since 5.0, set
#  TerminalInteractiveShell.prompts object directly.
#c.InteractiveShell.prompt_in2 = '   .\\D.: '

## Deprecated since IPython 4.0 and ignored since 5.0, set
#  TerminalInteractiveShell.prompts object directly.
#c.InteractiveShell.prompt_out = 'Out[\\#]: '

## Deprecated since IPython 4.0 and ignored since 5.0, set
#  TerminalInteractiveShell.prompts object directly.
#c.InteractiveShell.prompts_pad_left = True

##
#c.InteractiveShell.quiet = False

##
#c.InteractiveShell.separate_in = '\n'

##
#c.InteractiveShell.separate_out = ''

##
#c.InteractiveShell.separate_out2 = ''

## Show rewritten input, e.g. for autocall.
#c.InteractiveShell.show_rewritten_input = True

## Enables rich html representation of docstrings. (This requires the docrepr
#  module).
#c.InteractiveShell.sphinxify_docstring = False

##
#c.InteractiveShell.wildcards_case_sensitive = True

##
#c.InteractiveShell.xmode = 'Context'

#------------------------------------------------------------------------------
# TerminalInteractiveShell(InteractiveShell) configuration
#------------------------------------------------------------------------------

## Set to confirm when you try to exit IPython with an EOF (Control-D in Unix,
#  Control-Z/Enter in Windows). By typing 'exit' or 'quit', you can force a
#  direct exit without any confirmation.
c.TerminalInteractiveShell.confirm_exit = False

## Options for displaying tab completions, 'column', 'multicolumn', and
#  'readlinelike'. These options are for `prompt_toolkit`, see `prompt_toolkit`
#  documentation for more information.
#c.TerminalInteractiveShell.display_completions = 'multicolumn'

## Shortcut style to use at the prompt. 'vi' or 'emacs'.
c.TerminalInteractiveShell.editing_mode = 'vi'
# disable any emacs bindings, which will help speed up exiting normal mode
# (<esc>) and maybe other stuff
c.TerminalInteractiveShell.emacs_bindings_in_vi_insert_mode = False

## Set the editor used by IPython (default to $EDITOR/vi/notepad).
#c.TerminalInteractiveShell.editor = u'vim'

## Enable vi (v) or Emacs (C-X C-E) shortcuts to open an external editor. This is
#  in addition to the F2 binding, which is always enabled.
#c.TerminalInteractiveShell.extra_open_editor_shortcuts = False

## Highlight matching brackets.
#c.TerminalInteractiveShell.highlight_matching_brackets = True

## The name or class of a Pygments style to use for syntax highlighting:
c.TerminalInteractiveShell.highlighting_style = 'friendly_grayscale'

## Override highlighting format for specific tokens
from IPython.terminal import prompts
from pygments import token
c.TerminalInteractiveShell.highlighting_style_overrides = {
  # token.Whitespace:             '#bbbbbb',
  # token.Comment:                '#999988',
  # token.Comment.Preproc:        'bold noitalic #999999',
  # token.Comment.Special:        'bold #999999',
  token.String:                 '#708090',
  token.String.Regex:           '#708090',
  token.Number:                 '#875f87',
  token.Keyword:                '#666666',
  # token.Keyword.Type:           '#666666',
  token.Name.Builtin:           '#999999',
  # token.Name.Function:          '#666666',
  # token.Name.Class:             '#666666',
  token.Name.Exception:         '#aaaaaa',
  token.Name.Namespace:         '#aaaaaa',
  # token.Name.Variable:          '#008080',
  # token.Name.Constant:          '#008080',
  # token.Name.Tag:               '#000080',
  # token.Name.Attribute:         '#008080',
  # token.Name.Entity:            '#800080',
  # token.Generic.Heading:        '#999999',
  # token.Generic.Subheading:     '#aaaaaa',
  # token.Generic.Deleted:        'bg:#ffdddd #000000',
  # token.Generic.Inserted:       'bg:#ddffdd #000000',
  # token.Generic.Error:          '#aa0000',
  # token.Generic.Emph:           'italic',
  # token.Generic.Strong:         'bold',
  # token.Generic.Prompt:         '#555555',
  # token.Generic.Output:         '#888888',
  # token.Generic.Traceback:      '#aa0000',
  # token.Error:                  'bg:#e3d2d2 #a61717',

  # the ipython prompt colors
  prompts.Token.Prompt:         '#808080',
  prompts.Token.PromptNum:      '#8787ff',
  prompts.Token.OutPrompt:      '#c0c0c0',
  prompts.Token.OutPromptNum:   '#8787ff',

  # prompt_toolkit completion menu colors (requires monkey patch below)
  'completion-menu': 'bg:#333333 #cccccc',
  'completion-menu.completion': 'bg:#333333 #cccccc',
  'completion-menu.completion.current': 'bg:#cccccc #444444',
  'completion-menu.meta.completion': 'bg:#333333 #cccccc',
  'completion-menu.meta.completion.current': 'bg:#cccccc #222222',
  'completion-menu.multi-column-meta': 'bg:#333333 #cccccc'
}

# hack to customize the exception stack trace colors
import IPython.core.excolors
import IPython.core.ultratb
import IPython.utils.coloransi
orig_ec = IPython.core.excolors.exception_colors
def _exception_colors():
  def _ansi(h):
    parts = (
      int(h[0:2], 16),
      int(h[2:4], 16),
      int(h[4:6], 16),
    )
    return '\033[38;2;%d;%d;%dm' % parts

  grey = _ansi('888888')
  ex_colors = orig_ec()
  ex_colors.add_scheme(
    IPython.utils.coloransi.ColorScheme('Neutral', {
      'topline': grey,
      'filename': grey,
      'lineno': grey,
      'name': grey,
      'vName': _ansi('cccccc'),
      'val': grey,
      'em': grey,
      # emphasized colors for the last frame
      'normalEm': grey,
      'filenameEm': grey,
      'linenoEm': _ansi('87afd7'),
      'nameEm': grey,
      'valEm': grey,
      'excName': _ansi('a25757'),
      'line': grey,
      'caret': grey,
      'Normal': _ansi('cccccc'),
      # debugger
      'prompt': grey,
      'breakpoint_enabled': grey,
      'breakpoint_disabled': grey,
    })
  )
  return ex_colors

IPython.core.excolors.exception_colors = _exception_colors
IPython.core.ultratb.exception_colors = _exception_colors
IPython.core.ultratb.VerboseTB.tb_highlight = 'bg:#333333'
IPython.core.ultratb.VerboseTB.tb_highlight_style = 'friendly_grayscale'

## Enable mouse support in the prompt
#c.TerminalInteractiveShell.mouse_support = False

prompt_py_version = '(py %s)' % '{0.major}.{0.minor}'.format(sys.version_info)
class Prompt(prompts.Prompts):
  def in_prompt_tokens(self):
    tokens = super().in_prompt_tokens()
    tokens.insert(0, (prompts.Token.Prompt, prompt_py_version))
    return tokens

  def out_prompt_tokens(self):
    # added just for allignment
    tokens = super().out_prompt_tokens()
    padding = 0
    for token in self.in_prompt_tokens()[:-3]:
      padding += len(token[1])
    tokens.insert(0, (prompts.Token.OutPrompt, ' ' * padding))
    return tokens

# Class used to generate Prompt token for prompt_toolkit
c.TerminalInteractiveShell.prompts_class = Prompt

# hack to allow prompt_toolkit completion styles to be set by
# highlighting_style_overrides above
import IPython.terminal.interactiveshell
import prompt_toolkit.styles
def _style_from_pygments_dict(pygments_dict):
   pygments_style = []
   for token, style in pygments_dict.items():
     if isinstance(token, str):
       pygments_style.append((token, style))
     else:
       pygments_style.append((
         prompt_toolkit.styles.pygments.pygments_token_to_classname(token),
         style
       ))
   return prompt_toolkit.styles.Style(pygments_style)

prompt_toolkit.styles.pygments.style_from_pygments_dict = _style_from_pygments_dict
IPython.terminal.interactiveshell.style_from_pygments_dict = _style_from_pygments_dict

## Use `raw_input` for the REPL, without completion and prompt colors.
#
#  Useful when controlling IPython as a subprocess, and piping STDIN/OUT/ERR.
#  Known usage are: IPython own testing machinery, and emacs inferior-shell
#  integration through elpy.
#
#  This mode default to `True` if the `IPY_TEST_SIMPLE_PROMPT` environment
#  variable is set, or the current terminal is not a tty.
#c.TerminalInteractiveShell.simple_prompt = False

## Number of line at the bottom of the screen to reserve for the completion menu
#c.TerminalInteractiveShell.space_for_menu = 6

## Automatically set the terminal title
#c.TerminalInteractiveShell.term_title = True

## Use 24bit colors instead of 256 colors in prompt highlighting. If your
#  terminal supports true color, the following command should print 'TRUECOLOR'
#  in orange: printf "\x1b[38;2;255;100;0mTRUECOLOR\x1b[0m\n"
#c.TerminalInteractiveShell.true_color = False

#------------------------------------------------------------------------------
# HistoryAccessor(HistoryAccessorBase) configuration
#------------------------------------------------------------------------------

## Access the history database without adding to it.
#
#  This is intended for use by standalone history tools. IPython shells use
#  HistoryManager, below, which is a subclass of this.

## Options for configuring the SQLite connection
#
#  These options are passed as keyword args to sqlite3.connect when establishing
#  database conenctions.
#c.HistoryAccessor.connection_options = {}

## enable the SQLite history
#
#  set enabled=False to disable the SQLite history, in which case there will be
#  no stored history, no SQLite connection, and no background saving thread.
#  This may be necessary in some threaded environments where IPython is embedded.
#c.HistoryAccessor.enabled = True

## Path to file to use for SQLite history database.
#
#  By default, IPython will put the history database in the IPython profile
#  directory.  If you would rather share one history among profiles, you can set
#  this value in each, so that they are consistent.
#
#  Due to an issue with fcntl, SQLite is known to misbehave on some NFS mounts.
#  If you see IPython hanging, try setting this to something on a local disk,
#  e.g::
#
#      ipython --HistoryManager.hist_file=/tmp/ipython_hist.sqlite
#
#  you can also use the specific value `:memory:` (including the colon at both
#  end but not the back ticks), to avoid creating an history file.
#c.HistoryAccessor.hist_file = u''

#------------------------------------------------------------------------------
# HistoryManager(HistoryAccessor) configuration
#------------------------------------------------------------------------------

## A class to organize all history-related functionality in one place.

## Write to database every x commands (higher values save disk access & power).
#  Values of 1 or less effectively disable caching.
#c.HistoryManager.db_cache_size = 0

## Should the history database include output? (default: no)
#c.HistoryManager.db_log_output = False

#------------------------------------------------------------------------------
# ProfileDir(LoggingConfigurable) configuration
#------------------------------------------------------------------------------

## An object to manage the profile directory and its resources.
#
#  The profile directory is used by all IPython applications, to manage
#  configuration, logging and security.
#
#  This object knows how to find, create and manage these directories. This
#  should be used by any code that wants to handle profiles.

## Set the profile location directly. This overrides the logic used by the
#  `profile` option.
#c.ProfileDir.location = u''

#------------------------------------------------------------------------------
# BaseFormatter(Configurable) configuration
#------------------------------------------------------------------------------

## A base formatter class that is configurable.
#
#  This formatter should usually be used as the base class of all formatters. It
#  is a traited :class:`Configurable` class and includes an extensible API for
#  users to determine how their objects are formatted. The following logic is
#  used to find a function to format an given object.
#
#  1. The object is introspected to see if it has a method with the name
#     :attr:`print_method`. If is does, that object is passed to that method
#     for formatting.
#  2. If no print method is found, three internal dictionaries are consulted
#     to find print method: :attr:`singleton_printers`, :attr:`type_printers`
#     and :attr:`deferred_printers`.
#
#  Users should use these dictionaries to register functions that will be used to
#  compute the format data for their objects (if those objects don't have the
#  special print methods). The easiest way of using these dictionaries is through
#  the :meth:`for_type` and :meth:`for_type_by_name` methods.
#
#  If no function/callable is found to compute the format data, ``None`` is
#  returned and this format type is not used.

##
#c.BaseFormatter.deferred_printers = {}

##
#c.BaseFormatter.enabled = True

##
#c.BaseFormatter.singleton_printers = {}

##
#c.BaseFormatter.type_printers = {}

#------------------------------------------------------------------------------
# PlainTextFormatter(BaseFormatter) configuration
#------------------------------------------------------------------------------

## The default pretty-printer.
#
#  This uses :mod:`IPython.lib.pretty` to compute the format data of the object.
#  If the object cannot be pretty printed, :func:`repr` is used. See the
#  documentation of :mod:`IPython.lib.pretty` for details on how to write pretty
#  printers.  Here is a simple example::
#
#      def dtype_pprinter(obj, p, cycle):
#          if cycle:
#              return p.text('dtype(...)')
#          if hasattr(obj, 'fields'):
#              if obj.fields is None:
#                  p.text(repr(obj))
#              else:
#                  p.begin_group(7, 'dtype([')
#                  for i, field in enumerate(obj.descr):
#                      if i > 0:
#                          p.text(',')
#                          p.breakable()
#                      p.pretty(field)
#                  p.end_group(7, '])')

##
#c.PlainTextFormatter.float_precision = ''

## Truncate large collections (lists, dicts, tuples, sets) to this size.
#
#  Set to 0 to disable truncation.
#c.PlainTextFormatter.max_seq_length = 1000

##
#c.PlainTextFormatter.max_width = 79

##
#c.PlainTextFormatter.newline = '\n'

##
#c.PlainTextFormatter.pprint = True

##
#c.PlainTextFormatter.verbose = False

#------------------------------------------------------------------------------
# Completer(Configurable) configuration
#------------------------------------------------------------------------------

## Enable unicode completions, e.g. \alpha<tab> . Includes completion of latex
#  commands, unicode names, and expanding unicode characters back to latex
#  commands.
#c.Completer.backslash_combining_completions = True

## Activate greedy completion PENDING DEPRECTION. this is now mostly taken care
#  of with Jedi.
#
#  This will enable completion on elements of lists, results of function calls,
#  etc., but can be unsafe because the code is actually evaluated on TAB.
#c.Completer.greedy = False

#------------------------------------------------------------------------------
# IPCompleter(Completer) configuration
#------------------------------------------------------------------------------

## Extension of the completer class with IPython-specific features

## DEPRECATED as of version 5.0.
#
#  Instruct the completer to use __all__ for the completion
#
#  Specifically, when completing on ``object.<tab>``.
#
#  When True: only those names in obj.__all__ will be included.
#
#  When False [default]: the __all__ attribute is ignored
#c.IPCompleter.limit_to__all__ = False

## Whether to merge completion results into a single list
#
#  If False, only the completion results from the first non-empty completer will
#  be returned.
#c.IPCompleter.merge_completions = True

## Instruct the completer to omit private method names
#
#  Specifically, when completing on ``object.<tab>``.
#
#  When 2 [default]: all names that start with '_' will be excluded.
#
#  When 1: all 'magic' names (``__foo__``) will be excluded.
#
#  When 0: nothing will be excluded.
#c.IPCompleter.omit__names = 2

#------------------------------------------------------------------------------
# ScriptMagics(Magics) configuration
#------------------------------------------------------------------------------

## Magics for talking to scripts
#
#  This defines a base `%%script` cell magic for running a cell with a program in
#  a subprocess, and registers a few top-level magics that call %%script with
#  common interpreters.

## Extra script cell magics to define
#
#  This generates simple wrappers of `%%script foo` as `%%foo`.
#
#  If you want to add script magics that aren't on your path, specify them in
#  script_paths
#c.ScriptMagics.script_magics = []

## Dict mapping short 'ruby' names to full paths, such as '/opt/secret/bin/ruby'
#
#  Only necessary for items in script_magics where the default path will not find
#  the right interpreter.
#c.ScriptMagics.script_paths = {}

#------------------------------------------------------------------------------
# StoreMagics(Magics) configuration
#------------------------------------------------------------------------------

## Lightweight persistence for python variables.
#
#  Provides the %store magic.

## If True, any %store-d variables will be automatically restored when IPython
#  starts.
#c.StoreMagics.autorestore = False
