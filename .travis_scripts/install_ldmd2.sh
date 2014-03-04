#!/bin/bash

wget --no-check-certificate https://github.com/ldc-developers/ldc/releases/download/v0.13.0-alpha1/ldc2-0.13.0-alpha1-linux-x86_64.tar.gz
tar -xzf ldc2-0.13.0-alpha1-linux-x86_64.tar.gz
sudo ln -s `pwd`/ldc2-0.13.0-linux-x86_64/bin/ldmd2 /usr/bin/ldmd2
