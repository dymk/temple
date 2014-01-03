#!/bin/bash

sudo apt-get install cmake llvm-3.2 libconfig++-dev
git clone https://github.com/ldc-developers/ldc.git ldc
cd ldc
git checkout a24b8b69
git submodule update --init
mkdir build && cd build
cmake ..
make -j2
sudo make install
cd ..
