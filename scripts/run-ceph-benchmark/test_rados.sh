#!/bin/bash

# run rbd bench and collect result
bs="4096"   #"131072"  # block size 
totalruntime=10  # seconds
qd=48 # workload queue depth

# no need to change
DATA_FILE=dump-lat-analysis.csv  # output file name
pool="mybench"

single_dump() {
    qdepth=$1
    dump_state="dump-state-${qdepth}"
    sudo bin/ceph daemon osd.0 perf dump 2>/dev/null > $dump_state
	osd_op_in_osd_lat=$(jq ".osd.osd_op_in_osd_lat.avgtime" $dump_state)
	osd_op_queueing_time=$(jq ".osd.osd_op_queueing_time.avgtime" $dump_state)
	bluestore_simple_writes_lat=$(jq ".bluestore.bluestore_simple_writes_lat.avgtime" $dump_state) # simple write latency
	bluestore_deferred_writes_lat=$(jq ".bluestore.bluestore_deferred_writes_lat.avgtime" $dump_state) # deferred write latency
	bluestore_kv_queue_time=$(jq ".bluestore.bluestore_kv_queue_time.avgtime" $dump_state)
	bluestore_kv_sync_lat=$(jq ".bluestore.kv_sync_lat.avgtime" $dump_state) # flush + commit
	bluestore_kvq_lat=$(jq ".bluestore.bluestore_kvq_lat.avgtime" $dump_state) # queueing lat + flush/commit
	bluestore_simple_service_lat=$(jq ".bluestore.bluestore_aio_lat.avgtime" $dump_state)
	bluestore_deferred_service_lat=$(jq ".bluestore.bluestore_dio_lat.avgtime" $dump_state)
    
    printf '%s\n' $bs $totalruntime $qd $osd_op_in_osd_lat $osd_op_queueing_time $bluestore_simple_writes_lat $bluestore_deferred_writes_lat $bluestore_kv_queue_time $bluestore_kv_sync_lat $bluestore_kvq_lat $bluestore_simple_service_lat $bluestore_deferred_service_lat | paste -sd ',' >> ${DATA_FILE} 
}
printf '%s\n' "bs" "runtime" "qdepth" "osd_lat" "op_queue_lat" "bluestore_simple_writes_lat" "bluestore_deferred_writes_lat" "kv_queue_lat" "bluestore_kv_sync_lat" "bluestore_kvq_lat" "bluestore_simple_service_lat" "bluestore_deferred_service_lat" |  paste -sd ',' > ${DATA_FILE} 

	./start_ceph.sh
	sudo bin/ceph osd pool create mybench 128 128

	#sleep 5 # warmup
        
    echo benchmark starts!
	echo $qd 
	sudo bin/rados bench -p mybench -b ${bs} -t ${qd} ${totalruntime} write --no-cleanup | tee dump-rados-bench-${qd}
	#sleep 5

	sudo bin/ceph daemon osd.0 dump kvq vector
	mv ./kvq_lat_vec.csv ./dump_kvq_lat_vec-${qd}.csv
	mv ./kv_sync_lat_vec.csv ./dump_kv_sync_lat_vec-${qd}.csv
	mv ./txc_bytes_vec.csv ./dump_txc_bytes_vec-${qd}.csv
	mv ./bluestore_lat_vec.csv ./dump_bluestore_lat_vec-${qd}.csv
	mv ./bluestore_simple_writes_lat_vec.csv ./dump_bluestore_simple_writes_lat_vec-${qd}.csv
	mv ./bluestore_deferred_writes_lat_vec.csv ./dump_bluestore_deferred_writes_lat_vec-${qd}.csv
	mv ./bluestore_simple_service_lat_vec.csv ./dump_bluestore_simple_service_lat_vec-${qd}.csv
	mv ./bluestore_deferred_service_lat_vec.csv ./dump_bluestore_deferred_service_lat_vec-${qd}.csv
	mv ./kv_queue_size_vec.csv ./dump_kv_queue_size_vec-${qd}.csv	

	sudo bin/ceph daemon osd.0 dump opq vector
	mv ./opq_vec.csv ./dump_opq_size_vec-${qd}.csv

	single_dump $qd
	#sudo bin/ceph daemon osd.0 perf dump > dump-state-${qd}
    echo benchmark stops!

    sudo bin/ceph osd pool delete $pool $pool --yes-i-really-really-mean-it
    sudo ../src/stop.sh

echo DONE!
#done
