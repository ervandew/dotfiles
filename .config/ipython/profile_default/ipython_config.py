import sys

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

## Override highlighting format for specific tokens
from IPython.terminal import prompts
from pygments import token
c.TerminalInteractiveShell.highlighting_style_overrides = {
  # pygments tokens: https://pygments.org/docs/tokens/
  token.Keyword:                '#666666',
  token.Name.Builtin:           '#999999',
  token.Name.Exception:         '#aaaaaa',
  token.Name.Namespace:         '#aaaaaa',
  token.Number:                 '#875f87',
  token.Operator.Word:          '#875fd7',
  token.String.Regex:           '#708090',
  token.String:                 '#708090',

  # the ipython prompt colors
  prompts.Token.Prompt:         '#808080',
  prompts.Token.PromptNum:      '#8787ff',
  prompts.Token.OutPrompt:      '#c0c0c0',
  prompts.Token.OutPromptNum:   '#8787ff',

  # ipython specific highlights: search for "class:" in ipython/prompt_toolkit
  # prompt_toolkit completion menu colors (requires monkey patch below)
  'completion-menu': 'bg:#333333 #cccccc',
  'completion-menu.completion': 'bg:#333333 #cccccc',
  'completion-menu.completion.current': 'bg:#cccccc #444444',
  'completion-menu.meta.completion': 'bg:#333333 #cccccc',
  'completion-menu.meta.completion.current': 'bg:#cccccc #222222',
  'completion-menu.multi-column-meta': 'bg:#333333 #cccccc',

  # bracket/paren match
  'matching-bracket.other': 'bg:#333333 #cf9ebe',
}

# choose a better color combo for highlighting lines in a stack trace
# (default is near unreadable)
import IPython.core.ultratb
IPython.core.ultratb.VerboseTB.tb_highlight = 'bg:#333333'

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
