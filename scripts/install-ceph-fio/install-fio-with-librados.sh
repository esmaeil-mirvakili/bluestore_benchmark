#!/bin/bash

sudo apt update
sudo apt-get -y install python3-routes
sudo apt-get -y install python3-pip

sudo apt-get install -y build-essential libssl-dev
cd /tmp
wget https://github.com/Kitware/CMake/releases/download/v3.20.0/cmake-3.20.0.tar.gz
tar -zxvf cmake-3.20.0.tar.gz
cd cmake-3.20.0
./bootstrap
make
sudo make install
sudo apt-get install -y ninja-build

# install ceph
cd ~
git clone https://github.com/esmaeil-mirvakili/ceph.git
cd ceph	
git checkout bluestore-codel
export CEPH_HOME="$(pwd)"
./install-deps.sh
./do_cmake.sh -DWITH_MANPAGE=OFF -DWITH_BABELTRACE=OFF -DWITH_MGR_DASHBOARD_FRONTEND=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build

# install package "python3-routes" to get rid of the "No module named routes" error
#sudo apt-get install python3-routes
cd build
../src/stop.sh && rm -rf out dev && MON=1 OSD=1 MGR=1 MDS=0 RGW=0 ../src/vstart.sh -n -x
./bin/ceph osd pool create rados

# install fio
cd ~
git clone https://github.com/axboe/fio.git
cd fio
export FIO_HOME="$(pwd)"
LDFLAGS=-I"$CEPH_HOME"/src/include LIBRARY_PATH="$CEPH_HOME"/build/lib:$LIBRARY_PATH ./configure
EXTFLAGS=-I"$CEPH_HOME"/src/include LIBRARY_PATH="$CEPH_HOME"/build/lib:$LIBRARY_PATH make -j `nproc`

cd "$CEPH_HOME"/build
LD_LIBRARY_PATH="$CEPH_HOME"/build/lib:$LD_LIBRARY_PATH "$FIO_HOME"/fio "$FIO_HOME"/examples/rados.fio

# install useful packages
sudo apt install -y cscope
sudo pip3 install -U pyyaml