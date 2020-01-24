##
# Executed when X starts.
##

# load system level xinitrc files
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
  for xrc in /etc/X11/xinit/xinitrc.d/?*.sh ; do
    if [ -x "$xrc" ] ; then
      echo "Running system level xinitrc: $xrc"
      . "$xrc"
    fi
  done
fi

# load .Xresources before starting xmonad
[[ -f ~/.Xresources ]] && xrdb -load ~/.Xresources

# Enviroment Variables {{{

PATH="$HOME/bin:$PATH" ; export PATH
LANG=en_US.UTF-8; export LANG
LC_CTYPE=$LANG; export LC_CTYPE

# force java >= 1.6.1 to recongnize xmonad as a non-reparenting wm (openjdk only?)
_JAVA_AWT_WM_NONREPARENTING=1 ; export _JAVA_AWT_WM_NONREPARENTING

# }}}

# load user level xinitrc files
if [ -d ~/.xinitrc.d ] ; then
  for xrc in $(find -L ~/.xinitrc.d -name '*.sh' | sort) ; do
    echo "Running user level xinitrc: $xrc"
    . "$xrc"
  done
fi

exec xmonad

# vim:ft=sh:fdm=marker
