hadk_config_valid()
{
    local device_file=$1; shift
    
    if ! depend "$device_file" ; then
        error "$HADK_FILE_NOT_FOUND not found"
        exit 1
    fi


    if ! depend "$device_file" check ; then
        error "$HADK_FILE_NOT_FOUND not found"
        exit 1
    fi
}

is_function() {
    case "$(LANG=C type -- "$1" 2>/dev/null)" in
        *function*) return 0 ;;
    esac
    return 1
}

reset_job_funcs()
{

    unset -f check \
          build \
          build_sfos \
          sync \
          host
}


depend()
# usage: depend <file> [<chainload>]
# desc:  Load file an execute chainload if defend
#        Chainload is executed for all following depends.
#        The chainload is tried to be executed by the next dependend
#        if there is none its executed in the same depend is ince.
{
    if [ "$chainload" ] ; then
        verbose "$file: $chainload"
        "$chainload" "$abs_file"
        # Ok so we had something to execute lets blow up a counter unit
        [ $depth_counter -gt 0 ] && depth_counter=$((${depth_counter:-1}-1))
        # depth_counter should never go below zero
    fi
    reset_job_funcs

    file=$1; shift
    if [ $1 ] ; then
        local chainload=$1
        shift
    fi

    local IFS dir

    case $file in
        ./*)
            depend_path=$depend_path:"$PWD"
            ;;
        */*)
            depend_path=$depend_path:$(dirname $file)
            ;;
    esac

    case $file in
        /*)
            source "$file"
            ;;
        *)
            IFS=:
            # shellcheck disable=SC2145,SC2068
            # note: warnings not valid as it errors out because of the macro below
            for dir in $depend_path${@EXPORT_VAR_PREFIX@_DEPEND_PATH+:${@EXPORT_VAR_PREFIX@_DEPEND_PATH}} ; do
                unset IFS

                if [ -e "$dir/$file" ] ;then
                    abs_file="$dir/$file"
                    
                    verbose "Loading $file"
                    local old_depth_counter=${depth_counter:-0}
                    local depth_counter=$((${depth_counter:-1}+1))
                    # Save the current counter and increase the pile of counter units
                    . "$abs_file"
                    if [ $depth_counter -eq $old_depth_counter ] ; then
                        # Ok it seams that the current counter unit pile is the same again
                        # Lets execute our chain load
                        if [ "$chainload" ] ; then
                            verbose "$file: $chainload"
                            "$chainload" "$abs_file"
                        fi
                        reset_job_funcs
                    fi
                    return 0
                else
                    IFS=:
                fi
            done
    esac


    HADK_FILE_NOT_FOUND="$file"

    return 1
}
