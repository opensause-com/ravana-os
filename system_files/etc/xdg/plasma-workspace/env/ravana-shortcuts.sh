# Ravana: apply the Mac-style desktop shortcuts the user accepted, before KWin starts.
_ravana_flag="${XDG_STATE_HOME:-$HOME/.local/state}/ravana/apply-shortcuts"
if [ -f "$_ravana_flag" ]; then
    /usr/libexec/ravana-apply-shortcuts && rm -f "$_ravana_flag"
fi
unset _ravana_flag
