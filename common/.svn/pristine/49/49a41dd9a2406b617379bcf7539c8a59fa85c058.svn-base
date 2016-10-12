#!/bin/bash

#构建环境
SKYNETPATH="./skynet"
LBFPATH="./tools/lbf"
#更新或是部署skynet
echo "-----------------begin deploy or update skynet -----------------------"
if [ ! -d $SKYNETPATH ]; then
    git clone https://github.com/cloudwu/skynet.git

    chmod a+x ./skynetpatch/*.sh
    ./skynetpatch/dopatch.sh
    ./skynetpatch/domakefile.sh
else
    git fetch origin master
fi

cd $SKYNETPATH
make clean
make "linux"
cd ../

cd $LBFPATH
make install
source ~/.bashrc
cd ../ 
echo "-----------------end deploy or update skynet -------------------------"










