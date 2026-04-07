# autostart x if logging in on tty1
if systemctl -q is-active graphical.target && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] ; then
  export XINITRC=$HOME/.config/xinit/xinitrc
  mkdir ~/.local/share/xinit 2> /dev/null || true
  systemd-cat -t x-session --stderr-priority=3 startx
else
  [[ -f ~/.config/bash/bashrc ]] && . ~/.config/bash/bashrc
fi
