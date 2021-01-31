#!/bin/bash
output_path=$1
codel_activated=0
drive="/dev/sdc"
io_depth_settings=(40960)
throttle_settings=(256 1024 1792 2560 3328 4096 4864 5632 6400 7168 7936 8704 9472 10240 11008 11776 12544 13312 14080 14848 15616 16384 17152 17920 18688 19456 20224 20992 21760 22528 23296 24064 24832 25600 26368 27136 27904 28672 29440 30208 30976 31744 32512 33280 34048 34816 35584 36352 37120 37888 38656 39424 40192 40960 41728 42496 43264 44032 44800 45568 46336 47104 47872 48640 49408 50176 50944 51712 52480 53248 54016 54784 55552 56320 57088 57856 58624 59392)
# throttle_settings=(512 1280 2048 2816 3584 4352 5120 5888 6656 7424 8192 8960 9728 10496 11264 12032 12800 13568 14336 15104 15872 16640 17408 18176 18944 19712 20480 21248 22016 22784 23552 24320 25088 25856 26624 27392 28160 28928 29696 30464 31232 32000 32768 33536 34304 35072 35840 36608 37376 38144 38912 39680 40448 41216 41984 42752 43520 44288 45056 45824 46592 47360 48128 48896 49664 50432 51200 51968 52736 53504 54272 55040 55808 56576 57344 58112 58880 59648)
# throttle_settings=(768 1536 2304 3072 3840 4608 5376 6144 6912 7680 8448 9216 9984 10752 11520 12288 13056 13824 14592 15360 16128 16896 17664 18432 19200 19968 20736 21504 22272 23040 23808 24576 25344 26112 26880 27648 28416 29184 29952 30720 31488 32256 33024 33792 34560 35328 36096 36864 37632 38400 39168 39936 40704 41472 42240 43008 43776 44544 45312 46080 46848 47616 48384 49152 49920 50688 51456 52224 52992 53760 54528 55296 56064 56832 57600 58368 59136 59904)
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
