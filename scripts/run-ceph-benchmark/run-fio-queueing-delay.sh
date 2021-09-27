#!/bin/bash
export CEPH_HOME=~/ceph
export CEPH_CONF=~/ceph/build/ceph.conf
export FIO_HOME=~/fio
# run rbd bench and collect result
codel=$1
ssd_thread_num=$2
echo '=================================================================='
printf 'queue depth: %s\n' $1
printf 'io type: %s\n' $2
printf 'block size: %s\n' $3

# no need to change
pool="mybench"

#------------- start cluster -------------#
./start_ceph.sh # this is normal Ceph cluster on HDD/SSD
#./start_ceph_ramdisk.sh # this is Ceph cluster on ramdisk
sudo bin/ceph osd pool create mybench 128 128
sudo bin/rbd create --size=40G mybench/image1
sudo bin/ceph daemon osd.0 config show | grep bluestore_rocksdb
sleep 5 # warmup

#sudo rm -f fio_write_edited.fio
#sudo rm -f fio_prefill_rbdimage_edited.fio
#sudo cp fio_write.fio fio_write_edited.fio
#sudo cp fio_prefill_rbdimage.fio fio_prefill_rbdimage_edited.fio
#
## change the fio parameters
#sed -i "s/iodepth=.*/iodepth=${qd}/g" fio_write_edited.fio
#if [ ! -z "$bssplit" ]; then
#    sed -i "s~bs=.*~bssplit=${bssplit}~g" fio_write_edited.fio
#    sed -i "s~bs=.*~bssplit=${bssplit}~g" fio_prefill_rbdimage_edited.fio
#else
#    sed -i "s/bs=.*/bs=${bs}/g" fio_write_edited.fio
#    sed -i "s/bs=.*/bs=${bs}/g" fio_prefill_rbdimage_edited.fio
#fi
#sed -i "s/rw=.*/rw=${rw}/g" fio_write_edited.fio
#sed -i "s/runtime=.*/runtime=${fioruntime}/g" fio_write_edited.fio
#
#sed -i "s/rw=.*/rw=${rw}/g" fio_prefill_rbdimage_edited.fio
#sed -i "s/iodepth=.*/iodepth=${qd}/g" fio_prefill_rbdimage_edited.fio
#sed -i "s/runtime=.*/runtime=${prefill_time}/g" fio_prefill_rbdimage_edited.fio
#------------- pre-fill -------------#    
# pre-fill the image(to eliminate the op_rw)
#echo pre-fill the image!
sudo LD_LIBRARY_PATH="$CEPH_HOME"/build/lib:$LD_LIBRARY_PATH "$FIO_HOME"/fio fio_prefill_rbdimage_edited.fio
#------------- clear debug files and reset counters -------------#
# reset the perf-counter
sudo bin/ceph daemon osd.0 perf reset osd >/dev/null 2>/dev/null
sudo echo 3 | sudo tee /proc/sys/vm/drop_caches && sudo sync
# reset admin socket of OSD and BlueStore
if [ "$codel" = 1 ] ; then
  sudo bin/ceph daemon osd.0 enable codel
fi
sudo bin/ceph daemon osd.0 reset kvq vector
sudo bin/ceph daemon osd.0 reset op vector

#------------- benchmark -------------#
echo benchmark starts!
sudo LD_LIBRARY_PATH="$CEPH_HOME"/build/lib:$LD_LIBRARY_PATH "$FIO_HOME"/fio fio_write_edited.fio --output-format=json --output=dump-fio-bench.json

# dump internal data with admin socket
# BlueStore
sudo bin/ceph daemon osd.0 dump kvq vector
sudo bin/ceph daemon osd.0 dump op vector
# OSD
# aggregation
# rbd info
sudo bin/rbd info mybench/image1 | tee dump_rbd_info.txt
# get rocksdb debug files
#sudo cp /tmp/compact_job_timestamps.csv /tmp/flush_job_timestamps.csv /tmp/l0recover_job_timestamps.csv ${dn}
    echo benchmark stops!

#------------- stop cluster -------------#
sudo bin/rbd rm mybench/image1
sudo bin/ceph osd pool delete $pool $pool --yes-i-really-really-mean-it
sudo ../src/stop.sh

# move everything to a directory
# sudo mv dump* ${dn}
# sudo cp ceph.conf ${dn}
# sudo cp fio_write.fio ${dn}
# sudo cp start_ceph.sh ${dn}
# sudo cp plot-bluestore-lat.py ${dn}
# sudo mv ${dn} ./data
# echo DONE!
#done

#cd ./data/${dn} && sudo python3 plot-bluestore-lat.py
