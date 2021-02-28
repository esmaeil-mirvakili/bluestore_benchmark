#!/bin/bash
output_path=$1
codel_activated=0
drive="/dev/sdc"
io_depth_settings=(256)
rw_settings=(randwrite)
bs_settings=(4)  # KB
target_lats=(0)
intervals=(0)
path_del="/"
del="_"
prefix="${output_path}/results"
sudo rm -f codel_*
sudo rm -f dump-fio-bench-*
for io_depth in "${io_depth_settings[@]}"
do
        for rw in "${rw_settings[@]}"
        do
                for bs in "${bs_settings[@]}"
                do
                        for interval in "${intervals[@]}"
                        do
                                for target_lat in "${target_lats[@]}"
                                do
                                        bs_bytes=$(( bs*1024 ))
                                        target_lat_ns=$(( target_lat*1000000 ))
                                        interval_ns=$(( interval*1000000 ))
                                        init_batch_size=40960
                                        echo "$codel_activated"> codel.settings
                                        echo "$target_lat_ns">> codel.settings
                                        echo "$interval_ns">> codel.settings
                                        start_size=$(( bs_bytes*100 ))
                                        min_size=$(( bs_bytes*10 ))
                                        echo "$start_size">> codel.settings
                                        echo "$min_size">> codel.settings
                                        echo "50">> codel.settings
                                        sudo ./run-fio-queueing-delay.sh $io_depth $rw $bs_bytes $codel_activated $target_lat $interval $init_batch_size $drive
                                        path=$prefix$path_del$target_lat$del$interval$path_del$rw$path_del$bs
                                        echo $path
                                        sudo mkdir -p "$path"
                                        sudo mv codel_* $path
                                        name="fio_${target_lat}_${interval}.json"
                                        sudo mv dump-fio-bench-* $path$path_del$name
                                done
                        done
                done
        done
done

