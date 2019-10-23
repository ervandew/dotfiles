from pygments import style, token
from pygments.token import (
  Comment,
  Error,
  Generic,
  Keyword,
  Name,
  Number,
  Operator,
  String,
  Whitespace,
)

class ErvandewStyle(style.Style):
  default_style = ''

  styles = {
    token.Whitespace:             '#bbbbbb',
    token.Comment:                '#999988',
    token.Comment.Preproc:        'bold noitalic #999999',
    token.Comment.Special:        'bold #999999',
    #token.Operator:               'bold',
    token.String:                 '#bb8844',
    token.String.Regex:           '#808000',
    token.Number:                 '#009999',
    token.Keyword:                '#5884b0',
    token.Keyword.Type:           '#445588',
    token.Name.Builtin:           '#999999',
    token.Name.Function:          '#990000',
    token.Name.Class:             '#445588',
    token.Name.Exception:         '#cf6171',
    token.Name.Namespace:         '#aaaaaa',
    token.Name.Variable:          '#008080',
    token.Name.Constant:          '#008080',
    token.Name.Tag:               '#000080',
    token.Name.Attribute:         '#008080',
    token.Name.Entity:            '#800080',
    token.Generic.Heading:        '#999999',
    token.Generic.Subheading:     '#aaaaaa',
    token.Generic.Deleted:        'bg:#ffdddd #000000',
    token.Generic.Inserted:       'bg:#ddffdd #000000',
    token.Generic.Error:          '#aa0000',
    token.Generic.Emph:           'italic',
    token.Generic.Strong:         'bold',
    token.Generic.Prompt:         '#555555',
    token.Generic.Output:         '#888888',
    token.Generic.Traceback:      '#aa0000',
    token.Error:                  'bg:#e3d2d2 #a61717',
  }
