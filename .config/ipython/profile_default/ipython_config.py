import sys

import IPython.core.ultratb
import IPython.terminal.prompts
import IPython.terminal.interactiveshell
import prompt_toolkit.styles
from pygments.token import Token

## A list of dotted module names of IPython extensions to load.
c.InteractiveShellApp.extensions = ['autoreload']

## Set the color scheme (NoColor, Neutral, Linux, or LightBG).
c.InteractiveShell.colors = 'Neutral'

## Set to confirm when you try to exit IPython with an EOF (Control-D in Unix,
#  Control-Z/Enter in Windows). By typing 'exit' or 'quit', you can force a
#  direct exit without any confirmation.
c.TerminalInteractiveShell.confirm_exit = False

## Shortcut style to use at the prompt. 'vi' or 'emacs'.
c.TerminalInteractiveShell.editing_mode = 'vi'
# disable any emacs bindings, which will help speed up exiting normal mode
# (<esc>) and maybe other stuff
c.TerminalInteractiveShell.emacs_bindings_in_vi_insert_mode = False

c.TerminalInteractiveShell.shortcuts = [
  {
    'new_keys': ['escape', 'backspace'], # this actually translates to: Alt+BS
    'command': 'prompt_toolkit:named_commands.backward_kill_word',
    'create': True,
  },
]

## Override highlighting format for specific tokens
c.TerminalInteractiveShell.highlighting_style_overrides = {
  # pygments tokens: https://pygments.org/docs/tokens/
  Token.Keyword:                '#666666',
  Token.Name.Builtin:           '#999999',
  Token.Name.Exception:         '#aaaaaa',
  Token.Name.Namespace:         '#aaaaaa',
  Token.Number:                 '#875f87',
  Token.Operator.Word:          '#875fd7',
  Token.String.Regex:           '#708090',
  Token.String:                 '#708090',

  # the ipython prompt colors
  Token.Prompt:                 '#8787ff',
  Token.Prompt.Version:         '#808080',

  # ipython specific highlights: search for "class:" in ipython/prompt_toolkit
  # prompt_toolkit completion menu colors (requires monkey patch below)
  'completion-menu': 'bg:#333333 #cccccc',
  'completion-menu.completion': 'bg:#333333 #cccccc',
  'completion-menu.completion.current': 'bg:#cccccc #444444',
  'completion-menu.meta.completion': 'bg:#333333 #cccccc',
  'completion-menu.meta.completion.current': 'bg:#cccccc #222222',
  'completion-menu.multi-column-meta': 'bg:#333333 #cccccc',

  # bracket/paren match
  'matching-bracket.cursor': 'bg:#333333 #cf9ebe', # insert mode only
  'matching-bracket.other': 'bg:#333333 #cf9ebe',
}

# choose a better color combo for highlighting lines in a stack trace
# (default is near unreadable)
IPython.core.ultratb.VerboseTB.tb_highlight = 'bg:#333333'

prompt_py_version = 'py %s ' % '{0.major}.{0.minor}'.format(sys.version_info)
class Prompt(IPython.terminal.prompts.Prompts):
  def in_prompt_tokens(self):
    return [
      (Token.Prompt.Version, prompt_py_version),
      (Token.Prompt, '> '),
    ]

  def out_prompt_tokens(self):
    padding = sum(len(t[1]) for t in self.in_prompt_tokens()[:-1])
    return [
      (Token.OutPrompt, ' ' * padding),
      (Token.OutPrompt, '  '),
    ]

# Class used to generate Prompt token for prompt_toolkit
c.TerminalInteractiveShell.prompts_class = Prompt

# hack to allow prompt_toolkit completion styles to be set by
# highlighting_style_overrides above
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
