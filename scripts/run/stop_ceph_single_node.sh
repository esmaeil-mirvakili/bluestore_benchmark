#!/bin/bash

pool=${EXPERIMENT_POOL_NAME:=mybench}
image=${EXPERIMENT_IMAGE_NAME:=image1}

sudo bin/rbd info "$pool/$image" | tee dump_rbd_info.txt
sudo bin/rbd rm "$pool/$image"
sudo bin/ceph osd pool delete "$pool" "$pool" --yes-i-really-really-mean-it
sudo ../src/stop.sh
