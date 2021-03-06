#!/bin/bash
export CEPH_HOME=~/ceph
export FIO_HOME=~/fio
# run rbd bench and collect result
bs=$3   #"131072"  # block size 
rw=$2  # io type
fioruntime=300  # seconds
prefill_time=$(( 2*fioruntime ))
iototal="400m" # total bytes of io
qd=$1 # workload queue depth
codel=$4
target_lat=$5
interval=$6
batch_size=$7
drive=$8
bssplit=$9
echo '=================================================================='
printf 'queue depth: %s\n' $1
printf 'io type: %s\n' $2
printf 'block size: %s\n' $3

# no need to change
DATA_FILE=dump-lat-analysis.csv  # output file name
pool="mybench"
dn=${rw}-${bs}-$(date +"%Y_%m_%d_%I_%M_%p")
sudo mkdir -p ${dn} # create data if not created

single_dump() {
    qdepth=$1
    dump_state="dump-state-${qdepth}.json"
    sudo bin/ceph daemon osd.0 perf dump 2>/dev/null > $dump_state
	clt_bw=$(echo "$(jq '.jobs[0].write.bw' dump-fio-bench-${qdepth}.json) / 1024" | bc -l) #client throughput MB/s
	clt_lat=$(echo "$(jq '.jobs[0].write.lat_ns.mean' dump-fio-bench-${qdepth}.json) / 1000000000" | bc -l) # client latency seconds
	osd_op_w_lat=$(jq ".osd.op_w_latency.avgtime" $dump_state)
	osd_op_queueing_time=$(jq ".osd.osd_op_queueing_time.avgtime" $dump_state)
	osd_on_committed_lat=$(jq ".osd.osd_on_committed_lat.avgtime" $dump_state)
	bluestore_writes_lat=$(jq ".bluestore.bluestore_writes_lat.avgtime" $dump_state) # simple+deferred write latency
	bluestore_simple_writes_lat=$(jq ".bluestore.bluestore_simple_writes_lat.avgtime" $dump_state) # simple write latency
	bluestore_deferred_writes_lat=$(jq ".bluestore.bluestore_deferred_writes_lat.avgtime" $dump_state) # deferred write latency
	bluestore_kv_queue_time=$(jq ".bluestore.bluestore_kv_queue_time.avgtime" $dump_state)
	bluestore_kv_sync_lat=$(jq ".bluestore.kv_sync_lat.avgtime" $dump_state) # flush + commit
	bluestore_kvq_lat=$(jq ".bluestore.bluestore_kvq_lat.avgtime" $dump_state) # queueing lat + flush/commit
	bluestore_simple_service_lat=$(jq ".bluestore.bluestore_simple_service_lat.avgtime" $dump_state)
	bluestore_deferred_service_lat=$(jq ".bluestore.bluestore_deferred_service_lat.avgtime" $dump_state)
    bluestore_simple_aio_lat=$(jq ".bluestore.bluestore_simple_async_io_lat.avgtime" $dump_state)
	bluestore_deferred_aio_lat=$(jq ".bluestore.bluestore_deferred_async_io_lat.avgtime" $dump_state)

    printf '%s\n' $bs $fioruntime $qd $clt_bw $clt_lat $osd_op_w_lat $osd_op_queueing_time $osd_on_committed_lat $bluestore_writes_lat $bluestore_simple_writes_lat $bluestore_deferred_writes_lat $bluestore_kv_queue_time $bluestore_kv_sync_lat $bluestore_kvq_lat $bluestore_simple_service_lat $bluestore_deferred_service_lat $bluestore_simple_aio_lat $bluestore_deferred_aio_lat | paste -sd ',' >> ${DATA_FILE} 
}

printf '%s\n' "bs" "runtime" "qdepth" "bw_mbs" "lat_s" "osd_op_w_lat" "op_queue_lat" "osd_on_committed_lat" "bluestore_writes_lat" "bluestore_simple_writes_lat" "bluestore_deferred_writes_lat" "kv_queue_lat" "bluestore_kv_sync_lat" "bluestore_kvq_lat" "bluestore_simple_service_lat" "bluestore_deferred_service_lat" "bluestore_simple_aio_lat" "bluestore_deferred_aio_lat"|  paste -sd ',' > ${DATA_FILE} 
#for qd in {16..72..8}; do
#bs="$((2**i*4*1024))"
#iototal="$((2**i*4*1024*100000))"   #"$((2**i*40))m"

#------------- clear rocksdb debug files -------------#
#sudo rm /tmp/flush_job_timestamps.csv  /tmp/compact_job_timestamps.csv

#------------- start cluster -------------#
./start_ceph.sh "$codel" "$target_lat" "$interval" "$batch_size" "$drive" # this is normal Ceph cluster on HDD/SSD
#./start_ceph_ramdisk.sh # this is Ceph cluster on ramdisk
sudo bin/ceph osd pool create mybench 128 128
sudo bin/rbd create --size=40G mybench/image1
sudo bin/ceph daemon osd.0 config show | grep bluestore_rocksdb
sleep 5 # warmup

sudo rm -f fio_write_edited.fio
sudo rm -f fio_prefill_rbdimage_edited.fio
sudo cp fio_write.fio fio_write_edited.fio
sudo cp fio_prefill_rbdimage.fio fio_prefill_rbdimage_edited.fio

# change the fio parameters
sed -i "s/iodepth=.*/iodepth=${qd}/g" fio_write_edited.fio
if [ ! -z "$bssplit" ]; then
    sed -i "s/bs=.*/bs=${bs}/g" fio_write_edited.fio
    sed -i "s/bs=.*/bs=${bs}/g" fio_prefill_rbdimage_edited.fio
else
	sed -i "s/bs=.*/bssplit=${bssplit}/g" fio_write_edited.fio
	sed -i "s/bs=.*/bssplit=${bssplit}/g" fio_prefill_rbdimage_edited.fio
fi
sed -i "s/rw=.*/rw=${rw}/g" fio_write_edited.fio
sed -i "s/runtime=.*/runtime=${fioruntime}/g" fio_write_edited.fio

sed -i "s/rw=.*/rw=${rw}/g" fio_prefill_rbdimage_edited.fio
sed -i "s/iodepth=.*/iodepth=${qd}/g" fio_prefill_rbdimage_edited.fio
#------------- pre-fill -------------#    
# pre-fill the image(to eliminate the op_rw)
#echo pre-fill the image!
sudo LD_LIBRARY_PATH="$CEPH_HOME"/build/lib:$LD_LIBRARY_PATH "$FIO_HOME"/fio fio_prefill_rbdimage_edited.fio
#------------- clear debug files and reset counters -------------#
# reset the perf-counter
sudo bin/ceph daemon osd.0 perf reset osd >/dev/null 2>/dev/null
sudo echo 3 | sudo tee /proc/sys/vm/drop_caches && sudo sync
# reset admin socket of OSD and BlueStore
sudo bin/ceph daemon osd.0 reset kvq vector

#------------- benchmark -------------#
    echo benchmark starts!
echo $qd
    sudo LD_LIBRARY_PATH="$CEPH_HOME"/build/lib:$LD_LIBRARY_PATH "$FIO_HOME"/fio fio_write_edited.fio --output-format=json --output=dump-fio-bench-${qd}.json 

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
