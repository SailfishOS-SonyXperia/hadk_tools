#\\ifndef VARDB_DIR
#\\error VARDB_DIR not set, please set a directory for storing variables
#\\endif

var()
# usage: var var[=content]
# description: set var to content if =content is not given, output content of var
#              vars can be put in an other by using / just like when creating dirs
{
    case $1 in
	*=|*=*)
	    local __var_part1=$( echo "$1" | sed -e 's/[+-]*=.*//' -e 's/^[+,-]//' )
            local __var_part2=$( echo "$1" | cut -d '=' -f2- )
	    local __var12="@VARDB_DIR@/$__var_part1"
	    mkdir -p "${__var12%/*}"
	    case $1 in
		*+=*)
		    if [ -d "@VARDB_DIR@/$__var_part1" ] ; then
			printf  '%s' $__var_part2 > "@VARDB_DIR@/$__var_part1/"\  $((
				$( echo "@VARDB_DIR@"/$__var_part2/* \
				    | tail  | xargs basename ) + 1 ))
		    else
			printf '%s' "$__var_part2" >> "@VARDB_DIR@/$__var_part1"
		    fi
		    ;;
 		*-=*) false ;;
                *)  printf '%s' "$__var_part2" > "@VARDB_DIR@/$__var_part1" ;;
	    esac
	    ;;
	*)
	    if [ -d "@VARDB_DIR@/$1" ] ; then
                ls -1v "@VARDB_DIR@/$1"
	    elif [ -e "@VARDB_DIR@/$1" ] ; then
		cat "@VARDB_DIR@/$1"
	    else
		return 1
	    fi
	    ;;
    esac
}

unvar()
# usage: unvar <var>
# desription: remove var
{
    rm -rf "${tmp_dir:?}/$1"
}
