#!/bin/sh

#\\define HELP_DESCRIPTION "Setup sources in <device file>"

#\\include hadk.base.in.sh


seperate_chainload()
# desc: seperate each chainload by running in a seperate instance for each job
{
    if is_function sync ; then
        cd_source_root
        if ! sync ; then
            die "Error exit status $exit_status in $device_file:$1:sync()"
        fi
    fi
}


if ! depend "$device_file" seperate_chainload ; then
    error "$HADK_FILE_NOT_FOUND not found"
    exit 1
fi
