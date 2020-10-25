#!/bin/bash
io_depth_settings=(16 32 48)
rw_settings=(randwrite randread randrw)
bs_settings=(1024 4096 102400)
for io_depth in "${io_depth_settings[@]}"
do
	for rw in "${rw_settings[@]}"
	do
		for bs in "${bs_settings[@]}"
		do
			sudo ./run-fio-queueing-delay.sh $io_depth $rw $bs
		done
	done
done