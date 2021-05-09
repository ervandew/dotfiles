#!/bin/bash

# Note must also add the following entries to /etc/pam.d/login at the end of
# the auth/session sections accordingly:
#   auth       optional     pam_gnome_keyring.so
#   session    optional     pam_gnome_keyring.so auto_start
# start gnome-keyring-daemon
if ! $(grep -E "auth\s+optional\s+pam_gnome_keyring.so" /etc/pam.d/login &> /dev/null) ; then
  echo "xinitrc: Missing pam_gnome_keyring auth entry in /etc/pam.d/login"
elif ! $(grep -E "session\s+optional\s+pam_gnome_keyring.so\s+auto_start" /etc/pam.d/login &> /dev/null) ; then
  echo "xinitrc: Missing pam_gnome_keyring session entry in /etc/pam.d/login"
else
  eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
  export GNOME_KEYRING_CONTROL
  export GNOME_KEYRING_PID
  export GPG_AGENT_INFO
  export SSH_AUTH_SOCK

  # initialize ssh/gpg keyrings
  ~/.ssh/keyring
  ~/.gnupg/keyring

  # start gpg-agent
  eval $(gpg-agent --daemon --allow-preset-passphrase)

  # import ssh auth sock into systemctl user env so that backup service can
  # utilize it
  systemctl --user import-environment SSH_AUTH_SOCK
fi
