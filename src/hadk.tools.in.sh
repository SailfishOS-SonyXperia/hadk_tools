#!/bin/sh

sfos_sdk_run()
{
    "$SFOSSDK_DIR//mer-sdk-chroot" "$@"
}

sfos_tooling_run()
{
    "$CHRTDIR"/toolings/SailfishOS-latest/mer-tooling-chroot
}

ubu_chrt_run()
{
    "$SFOSSDK_DIR//mer-sdk-chroot" \
                        ubu-chroot -r  \
                        "$UBUCHRT_DIR" "$@"
}


git_clone_or_update()
{
    local git_url=$1
    shift
    if [ "$1" ] ; then
        git_name="$1"
        shift
    else
        git_name="${git_url##*/}"
    fi
    

    if [ -e "$git_name" ] ; then
        (
            cd "$git_name" || return 1
            git pull --recurse-submodules
        )
    else
        git clone --recursive "$git_url" "$git_name" "$@"
    fi
}


cd_source_root()
{
    local SOURCE_ROOT="${SOURCE_ROOT:-$ANDROID_ROOT}"

    if [ "$ANDROID_ROOT" ] ; then
        # shellcheck disable=SC2154
        # note: We set $file somewhere else
        msg "$file: Please rename \$ANDROID_ROOT to \$SOURCE_ROOT"
    fi
    export ANDROID_ROOT="$SOURCE_ROOT"
    cd "$SOURCE_ROOT" || exit $?
}
