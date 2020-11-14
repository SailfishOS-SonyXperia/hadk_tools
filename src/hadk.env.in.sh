#!/bin/bash -e
#\\include hadk.base.env.in.sh
#\\include hadk.tools.in.sh
#\\include hadk.config.in.sh
#\\include msg.in.sh


show_help()
{
    cat <<EOF
$appname - help

usage: $appname [<options>] mode

-h --help show help
-f        custom environment
-t        add custom template path
-s        Supply custom hadk file when initialising the sdk

modes: 
init - download env and initialise
update - update sdk against latest changes
verify - check env (NYI)
EOF
}




init()
{
    case $1 in
        sfos)
            init_sfos
            update_sfos
            ;;
        ubuntu)
            init_ubu
            update_ubu
            ;;
        *)
            init_sfos
            update_sfos

            init_ubu
            update_ubu
            ;;
    esac
}

update()
{
    case $1 in
        sfos)
            update_sfos
            ;;
        ubuntu)
            update_ubu
            ;;
        *)
            update_sfos
            update_ubu
            ;;
    esac
}


is_local() {
    case $1  in
        *://*) return 1 ;;
    esac
}


init_sfos()
{
    local sfossdk_src_url="$SFOSSDK_URL"
    mkdir -p "$SFOSSDK_DIR"
    if ! is_local "$SFOSSDK_URL" ; then
        ${AGENT:-curl} "$SFOSSDK_URL" > "$SFOSSDK_DIR/${SFOSSDK_URL##*/}"
        sfossdk_src_url="$SFOSSDK_DIR/${SFOSSDK_URL##*/}"
    fi
    sudo tar --numeric-owner -p -xjf "$sfossdk_src_url" -C "$SFOSSDK_DIR"
    case ${SFOSSDK_URL##*/} in
        *devel*)
            sfos_sdk_run sudo ssu r
            ;;
    esac
}

init_ubu()
{

    local ubuchrt_src_url="$UBUCHRT_URL"
    mkdir -p "$UBUCHRT_DIR"
    if ! is_local "$UBUCHRT_URL" ; then
        ${AGENT:-curl} "$UBUCHRT_URL" > "$UBUCHRT_DIR/${UBUCHRT_URL##*/}"
        ubuchrt_src_url="$UBUCHRT_DIR/${UBUCHRT_URL##*/}"
    fi
    sudo tar --numeric-owner -xjf "$ubuchrt_src_url" -C "$UBUCHRT_DIR"
}

update_sfos()
{
    sfos_sdk_run sudo zypper -n in android-tools
    
    echo c | sfos_sdk_run sudo zypper -n in android-tools-hadk \
                          createrepo_c \
                          zip \
                          tar \
                          lvm2 \
                          atruncate \
                          pigz \
                          git \
                          mic \
                          rpm-python   # not auto-installed dep of mic
    

    sfos_sdk_run sudo ssu re $RELEASE
    sfos_sdk_run sudo zypper ref
    echo c| sfos_sdk_run sudo zypper -n dup
}

update_ubu()
{
    # ubu chrt
    ubu_chrt_run sudo apt-get -y update
    # bsdmainutils provides `column`, otherwise an informative Android's
    # `make modules` target fails
    ubu_chrt_run sudo apt-get -y install bsdmainutils
    # Add OpenJDK 1.7 VM, and switch to it:
    ubu_chrt_run sudo apt-get -y install openjdk-8-jdk
    ubu_chrt_run sudo update-java-alternatives -s java-1.8.0-openjdk-amd64
    # Add rsync for the way certain HW adaptations package their system
    # partition; also vim and unzip for convenience
    ubu_chrt_run sudo apt-get -y install rsync vim unzip wget
}

verify()
{
  cat <<EOF_1 | sfos_sdk_run  --
cat > /tmp/sb2_hello_world.c << EOF
#include <stdlib.h>            
#include <stdio.h>             
int main(void) {               
printf("SB2 TEST OK\n");        
return EXIT_SUCCESS;            
}      
EOF
EOF_1
sfos_sdk_run "sb2 gcc /tmp/sb2_hello_world.c -o /tmp/sb2_hello_world && sb2 /tmp/sb2_hello_world" | grep 'SB2 TEST OK'
}

env_config=local.base.hadk
env_src_hadk=hadk.env.src.hadk


while getopts hf:t:s:  arg ; do
    case $arg in
        h) show_help; exit 0;;
        t)
            depend_path="$OPTARG:$depend_path"
            # shellcheck disable=SC2145,SC2068
            # note: warnings not valid as it errors out because of the macro below
            @EXPORT_VAR_PREFIX@_DEPEND_PATH="$OPTARG":$@EXPORT_VAR_PREFIX@_DEPEND_PATH
            ;;
        f) env_config=$OPTARG ;;
        s) env_src_hadk=$OPTARG ;;
        *) : ;;
    esac
done

shift $(( $OPTIND - 1 ))

#FIXME
depend_path=$depend_path:"$PWD"

depend "${env_config}"


case $1 in
    init)
        depend "${env_src_hadk}"
        init $2;;
    update) update $2 ;;
    verify) verify ;;
    enter|shell)
        # shellcheck disable=SC2145,SC2068
        # note: warnings not valid as it errors out because of the macro below
        case $2 in
            ubuntu) ubu_chrt_run "$0" \
                                 -f "${env_config}" \
                                 ${@EXPORT_VAR_PREFIX@_DEPEND_PATH+ -t "${@EXPORT_VAR_PREFIX@_DEPEND_PATH}"} \
                                 enter_shell
                    ;;
            sfos) sfos_sdk_run "$0" \
                               -f "${env_config}" \
                               ${@EXPORT_VAR_PREFIX@_DEPEND_PATH+ -t "${@EXPORT_VAR_PREFIX@_DEPEND_PATH}"} \
                               enter_shell ;;
            host)
                cd "${SOURCE_ROOT:-$ANDROID_ROOT}"
                "${SHELL:-/bin/sh}"
        esac
        ;;
    enter_shell)
        export LC_COLLATE=POSIX
        export LC_NUMERIC=POSIX
        [ -e /parentroot/usr/share/ubu-chroot/mer-ubusdk-bash-setup ] && \
            shellrc=/parentroot/usr/share/ubu-chroot/mer-ubusdk-bash-setup
        [ "${SOURCE_ROOT:-$ANDROID_ROOT}" ] && cd "${SOURCE_ROOT:-$ANDROID_ROOT}"
        bash --init-file ${shellrc:-/mer-bash-setup} -i
        ;;
    *) error 'No mode suplied'; show_help; exit 1;;
esac
