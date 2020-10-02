#!/bin/bash

export WORKING_DIR=$(pwd)
export MAIN_DIR=$(eval echo "~")
export CEPH_HOME="$MAIN_DIR/ceph"
export FIO_HOME="$MAIN_DIR/fio"

function set_conf() {
	target_lat_param=$1
	interval_param=$2
	adaptive_param=$3
	cd "$MAIN_DIR"
	rm -f ceph/src/os/bluestore/BlueStore.cc
	cp BlueStore.cc ceph/src/os/bluestore/BlueStore.cc
	path="ceph/src/os/bluestore/BlueStore.cc"
	echo "Set parameters in BlueStore.cc"
	sed -i "s|<<target_latency>>|$target_lat_param|g" "$path"
	sed -i "s|<<interval>>|$interval_param|g" "$path"
	sed -i "s|<<adaptive>>|$adaptive_param|g" "$path"
}

function compile() {
	# install ceph
	cd "${CEPH_HOME}"
	cd build
	make -j`nproc`
	../src/stop.sh && rm -rf out dev && MON=1 OSD=1 MGR=1 MDS=0 RGW=0 ../src/vstart.sh -n -x
	./bin/ceph osd pool create rados

	# install fio
	cd "${FIO_HOME}"
	LDFLAGS=-I"$CEPH_HOME"/src/include LIBRARY_PATH="$CEPH_HOME"/build/lib:$LIBRARY_PATH ./configure
	EXTFLAGS=-I"$CEPH_HOME"/src/include LIBRARY_PATH="$CEPH_HOME"/build/lib:$LIBRARY_PATH make -j `nproc`

	# set git
	git config --global user.name "esmaeil-mirvakili"
	git config --global user.email "smirvaki@ucsc.edu"
}

function run_experiment() {
	cd "$WORKING_DIR"
	# run rbd bench and collect result
	bs="4096"   #"131072"  # block size 
	rw="randwrite"  # io type
	fioruntime=300  # seconds
	iototal="400m" # total bytes of io
	#qd=48 # workload queue depth

	# no need to change
	DATA_FILE=dump-lat-analysis.csv  # output file name
	pool="mybench"
	dn=${rw}-${bs}-$(date +"%Y_%m_%d_%I_%M_%p")
	sudo mkdir -p ${dn} # create data if not created

	printf '%s\n' "bs" "runtime" "qdepth" "bw_mbs" "lat_s" "osd_op_w_lat" "op_queue_lat" "osd_on_committed_lat" "bluestore_writes_lat" "bluestore_simple_writes_lat" "bluestore_deferred_writes_lat" "kv_queue_lat" "bluestore_kv_sync_lat" "bluestore_kvq_lat" "bluestore_simple_service_lat" "bluestore_deferred_service_lat" "bluestore_simple_aio_lat" "bluestore_deferred_aio_lat"|  paste -sd ',' > ${DATA_FILE} 
	#for qd in {16..72..8}; do
	for qd in $1; do
		#bs="$((2**i*4*1024))"
		#iototal="$((2**i*4*1024*100000))"   #"$((2**i*40))m"
		
		#------------- clear rocksdb debug files -------------#
		#sudo rm /tmp/flush_job_timestamps.csv  /tmp/compact_job_timestamps.csv
		
		#------------- start cluster -------------#
		cd "${CEPH_HOME}"
		cd build
		sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -o 'bluestore block = /dev/sdc' -o 'bluestore block path = /dev/sdc' -o 'bluestore fsck on mkfs = false' -o 'bluestore fsck on mount = false' -o 'bluestore fsck on umount = false' -o 'bluestore block db path = ' -o 'bluestore block wal path = ' -o 'bluestore block wal create = false' -o 'bluestore block db create = false' --without-dashboard
		#./start_ceph_ramdisk.sh # this is Ceph cluster on ramdisk
		sudo bin/ceph osd pool create mybench 128 128
		sudo bin/rbd create --size=40G mybench/image1
		sudo bin/ceph daemon osd.0 config show | grep bluestore_rocksdb
		sleep 5 # warmup

		# change the fio parameters
		cd "$WORKING_DIR"
		sed -i "s/iodepth=.*/iodepth=${qd}/g" fio_write.fio
		sed -i "s/bs=.*/bs=${bs}/g" fio_write.fio
		sed -i "s/rw=.*/rw=${rw}/g" fio_write.fio
		sed -i "s/runtime=.*/runtime=${fioruntime}/g" fio_write.fio
		#sed -i "s/size=.*/size=${iototal}/g" fio_write.fio
	    
		#------------- pre-fill -------------#    
		# pre-fill the image(to eliminate the op_rw)
		#echo pre-fill the image!
		sudo LD_LIBRARY_PATH="$CEPH_HOME"/build/lib:$LD_LIBRARY_PATH "$FIO_HOME"/fio fio_prefill_rbdimage.fio
		# reset the perf-counter
		cd "${CEPH_HOME}"
		cd build
		sudo bin/ceph daemon osd.0 perf reset osd >/dev/null 2>/dev/null
		sudo echo 3 | sudo tee /proc/sys/vm/drop_caches && sudo sync
		# reset admin socket of OSD and BlueStore
		sudo bin/ceph daemon osd.0 reset kvq vector

		#------------- benchmark -------------#
	    echo benchmark starts!
		echo $qd
		cd "$WORKING_DIR"
	    sudo LD_LIBRARY_PATH="$CEPH_HOME"/build/lib:$LD_LIBRARY_PATH "$FIO_HOME"/fio fio_write.fio --output-format=json --output=dump-fio-bench-${qd}.json 
		
		# dump internal data with admin socket
		# BlueStore
		cd "${CEPH_HOME}"
		cd build
		sudo bin/ceph daemon osd.0 dump kvq vector
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
	done
}

