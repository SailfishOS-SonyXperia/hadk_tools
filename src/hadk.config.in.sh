hadk_config_valid()
{
    local device_file=$1; shift
    
    if ! depend "$device_file" ; then
        error "$HADK_FILE_NOT_FOUND not found"
        exit 1
    fi


    set -x 
    if ! depend "$device_file" check ; then
        error "$HADK_FILE_NOT_FOUND not found"
        exit 1
    fi
    set +x
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
{
    local file=$1; shift
    if [ $1 ] ; then
        chainload=$1
        shift
    fi
    
    local IFS dir chainload_stat abs_file
    
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
            for dir in $depend_path ; do
                unset IFS

                if [ -e "$dir/$file" ] ;then
                    abs_file="$dir/$file"
                    
                    verbose "Loading $file"
                    if [ $chainload ] ; then
                        reset_job_funcs
                    fi
                     
                    . "$abs_file"


                    if [ "$chainload" ] ; then
                        verbose "$file: $chainload"
                        "$chainload" "$abs_file"
                        chainload_stat=$?
                        reset_job_funcs
                    fi
                    
                    return $chainload_stat
                else
                    IFS=:
                fi
            done
    esac


    HADK_FILE_NOT_FOUND="$file"
    
    return 1
}
