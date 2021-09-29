# Start gnome-keyring-daemon on login
if command -v gnome-keyring-daemon &>/dev/null; then
  eval $(gnome-keyring-daemon --start 2>/dev/null)
  export SSH_AUTH_SOCK
fi