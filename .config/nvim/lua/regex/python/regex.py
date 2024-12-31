# execute: python "<script>" "<file>" <flags>
import io
import re
import sys

def main():
  f = open(sys.argv[1], 'r')
  flags = len(sys.argv) > 2 and sys.argv[2] or ''

  try:
    content = f.read().strip()
    regex_text = content.split('\n', 1)
    if len(regex_text) != 2:
      return

    regex, text = regex_text

    pflags = 0
    if 'm' in flags:
      pflags |= re.MULTILINE
    if 'i' in flags:
      pflags |= re.IGNORECASE
    if 'd' in flags:
      pflags |= re.DOTALL

    pattern = re.compile(regex, pflags)

    pos = len(content) - len(text)
    for match in pattern.finditer(text):
      string = io.StringIO()
      string.write('%s-%s' % (match.start() + pos, match.end() + pos - 1))
      if(match.groups()):
        for ii in range(1, len(match.groups()) + 1):
          if match.start(ii) >= 0:
            string.write(',%s-%s' % (match.start(ii) + pos, match.end(ii) + pos - 1))

      print(string.getvalue())
  finally:
    f.close()

if __name__ == '__main__':
  main()
