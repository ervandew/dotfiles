# autostart x if logging in on tty1
if systemctl -q is-active graphical.target && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] ; then
  exec startx &> ~/.startx.log
else
  [[ -f ~/.bashrc ]] && . ~/.bashrc
fi

# vim:fdm=marker
