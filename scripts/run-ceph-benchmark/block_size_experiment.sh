#!/bin/bash
output_path=$1
codel_activated=0
io_depth_settings=(16 48 128 512)
rw_settings=(randwrite)
bs_settings=(1 4 16 64 128 512 1024 4096)  # KB
declare -A target_lats=( [16]=0 [48]=0 [512]=0)
declare -A intervals=( [16]=0 [48]=0 [512]=0)
path_del="/"
prefix="${output_path}/results"
post_fix="_fio.json"

for io_depth in "${io_depth_settings[@]}"
do
	for rw in "${rw_settings[@]}"
	do
		for bs in "${bs_settings[@]}"
		do
			bs_bytes=$(( bs*1024 )) 
			target_lat=${target_lats[$io_depth]}
			interval=${intervals[$io_depth]}
			init_batch_size=${io_depth}
			sudo ./run-fio-queueing-delay.sh $io_depth $rw $bs_bytes $codel_activated $target_lat $interval $init_batch_size
			path=$prefix$path_del$io_depth$path_del$rw$path_del$bs
			echo $path
			sudo mkdir -p "$path"
			name=$(find . -type f -name "codel_log_batch*"  | cut -c3-)
			sudo mv codel_* $path
			sudo mv dump-fio-bench-* $path$path_del$name$post_fix
		done
	done
done