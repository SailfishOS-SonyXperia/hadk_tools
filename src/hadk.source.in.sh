#!/bin/sh

#\\include hadk.base.in.sh


if ! depend "$device_file" sync ; then
    error "$HADK_FILE_NOT_FOUND not found"
    exit 1
fi
