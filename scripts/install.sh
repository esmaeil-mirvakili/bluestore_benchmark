#!/bin/bash

branch="bluestore-bufferbloat-mitigation-dev"
git_url="https://github.com/esmaeil-mirvakili/ceph.git"

cd install-ceph-fio
sed -i "s/git clone .*/git clone ${git_url}/g" install-fio-with-librados.sh
sed -i "s/git checkout .*/git checkout ${branch}/g" install-fio-with-librados.sh

sudo ./install-fio-with-librados.sh

echo ""
echo "---------------------init-------------------------"
echo ""

cd ../run-ceph-benchmark
sudo cp * ~/ceph/build

cd ~/ceph/build
sudo ./run-fio-with-preconditioning.sh