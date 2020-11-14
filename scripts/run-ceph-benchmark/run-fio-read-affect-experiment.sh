#!/bin/bash
export CEPH_HOME=~/ceph
export FIO_HOME=~/fio
# run rbd bench and collect result
bs=4096
size=16106127360 # total bytes of io
qd=16 # workload queue depth
read_portion=$1
echo '============================================='
echo "read portion: ${read_portion}%"
echo '============================================='

#------------- clear rocksdb debug files -------------#
#sudo rm /tmp/flush_job_timestamps.csv  /tmp/compact_job_timestamps.csv

#------------- start cluster -------------#
./start_ceph.sh "0" "0" "0" "0" # this is normal Ceph cluster on HDD/SSD
#./start_ceph_ramdisk.sh # this is Ceph cluster on ramdisk
sudo bin/ceph osd pool create mybench 128 128
sudo bin/rbd create --size=40G mybench/image1
sudo bin/ceph daemon osd.0 config show | grep bluestore_rocksdb
sleep 5 # warmup

# change the fio parameters
sudo cp fio_read_write.fio fio_read_write_temp.fio
sed -i "s/iodepth=.*/iodepth=${qd}/g" fio_read_write_temp.fio
sed -i "s/bs=.*/bs=${bs}/g" fio_read_write_temp.fio
sed -i "s/rwmixread=.*/rwmixread=${read_portion}/g" fio_read_write_temp.fio

sed -i "s/bs=.*/bs=${bs}/g" fio_prefill_rbdimage.fio
sed -i "s/iodepth=.*/iodepth=${qd}/g" fio_prefill_rbdimage.fio
#------------- pre-fill -------------#    
# pre-fill the image(to eliminate the op_rw)
#echo pre-fill the image!
sudo LD_LIBRARY_PATH="$CEPH_HOME"/build/lib:$LD_LIBRARY_PATH "$FIO_HOME"/fio fio_prefill_rbdimage.fio
#------------- clear debug files and reset counters -------------#
# reset the perf-counter
sudo bin/ceph daemon osd.0 perf reset osd >/dev/null 2>/dev/null
sudo echo 3 | sudo tee /proc/sys/vm/drop_caches && sudo sync
# reset admin socket of OSD and BlueStore
sudo bin/ceph daemon osd.0 reset kvq vector

#------------- benchmark -------------#
    echo benchmark starts!
echo $qd
    sudo LD_LIBRARY_PATH="$CEPH_HOME"/build/lib:$LD_LIBRARY_PATH "$FIO_HOME"/fio fio_read_write_temp.fio --output-format=json --output=dump-fio-bench-${qd}.json 

# dump internal data with admin socket
# BlueStore
sudo bin/ceph daemon osd.0 dump kvq vector
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
sudo rm fio_read_write_temp.fio
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
