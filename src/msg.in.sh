error()
{
    echo "$@" >&2
    return 1
}

msg()
{
    echo "$@"
}

verbose()
{
    if [ $verbose ] ; then
        echo "$@" >&2
    fi
}

die()
{
    error "$@"
    exit 1
}
