#!/bin/bash -e
#\\include hadk.base.in.sh

buildmw()
{
    local GIT_URL="$1" 
    shift
    
    if [[ "$1" != "" && "$1" != *.spec ]]; then
        local GIT_BRANCH="-b $1"
        shift;
    fi

    local PKG="$(basename ${GIT_URL%.git})"

    local pkgdir=hybris/mw/$PKG

    if [ "$GIT_URL" = "$PKG" ]; then
        GIT_URL=https://github.com/mer-hybris/$PKG.git
        msg "No git url specified, assuming $GIT_URL"
    fi


    if [ -d "$ANDROID_ROOT/external/$PKG" ] && [ -r "$ANDROID_ROOT/external/$PKG" ]; then
        msg "Source code directory exists in \$ANDROID_ROOT/external. Building the existing version. Make sure to update this version by updating the manifest, if required."
        pkgdir=$ANDROID_ROOT/external/$PKG
    else

        if [ ! -d "$ANDROID_ROOT/hybris/mw/$PKG" ] ; then
            #FIXME
            msg "Source code directory doesn't exist, cloning repository"
            git clone --recurse-submodules "$GIT_URL" $GIT_BRANCH "$pkgdir" || die "cloning of $GIT_URL failed"
        else
            (
                cd "$pkgdir"
                msg  "pulling updates..."
                git pull
            )
        fi
    fi

    ./rpm/dhd/helpers/build_packages.sh \
        -b "$pkgdir" \
        -s "$1"
    

}

seperate_chainload()
# desc: seperate each chainload by running in a seperate instance for each job
{

    for job_func  in build build_sfos host ; do
        if is_function $job_func ; then
            case $job_func in
                build)
                    ubu_chrt_run "$0" -f "$device_file" job $job_func "$1";;
                build_sfos)
                    sfos_sdk_run "$0" -f "$device_file" job $job_func "$1";;
                host)
                    "$0" -f "$device_file" job $job_func "$1";;
            esac
        fi
    done
}


run_job()
# desc: run target job for the current instance
{
    if [ "$1" = "$job_target"  ] ; then
        verbose "$1: $job_func : begin"
        "$job_func"
        verbose "$1: $job_func : end"
        exit 0
    fi
}

case $1 in
    job)
        job_func="$2"
        job_target="$3"
        depend "$device_file" run_job
        ;;
    shell)
        case $2 in
            ubuntu) ubu_chrt_run "$0" -f "$device_file" enter_shell;;
            sfos) sfos_sdk_run "$0" -f "$device_file" enter_shell ;;
            host)
                cd "$ANDROID_ROOT"
                "${SHELL:-/bin/sh}"
        esac
        ;;
    enter_shell)
        export LC_COLLATE=POSIX
        export LC_NUMERIC=POSIX
        [ -e /parentroot/usr/share/ubu-chroot/mer-ubusdk-bash-setup ] && \
            shellrc=/parentroot/usr/share/ubu-chroot/mer-ubusdk-bash-setup
        cd "$ANDROID_ROOT"
        bash --init-file ${shellrc:-/mer-bash-setup} -i
        ;;
    *)
        if ! depend "$device_file" seperate_chainload  ; then
            error "$HADK_FILE_NOT_FOUND not found"
            exit 1
        fi
        ;;
esac
