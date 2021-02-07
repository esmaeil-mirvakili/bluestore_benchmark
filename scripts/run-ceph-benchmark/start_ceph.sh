#!/bin/bash

codel=$1
if [ "$codel" = 1 ] ; then
    codel=true
fi
target_lat=$2
interval=$3
batch_size=$4
drive_loc=$5
batch_size_limit_ratio=1.5
adaptive_down_sizing=true

#sudo bin/ceph osd pool delete mybench mybench --yes-i-really-really-mean-it
#sudo ../src/stop.sh

#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -b -d -k -x -l --without-dashboard
#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -b -n -x -l --without-dashboard
#sudo MON=1 OSD=2 MDS=0 ../src/vstart.sh -n -b -x -l --without-dashboard
#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -b -x -l  -o 'bluestore fsck on mkfs = false' -o 'bluestore fsck on mount = false' -o 'bluestore fsck on umount = false' -o 'bluestore block db path = ' -o 'bluestore block wal path = ' -o 'bluestore block wal create = false' -o 'bluestore block db create = false' --without-dashboard
sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -o 'bluestore codel = "$codel"' -o 'bluestore codel target latency = $target_lat' -o 'bluestore codel interval = $interval' -o 'bluestore codel starting budget = $batch_size' -o 'objecter_inflight_ops = 40960' -o 'bluestore block = "$drive_loc"' -o 'bluestore block path = "$drive_loc"' -o 'bluestore fsck on mkfs = false' -o 'bluestore fsck on mount = false' -o 'bluestore fsck on umount = false' -o 'bluestore block db path = ' -o 'bluestore block wal path = ' -o 'bluestore block wal create = false' -o 'bluestore block db create = false' --without-dashboard
#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -o 'bluestore block = /dev/sdc' -o 'bluestore block path = /dev/sdc'  --without-dashboard
#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -o 'bluestore block = /dev/sdc' -o 'bluestore block path = /dev/sdc'
#sudo bin/ceph osd pool create mybench 128 128
