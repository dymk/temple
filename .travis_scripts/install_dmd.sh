#!/bin/bash

wget http://downloads.dlang.org/releases/2013/dmd_2.064.2-0_amd64.deb
sudo apt-get install gcc-multilib
sudo dpkg -i dmd_2.064.2-0_amd64.deb
