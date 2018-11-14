config_load()
{
    config=$1
    shift
    if [ -e "$PWD/.$config" ] ; then
        . "$PWD/.$config"
    elif [ -e "${CONFIGDIR:-${XDG_CONFIG_HOME:-$HOME/.config}}/$config" ] ; then
        . "${CONFIGDIR:-${XDG_CONFIG_HOME:-$HOME/.config}}/$config"
    else
        return 1
    fi
}
