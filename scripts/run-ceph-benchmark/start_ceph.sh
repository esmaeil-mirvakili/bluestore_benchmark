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
sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -o 'bluestore_codel = "$codel"' -o 'bluestore_codel_target_latency = $target_lat' -o 'bluestore_codel_interval = $interval' -o 'bluestore_codel_starting_budget = $batch_size' -o 'ms_dispatch_throttle_bytes = 1073741824' -o 'objecter_inflight_op_bytes = 1073741824' -o 'objecter_inflight_ops = 40960' -o 'bluestore block = /dev/sdc' -o 'bluestore block path = /dev/sdc' -o 'bluestore fsck on mkfs = false' -o 'bluestore fsck on mount = false' -o 'bluestore fsck on umount = false' -o 'bluestore block db path = ' -o 'bluestore block wal path = ' -o 'bluestore block wal create = false' -o 'bluestore block db create = false' --without-dashboard
#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -o 'bluestore block = /dev/sdc' -o 'bluestore block path = /dev/sdc'  --without-dashboard
#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -o 'bluestore block = /dev/sdc' -o 'bluestore block path = /dev/sdc'
#sudo bin/ceph osd pool create mybench 128 128
