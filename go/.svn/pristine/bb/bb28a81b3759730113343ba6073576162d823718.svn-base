#!/bin/bash

source server.env

if [ ! -d "$PROJECTROOT" ]; then
    cd $PROJECTROOT
    svn checkout http://svn.twotael.com/svn/framework
else
    cd $PROJECTROOT
	svn cleanup
	svn update --force
fi

if [ ! -d "$PROJECTROOT/$PROJECTDIR" ]; then
    echo "$PROJECTROOT/$PROJECTDIR not existence"
    exit -1
fi 

killall skynet

echo "run svrd start"
cd $PROJECTROOT/$PROJECTDIR/logindbsvrd
$PROJECTROOT/$PROJECTSKYNET config_logindbsvrd &

cd $PROJECTROOT/$PROJECTDIR/datadbsvrd
$PROJECTROOT/$PROJECTSKYNET config_datadbsvrd &

cd $PROJECTROOT/$PROJECTDIR/loginsvrd
$PROJECTROOT/$PROJECTSKYNET config_loginsvrd &

cd $PROJECTROOT/$PROJECTDIR/tablestatesvrd
$PROJECTROOT/$PROJECTSKYNET config_tablestatesvrd &

cd $PROJECTROOT/$PROJECTDIR/roomsvrd
$PROJECTROOT/$PROJECTSKYNET config_roomsvrd &

cd $PROJECTROOT/$PROJECTDIR/gatesvrd
$PROJECTROOT/$PROJECTSKYNET config_gatesvrd &
echo "run svrd end"

echo "-------run success---------"
