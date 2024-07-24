# autostart x if logging in on tty1
if systemctl -q is-active graphical.target && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] ; then
  export XINITRC=$HOME/.config/xinit/xinitrc
  mkdir ~/.local/share/xinit 2> /dev/null || true
  exec startx 2>&1 >| ~/.local/share/xinit/startx.log
else
  [[ -f ~/.config/bash/bashrc ]] && . ~/.config/bash/bashrc
fi
