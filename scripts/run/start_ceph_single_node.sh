#!/bin/bash

pool=${EXPERIMENT_POOL_NAME:=mybench}
image=${EXPERIMENT_IMAGE_NAME:=image1}
image_size=${EXPERIMENT_IMAGE_SIZE:=40G}
pg_num=${EXPERIMENT_PG_NUM:=128}
pgp_num=${EXPERIMENT_PGP_NUM:=128}

# start single node ceph
sudo MON=1 OSD=1 MDS=0 ../src/vstart.sh -n -b --without-dashboard

# create the pool
sudo bin/ceph osd pool create "$pool" "$pg_num" "$pgp_num"
sudo bin/rbd create --size="$image_size" "$pool/$image"
sudo bin/ceph daemon osd.0 config show | grep bluestore_rocksdb
sleep 5 # warmup

