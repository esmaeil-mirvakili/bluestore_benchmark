#!/bin/bash

export WORKING_DIR=$(pwd)
export MAIN_DIR="~"

function set_conf() {
	target_lat_param=$1
	interval_param=$2
	adaptive_param=$3
	path="ceph/src/os/bluestore/BlueStore.cc"
	echo "Set parameters in BlueStore.cc"
	sed -i "s|<<target_latency>>|$target_lat_param|g" "$path"
	sed -i "s|<<interval>>|$interval_param|g" "$path"
	sed -i "s|<<adaptive>>|$adaptive_param|g" "$path"
}

function compile() {
	# install ceph
	cd "${CEPH_HOME}"
	./install-deps.sh
	sudo apt update
	./do_cmake.sh -DWITH_MANPAGE=OFF -DWITH_BABELTRACE=OFF -DWITH_MGR_DASHBOARD_FRONTEND=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo
	cd build
	make -j`nproc`
	../src/stop.sh && rm -rf out dev && MON=1 OSD=1 MGR=1 MDS=0 RGW=0 ../src/vstart.sh -n -x
	./bin/ceph osd pool create rados

	# install fio
	cd "${FIO_HOME}"
	LDFLAGS=-I"$CEPH_HOME"/src/include LIBRARY_PATH="$CEPH_HOME"/build/lib:$LIBRARY_PATH ./configure
	EXTFLAGS=-I"$CEPH_HOME"/src/include LIBRARY_PATH="$CEPH_HOME"/build/lib:$LIBRARY_PATH make -j `nproc`

	cd "$CEPH_HOME"/build
	LD_LIBRARY_PATH="$CEPH_HOME"/build/lib:$LD_LIBRARY_PATH "$FIO_HOME"/fio "$FIO_HOME"/examples/rados.fio

	# set git
	git config --global user.name "esmaeil-mirvakili"
	git config --global user.email "smirvaki@ucsc.edu"
}

function run_experiment() {
	io_depth=$1
	cd "$WORKING_DIR"
	bash run-fio-with-preconditioning.sh "$io_depth"
}


sudo apt update
sudo apt-get install python3-routes

target_lat_configs=(500 600 700 800 900 1000 1100)
interval_configs=(250 500 750 1000 1500 2000 3000 4000)
adaptive_configs=(true)
io_depth_configs=(4 8 32 48 64 128)
exp_index=1

export CEPH_HOME="$MAIN_DIR/ceph"
if [ ! -d "$CEPH_HOME" ]; then
    echo "Cloning ceph"
    git clone https://github.com/esmaeil-mirvakili/benchmark.git
	cd ceph	
	git checkout dev-CoDel
fi

export FIO_HOME="$MAIN_DIR/fio"
if [ ! -d "$FIO_HOME" ]; then
	cd "$WORKING_DIR"
    echo "Cloning ceph"
    git clone https://github.com/axboe/fio.git
fi

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


				ech "Moving results..."
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