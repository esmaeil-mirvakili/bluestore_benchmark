#!/bin/bash

#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n --without-dashboard

#sudo bin/ceph osd pool delete mybench mybench --yes-i-really-really-mean-it
#sudo ../src/stop.sh

#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -b -d -k -x -l --without-dashboard
#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -b -n -x -l --without-dashboard
#sudo MON=1 OSD=2 MDS=0 ../src/vstart.sh -n -b -x -l --without-dashboard
#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -b -x -l  -o 'bluestore fsck on mkfs = false' -o 'bluestore fsck on mount = false' -o 'bluestore fsck on umount = false' -o 'bluestore block db path = ' -o 'bluestore block wal path = ' -o 'bluestore block wal create = false' -o 'bluestore block db create = false' --without-dashboard
sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -o 'bluestore block = /dev/sdc' -o 'bluestore block path = /dev/sdc' -o 'bluestore fsck on mkfs = false' -o 'bluestore fsck on mount = false' -o 'bluestore fsck on umount = false' -o 'bluestore block db path = ' -o 'bluestore block wal path = ' -o 'bluestore block wal create = false' -o 'bluestore block db create = false' -o 'bluestore codel = true'  -o 'bluestore codel slow interval = 500000000'  -o 'bluestore codel fast interval = 50000000'  -o 'bluestore codel initial target latency = 5000000'  -o 'bluestore codel min target latency = 1000000'  -o 'bluestore codel max target latency = 1000000000'  -o 'bluestore codel throughput latency tradeoff = 5'  -o 'bluestore codel initial budget bytes = 102400'  -o 'bluestore codel min budget bytes = 102400'  -o 'bluestore codel budget increment bytes = 10240'  -o 'bluestore codel regression history size = 100' --without-dashboard
#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -o 'bluestore block = /dev/sdc' -o 'bluestore block path = /dev/sdc'  --without-dashboard
#sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -o 'bluestore block = /dev/sdc' -o 'bluestore block path = /dev/sdc'
#sudo bin/ceph osd pool create mybench 128 128
