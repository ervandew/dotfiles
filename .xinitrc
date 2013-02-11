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
export GNOME_KEYRING_PID
export GPG_AGENT_INFO
export SSH_AUTH_SOCK

# start gpg-agent
eval $(gpg-agent --daemon --allow-preset-passphrase)

# initialize ssh/gpg keyrings
~/.ssh/keyring
~/.gnupg/keyring

# start offlineimap loop
~/bin/offlineimap &

if [ -d ~/.xinitrc.d ] ; then
  for xrc in `find ~/.xinitrc.d -name '*.sh' | sort` ; do
    . $xrc
  done
fi

# }}}

# intialize display outputs
~/bin/monitor internal on
~/bin/monitor external on

# start eclim
/opt/eclipse/eclimd start

exec xmonad

# vim:ft=sh:fdm=marker
