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


init_sfos()
{
    mkdir -p "$SFOSSDK_DIR"
    ${AGENT:-curl} "$SFOSSDK_URL" > "$SFOSSDK_DIR/${SFOSSDK_URL##*/}"
    sudo tar --numeric-owner -p -xjf "$SFOSSDK_DIR/${SFOSSDK_URL##*/}" -C "$SFOSSDK_DIR"
}

init_ubu()
{
    mkdir -p "$UBUCHRT_DIR"
    curl "$UBUCHRT_URL" > "$UBUCHRT_DIR/${UBUCHRT_URL##*/}"
    sudo tar --numeric-owner -xjf "$UBUCHRT_DIR/${UBUCHRT_URL##*/}" -C "$UBUCHRT_DIR"
}

update_sfos()
{

    sfos_sdk_run sudo zypper refresh unbreakmic
    sfos_sdk_run sudo zypper in android-tools
    
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
    

    #FIXME
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

while getopts hf:  arg ; do 
    case $arg in
        h) show_help; exit 0;;
        f) env_config=$OPTARG ;;
        *) : ;;
    esac
done

shift $(( $OPTIND - 1 ))

#FIXME
depend_path=$depend_path:"$PWD"

depend "${env_config:-local.base.hadk}"
depend hadk.env.src.hadk


case $1 in
    init) init $2;;
    update) update $2 ;;
    verify) verify ;;
    enter|shell) 
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
    *) error 'No mode suplied'; show_help; exit 1;;
esac
