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
-f        Supply config via device config file
-t        Add custom template path

-x        Enable xtrace when executing unit
-V        Be more verbose
-h        Show this help
EOF
}

while getopts f:c:hxVt: arg ; do
    case $arg in
        f) device_file=$OPTARG;;
        t)
            depend_path="$OPTARG:$depend_path"
            # shellcheck disable=SC2145,SC2068
            # note: warnings not valid as it errors out because of the macro below
            @EXPORT_VAR_PREFIX@_DEPEND_PATH="$OPTARG":$@EXPORT_VAR_PREFIX@_DEPEND_PATH
            ;;
        h) show_help; exit 0;;
        x) shell_opt_xtrace=t;;
        V) verbose=t;;
        *) : ;;
    esac
done

shift $(( $OPTIND - 1 ))

if [ ! "$device_file" ] ; then
    error "Either device or device file must be given, exit 1"
    exit 1
fi




# first load each depend to check if every depend was found
# try witn $PWD/$device_file first
if ! depend "./$device_file" ; then
    # try a 2nd time without $PWD
    if ! depend "$device_file" ; then
        error "$HADK_FILE_NOT_FOUND not found"
        exit 1
    fi
fi
# After we checked if every dependcy is found we need to reset var.db
unset IID
reset_job_funcs
