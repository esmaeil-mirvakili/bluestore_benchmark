#!/bin/bash
output_path=$1
codel_activated=0
drive="/dev/sdc"
io_depth_settings=(40960)
rw_settings=(randwrite)
bs_settings=(4)  # KB
target_lats=(0)
intervals=(0)
path_del="/"
del="_"
prefix="${output_path}/results"
post_fix="_fio.json"

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
                                        init_batch_size=40960
                                        sudo ./run-fio-queueing-delay.sh $io_depth $rw $bs_bytes $codel_activated $target_lat $interval $init_batch_size $drive
                                        path=$prefix$path_del$interval$del$target_lat$path_del$rw$path_del$bs
                                        echo $path
                                        sudo mkdir -p "$path"
                                        name=$(find . -type f -name "codel_log*"  | cut -c3-)
                                        sudo mv codel_* $path
                                        sudo mv dump-fio-bench-* $path$path_del$name$post_fix
                                done
                        done
                done
        done
done
