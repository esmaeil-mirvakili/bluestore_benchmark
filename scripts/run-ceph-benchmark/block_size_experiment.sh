#!/bin/bash
output_path=$1
codel_activated=0
drive="/dev/sdc"
io_depth_settings=(40960)
throttle_settings=(256 1024 1792 2560 3328 4096 4864 5632 6400 7168 7936 8704 9472 10240 11008 11776 12544 13312 14080 14848 15616 16384 17152 17920 18688 19456 20224 20992 21760 22528 23296 24064 24$
# throttle_settings=(512 1280 2048 2816 3584 4352 5120 5888 6656 7424 8192 8960 9728 10496 11264 12032 12800 13568 14336 15104 15872 16640 17408 18176 18944 19712 20480 21248 22016 22784 23552 24320 25$
# throttle_settings=(768 1536 2304 3072 3840 4608 5376 6144 6912 7680 8448 9216 9984 10752 11520 12288 13056 13824 14592 15360 16128 16896 17664 18432 19200 19968 20736 21504 22272 23040 23808 24576 2534$
rw_settings=(randwrite)
bs_settings=(4)  # KB
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
                        for th in "${throttle_settings[@]}"
                        do
                                echo $th> codel.settings
                                bs_bytes=$(( bs*1024 )) 
                                target_lat=${target_lats[$io_depth]}
                                interval=${intervals[$io_depth]}
                                init_batch_size=${io_depth}
                                sudo ./run-fio-queueing-delay.sh $io_depth $rw $bs_bytes $codel_activated $target_lat $interval $init_batch_size $drive
                                path=$prefix$path_del$th$path_del$rw$path_del$bs
                                echo $path
                                sudo mkdir -p "$path"
                                name=$(find . -type f -name "codel_log_batch*"  | cut -c3-)
                                sudo mv codel_* $path
                                sudo mv dump-fio-bench-* $path$path_del$name$post_fix
                        done
                done
        done
done
