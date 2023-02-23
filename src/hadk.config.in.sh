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

#\\include instance.in.sh

depend()
# usage: depend <file> [<chainload>]
# desc:  Load file an execute chainload if defend
#        Chainload is executed for all following depends.
#        The chainload is tried to be executed by the next dependend
#        if there is none its executed in the same depend is ince.
{
    if [ "$chainload" ] ; then
        file=$(var self/file/rel)
        file_abs=$(var self/file/abs)
        if [ ! -e "$tmp_dir"/chainload/dry_run ] ; then
            verbose "$file: $chainload"
            "$chainload" "$file_abs"
        fi
        # Ok so we had something to execute lets blow up a counter unit
        var self/chainload/executed=t
    fi
    reset_job_funcs

    # New IID
    # if we got no $tmp_dir/self we are at main instance, so init it
    if [ ! -e "$tmp_dir"/self ] ; then
	# init InstanceID to use if we can't use $tmp_dir/self
	# if we are the first instance our id is 1
	instance_create 1
	echo "$tmp_dir" > "$tmp_dir"/1/clean_files
    else
        # else gen rnd var and move old self to new instance and create new self
        instance_create
    fi
    instance_enter

    local file=$1; shift
    var self/file/rel=$file
    if [ $1 ] ; then
        local chainload=$1
        shift
    fi

    case $file in
        ./*)
            # Check if file is in $PWD or in a subfolder that is in $PWD
            local file_dirname=$(dirname "$file")
            case $file_dirname in
                .) depend_path=$depend_path:"$PWD" ;;
                ./*)
                    if [ -e "$PWD/$file_dirname" ] ; then
                        depend_path=$depend_path:"$PWD/$file_dirname"
                    fi
            esac
            ;;
        */*)
            depend_path=$depend_path:$(dirname $file)
            ;;
    esac

    case $file in
        /*)
            var self/file/abs="$file"
            source "$file"
            return
            ;;
        *)
            local dir IFS=:
            # shellcheck disable=SC2145,SC2068
            # note: warnings not valid as it errors out because of the macro below
            for dir in $depend_path${@EXPORT_VAR_PREFIX@_DEPEND_PATH+:${@EXPORT_VAR_PREFIX@_DEPEND_PATH}} ; do
                unset IFS

                if [ -e "$dir/$file" ] ;then
                    local file_abs="$dir/$file"
                    var self/file/abs="$file_abs"
                    local check \
                          build \
                          build_sfos \
                          sync \
                          host

                    verbose "Loading $file"
                    # Save the current counter and increase the pile of counter units
                    . "$file_abs"

                    # Restore IID
                    if [  ! -e self/chainload/executed ] ; then
                        # Ok it seams that the current counter unit pile is the same again
                        # Lets execute our chain load
                        if [ "$chainload" ] ; then
                            file=$(var self/file/rel)
                            file_abs=$(var self/file/abs)
                            if [ ! -e "$tmp_dir"/chainload/dry_run ] ; then
                                verbose "$file: $chainload"
                                "$chainload" "$file_abs"
                            fi
                        fi
                        reset_job_funcs
                    fi

                    if [ ! $IID = 1 ] ; then
                        instance_leave
                    fi
                    return 0
                else
                    IFS=:
                fi
            done
    esac


    HADK_FILE_NOT_FOUND="$file"

    cleanup

    return 1
}

for signal in TERM HUP QUIT; do
    trap "IID=1 cleanup; exit 1" $signal
done
unset signal
trap "IID=1 cleanup; exit 130" INT