function prec() {
	cd "$WORKING_DIR"
	set -eu -o pipefail

	if [[ "$EUID" -ne 0 ]]; then
	  echo "This script must be run as root!"
	  exit 1
	fi

	device="/dev/sdc"
	if [[ ! -b "$device" ]]; then
	  echo "$device is not a block device"
	  exit 2
	fi

	total_sectors="$(blockdev --getsz "$device")"
	echo "Trimming a total $total_sectors 512-byte sectors on device $device..."

	SECTOR_COUNT=65535

	remain_sectors="$total_sectors"
	pos=0

	echo -en "\033[0;31m Progress 0% ([$pos/$total_sectors])\033[0m"

	while [[ "$remain_sectors" -gt 0 ]]; do
	  if [ "$remain_sectors" -gt "$SECTOR_COUNT" ]; then
	    sectors="$SECTOR_COUNT"
	  else
	    sectors="$remain_sectors"
	  fi

	  hdparm --please-destroy-my-drive --trim-sector-ranges "$pos":"$sectors" "$device" > /dev/null

	  remain_sectors=$((remain_sectors - sectors))
	  pos=$((pos + sectors))

	  percentage=$((pos * 100 / total_sectors))
	  echo -en "\e[0K\r\033[0;31m Progress $percentage% ([$pos/$total_sectors])\033[0m"
	done

	printf "Done!\n"
	sudo LD_LIBRARY_PATH="$CEPH_HOME"/build/lib:$LD_LIBRARY_PATH "$FIO_HOME"/fio prec.fio
}


sudo apt --assume-yes update
sudo apt-get --assume-yes install python3-routes

target_lat_configs=(500 600 700 800 900 1000 1100)
interval_configs=(250 500 750 1000 1500 2000 3000 4000)
adaptive_configs=(true)
io_depth_configs=(4 8 32 48 64 128)
exp_index=1

if [ ! -d "$CEPH_HOME" ]; then
    echo "Cloning ceph"
    cd "$MAIN_DIR"
    git clone https://github.com/esmaeil-mirvakili/ceph.git
	cd "$CEPH_HOME"	
	git checkout dev-CoDel
	cp "src/os/bluestore/BlueStore.cc" "$MAIN_DIR/BlueStore.cc"
	./install-deps.sh
	sudo apt update
	./do_cmake.sh -DWITH_MANPAGE=OFF -DWITH_BABELTRACE=OFF -DWITH_MGR_DASHBOARD_FRONTEND=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo
fi

cd "$MAIN_DIR"
if [ ! -d "$FIO_HOME" ]; then
    echo "Cloning ceph"
    cd "$MAIN_DIR"
    git clone https://github.com/axboe/fio.git
fi

prec

cd "$WORKING_DIR"
for io_depth in "${io_depth_configs[@]}"
do
	for target_lat in "${target_lat_configs[@]}"
	do
		for interval in "${interval_configs[@]}"
		do
			for adaptive in "${adaptive_configs[@]}"
			do
				echo
				echo "======================= Experiment #$exp_index ======================="
				echo "io_depth: $io_depth"
				echo "target_lat: $target_lat"
				echo "interval: $interval"
				echo "adaptive: $adaptive"
				echo
				let "exp_index++"

				
				set_conf "$target_lat" "$interval" "$adaptive"
				compile
				run_experiment "$io_depth"

				sleep 10
				echo "Moving results..."
				cd "$MAIN_DIR"
				if [ ! -d "results" ]; then
				    mkdir results
				fi
				cd "$CEPH_HOME/build"
				cp codel_log.csv "${MAIN_DIR}/results/codel_log_io_depth_${io_depth}_target_lat_${target_lat}_interval_${interval}_adaptive_${adaptive}.csv"
			done
		done
	done
done