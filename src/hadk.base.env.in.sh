appname=${0##*/}
CONFIGDIR="${XDG_DATA_HOME:-$HOME/.local/share}/hadk"
depend_path="$CONFIGDIR"/devices:"$CONFIGDIR":"$PWD"
#\\define EXPORT_VAR_PREFIX HADK
