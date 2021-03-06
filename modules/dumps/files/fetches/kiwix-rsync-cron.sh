#!/bin/sh
######################################
# This file is managed by puppet!
#  puppet:///modules/dumps/fetches/kiwix-rsync-cron.sh
######################################

sourcehost="download.kiwix.org"
bwlimit="--bwlimit=40000"

do_rsync (){
    srcpath=$1
    destpath=$2

    running=`/usr/bin/pgrep -f -x "/usr/bin/rsync -rlptq $bwlimit ${sourcehost}::${srcpath} ${destroot}/${destpath}"`
    if [ -z "$running" ]; then
        # filter out messages of the type
        #   file has vanished: "/zim/wikipedia/.wikipedia_tg_all_nopic_2016-05.zim.TQH5Zv" (in download.kiwix.org)
        #   rsync warning: some files vanished before they could be transferred (code 24) at main.c(1655) [generator=3.1.1]
        /usr/bin/rsync -rlptq --delete "$bwlimit" "${sourcehost}::${srcpath}" "${destroot}/${destpath}" 2>&1 | grep -v 'vanished'
    fi
}

if [ -z "$1" ]; then
    echo "Usage: $0 dest_base_dir"
    exit 1
fi

destroot="$1"

do_rsync "download.kiwix.org/zim/wikipedia/" "kiwix/zim/wikipedia/"
