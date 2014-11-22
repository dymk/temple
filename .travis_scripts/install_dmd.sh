#!/bin/bash

set -e

wget http://downloads.dlang.org/releases/2014/dmd_2.066.1-0_amd64.deb
sudo apt-get install gcc-multilib
sudo dpkg -i dmd_2.066.1-0_amd64.deb
