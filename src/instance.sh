#\\define VARDB_DIR $tmp_dir
#\\include "var.in.sh"
#\\include "utils.in.sh"

tmp_dir="$(mktemp -u "${TMPDIR:-/tmp}/${appname}.XXXXXXX")"

cleanup() {
    if [ ! $keep ] ; then
        local clean_files
        read -r clean_files < "@VAR_DIR@/$IID/clean_files"
	rm -rf "$clean_files"
    fi
}


instance_create()
# usage: instance_create [<IID>]
# description:  create_instance
#               if $1 is not set, set IID from
#               calling random
# example: instance_create
{
    IID=$IID${IID+/}${1:-$(random)}
    mkdir -p "$tmp_dir"/$IID
    echo "$tmp_dir/$IID" > "$tmp_dir"/$IID/clean_files
}

instance_enter()
# usage: instance_enter
# description:  enter_instance
# example: instance_enter
{
    if [  -e "$tmp_dir"/self ] ; then
        # save last instance self
        mv -f "$tmp_dir/self" "$tmp_dir/$IID/.lastself"
    fi
    verbose "Entering instance '$IID'"
    ln -s $IID "$tmp_dir/self"
}

instance_leave()
# usage: instance_leave
# description:  leave old instance and return to last instance
# example: instance_leave
{
    rm "$tmp_dir"/self
    verbose "Leaving instance '$IID'"
    if [  -L "$tmp_dir"/$IID/.lastself ] ; then
        mv -f  "$tmp_dir"/$IID/.lastself "$tmp_dir"/self
        cleanup
        IID=$(readlink $tmp_dir/self)
        verbose "Returning to instance '$IID'"
    else
        cleanup
    fi
}
