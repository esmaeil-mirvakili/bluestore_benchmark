#!/bin/bash

#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n --without-dashboard

#sudo bin/ceph osd pool delete mybench mybench --yes-i-really-really-mean-it
#sudo ../src/stop.sh

#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -b -d -k -x -l --without-dashboard
#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -b -n -x -l --without-dashboard
#sudo MON=1 OSD=2 MDS=0 ../src/vstart.sh -n -b -x -l --without-dashboard
#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -b -x -l  -o 'bluestore fsck on mkfs = false' -o 'bluestore fsck on mount = false' -o 'bluestore fsck on umount = false' -o 'bluestore block db path = ' -o 'bluestore block wal path = ' -o 'bluestore block wal create = false' -o 'bluestore block db create = false' --without-dashboard
#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -o 'bluestore block = /dev/sdc' -o 'bluestore block path = /dev/sdc' -o 'bluestore fsck on mkfs = false' -o 'bluestore fsck on mount = false' -o 'bluestore fsck on umount = false' -o 'bluestore block db path = ' -o 'bluestore block wal path = ' -o 'bluestore block wal create = false' -o 'bluestore block db create = false' -o 'bluestore codel = true'  -o 'bluestore codel throughput latency tradeoff = 5' --without-dashboard
#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -o 'bluestore block = /dev/sdc' -o 'bluestore block path = /dev/sdc'  --without-dashboard
#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -o 'bluestore block = /dev/sdc' -o 'bluestore block path = /dev/sdc'
#sudo bin/ceph osd pool create mybench 128 128


sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n \
  -o 'bluestore block = /dev/sdc' \
  -o 'bluestore block path = /dev/sdc' \
  -o 'bluestore fsck on mkfs = false' \
  -o 'bluestore fsck on mount = false' \
  -o 'bluestore fsck on umount = false' \
  -o 'bluestore block db path = ' \
  -o 'bluestore block wal path = ' \
  -o 'bluestore block wal create = false' \
  -o 'bluestore block db create = false' \
  -o 'bluestore codel = false' \
  -o "bluestore codel throughput latency tradeoff = $SLOP_TARGET" \
  -o "bluestore codel throughput latency tradeoff = $TARGET" \
  -o "bluestore codel throughput latency tradeoff = $FAST_INTERVAL" \
  -o "bluestore codel throughput latency tradeoff = $SLOW_INTERVAL" \
  -o "bluestore codel throughput latency tradeoff = $STARTING_BUDGET" \
  -o "bluestore codel throughput latency tradeoff = $MIN_BUDGET" \
  -o "bluestore codel throughput latency tradeoff = $MAX_TARGET_LATENCY" \
  -o "bluestore codel throughput latency tradeoff = $MIN_TARGET_LATENCY" \
  -o "bluestore codel throughput latency tradeoff = $REGRESSION_HISTORY_SIZE" \
  --without-dashboard