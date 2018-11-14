depend()
{
    if [ -e "$PWD/$1" ] ; then
        
    config_load "$1"
}
