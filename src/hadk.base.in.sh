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
Usage:    $appname -f <device file> [other <options>]
@HELP_DESCRIPTION@

-f        Device file
-t        Add custom template path
-j        Specifies  the  number  of jobs (commands) to run simultaneously.
          If the -j option is given without an argument,
          $appname will not limit the number of jobs that can
          run simultaneously.


-x        Enable xtrace when executing unit
-V        Be more verbose
-h        Show this help
EOF
}

while getopts f:c:hxVt:j: arg ; do
    case $arg in
        f) device_file=$OPTARG;;
        t)
            depend_path="$OPTARG:$depend_path"
            # shellcheck disable=SC2145,SC2068
            # note: warnings not valid as it errors out because of the macro below
            @EXPORT_VAR_PREFIX@_DEPEND_PATH="$OPTARG":$@EXPORT_VAR_PREFIX@_DEPEND_PATH
            ;;
        h) show_help; exit 0;;
        j) MAKE_JOBS=$OPTARG;;
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



if [ -z "$MAKE_FLAGS" ] ; then
   MAKE_FLAGS=$(($(nproc)/2))
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

mkdir "${XDG_CACHE_HOME:-$HOME/.cache}/$appname-$$"
echo "${XDG_CACHE_HOME:-$HOME/.cache}/$appname-$$" > "$tmp_dir/1/clean_files"

# Prepare temporary environment unit to pass any options down to slave instances
tmp_unit="${XDG_CACHE_HOME:-$HOME/.cache}/$appname-$$/env.hadk"
cat > $tmp_unit <<EOF
${depend_path+ depend_path=$depend_path}
${shell_opt_xtrace+ shell_opt_xtrace=t}
${verbose+ verbose=t}
${MAKE_JOBS+ MAKE_JOBS=$MAKE_JOBS}

depend "$device_file"
EOF

device_file="$tmp_unit"
