#!/bin/bash

source server.env

if [ ! -d "$PROJECTROOT/texasskynet" ]; then
    cd $PROJECTROOT
    svn checkout http://svn.twotael.com/svn/texasskynet/
else
    cd $PROJECTROOT/texasskynet
	svn cleanup
	svn update --force
fi

if [ ! -d "$PROJECTROOT/$PROJECTDIR" ]; then
    echo "$PROJECTROOT/$PROJECTDIR not existence"
    exit -1
fi 
cd $PROJECTROOT/texasskynet/tools/gm

$PROJECTROOT/texasskynet/skynet/3rd/lua/lua wsclient.lua gatereload

$PROJECTROOT/texasskynet/skynet/3rd/lua/lua wsclient.lua matchreload

$PROJECTROOT/texasskynet/skynet/3rd/lua/lua wsclient.lua roomreload

$PROJECTROOT/texasskynet/skynet/3rd/lua/lua wsclient.lua rechargereload


echo "-------reload success---------"
