#!/bin/bash

osd_begin_cmds=${OSD_BEGIN_COMMANDS:=()}
osd_end_cmds=${OSD_END_COMMANDS:=()}
prefill_fio_file=${FIO_PREFILL_FILE:=fio_prefill_rbdimage_edited.fio}
workload_fio_file=${FIO_WORKLOAD_FILE:=fio_workload.fio}

sudo LD_LIBRARY_PATH="$CEPH_HOME"/build/lib:$LD_LIBRARY_PATH "$FIO_HOME"/fio "$prefill_fio_file"
#------------- clear debug files and reset counters -------------#
# reset the perf-counter
sudo bin/ceph daemon osd.0 perf reset osd >/dev/null 2>/dev/null
sudo echo 3 | sudo tee /proc/sys/vm/drop_caches && sudo sync
# reset admin socket of OSD and BlueStore
if [ "$codel" = 1 ] ; then
  sudo bin/ceph daemon osd.0 enable codel
fi

# send the begin commands to osd
for cmd in "${osd_begin_cmds[@]}"
do
  sudo bin/ceph daemon osd.0 "$cmd"
done


#------------- benchmark -------------#
echo benchmark starts!
sudo LD_LIBRARY_PATH="$CEPH_HOME"/build/lib:$LD_LIBRARY_PATH "$FIO_HOME"/fio "$workload_fio_file" --output-format=json --output=dump-fio-bench.json


# send the end commands to osd
for cmd in "${osd_end_cmds[@]}"
do
  sudo bin/ceph daemon osd.0 "$cmd"
done