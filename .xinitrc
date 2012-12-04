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

if [ -d ~/.xinitrc.d ] ; then
  for xrc in `find ~/.xinitrc.d -type f -o -type l -name '*.sh' | sort` ; do
    . $xrc
  done
fi

# }}}

# setup external monitor if connected
~/bin/monitor on

# start eclim
/opt/eclipse/eclimd start

exec xmonad

# vim:ft=sh:fdm=marker
