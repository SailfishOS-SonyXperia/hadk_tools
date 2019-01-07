#!/bin/bash
set -e

#\\include hadk.base.env.in.sh
#\\include hadk.tools.in.sh
#\\include msg.in.sh
#\\include hadk.config.in.sh
#\\include config.in.sh

show_help()
{
    cat <<EOF
$appname - help
-f supply config via device config file
EOF
}

while getopts f:c:hV arg ; do
    case $arg in
        f) device_file=$OPTARG;;
        h) show_help; exit 0;;
        V) verbose=t;;
        *) : ;;
    esac
done

shift $(( $OPTIND - 1 ))

if [ ! "$device_file" ] ; then
    error "Either device or device file must be given, exit 1"
    exit 1
fi

depend_path=$depend_path:"$CONFIGDIR"/devices



# first load each depend to check if every depend was found
# try witn $PWD/$device_file first
if ! depend "./$device_file" ; then
    # try a 2nd time without $PWD
    if ! depend "$device_file" ; then
        error "$HADK_FILE_NOT_FOUND not found"
        exit 1
    fi
fi
