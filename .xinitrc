##
# Executed when X starts.
##

# Enviroment Variables {{{

PATH="$HOME/bin:$PATH" ; export PATH
LANG=en_US.UTF-8; export LANG
LC_CTYPE=$LANG; export LC_CTYPE

# force java >= 1.6.1 to recongnize xmonad as a non-reparenting wm (openjdk only?)
_JAVA_AWT_WM_NONREPARENTING=1 ; export _JAVA_AWT_WM_NONREPARENTING

# }}}

# X Settings {{{

# account for possible low default resolution on external monitor
if [ -n "`xrandr | grep '^VGA-0 connected'`" ] ; then
  xrandr --output VGA-0 --auto
elif [ -n "`xrandr | grep '^DVI-0 connected'`" ] ; then
  xrandr --output DVI-0 --auto
fi

# turn off beeps:
xset -b

# increase the keyboard repeat-rate:
xset r rate 250 30

# add local fonts
xset +fp /usr/share/fonts/local
xset fp rehash

# set a cursor since xmonad doesn't
xsetroot -cursor_name left_ptr

# set keymap options:
xmodmap ~/.Xmodmap

# disable caps lock
setxkbmap -option ctrl:nocaps

# ensure our x resources are loaded
xrdb -load ~/.Xresources

# }}}

# Desktop apps {{{

# hide mouse cursor after specified idle time:
unclutter -idle 2 -root -noevents &

# start keynav
keynav &

# set background
feh --bg-tile ~/.x-background.png

# start conky/dzen
conky -c ~/.dzen/conkyrc | ~/bin/dzen2 -xp 45 -wp 55 -h 16 -ta r &

# start compositing manager to fade out inactive windows
xcompmgr -c -r0 &

# start dunst to display dbus notification messages
dunst -config ~/.dunstrc &

# }}}

# Keyring, mail, etc. {{{

# start gnome-keyring-daemon
# see the following for getting gnome-keyring to unlock at startup w/ slim:
# https://wiki.archlinux.org/index.php/SLiM#SLiM_and_Gnome_Keyring
eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
export GNOME_KEYRING_CONTROL
export SSH_AUTH_SOCK

# initialize ssh keyring
~/.ssh/keyring

# start offlineimap loop
~/bin/offlineimap &

# start the dropbox daemon if installed
if [ -n "$(which dropboxd 2> /dev/null)" ] ; then
  dropboxd &
fi

# }}}

# start eclim
/opt/eclipse/eclimd start

exec xmonad

# vim:ft=sh:fdm=marker
