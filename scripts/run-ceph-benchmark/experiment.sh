#!/bin/bash
output_path=$1
io_depth_settings=(16 32 48)
rw_settings=(randwrite randread randrw)
bs_settings=(1024 4096 102400)
path_del="/"
prefix="${output_path}/results"
post_fix="_fio.json"
for io_depth in "${io_depth_settings[@]}"
do
	for rw in "${rw_settings[@]}"
	do
		for bs in "${bs_settings[@]}"
		do
			sudo ./run-fio-queueing-delay.sh $io_depth $rw $bs
			path=$prefix$path_del$io_depth$path_del$rw$path_del$bs
			echo $path
			sudo mkdir -p "$path"
			name=$(find . -type f -name "codel_*"  | cut -c3-)
			sudo mv codel_* $path
			sudo mv dump-fio-bench-* $path$path_del$name$post_fix
		done
	done
done