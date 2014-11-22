#!/bin/bash

set -e

sudo add-apt-repository --yes ppa:ubuntu-toolchain-r/test
sudo apt-get update
sudo apt-get install g++-4.9
sudo apt-get install libstdc++6

wget --no-check-certificate https://github.com/ldc-developers/ldc/releases/download/v0.15.0-alpha1/ldc2-0.15.0-alpha1-linux-x86_64.tar.gz
tar -xzf ldc2-0.15.0-alpha1-linux-x86_64.tar.gz
sudo ln -s `pwd`/ldc2-0.15.0-alpha1-linux-x86_64/bin/ldmd2 /usr/bin/ldmd2
