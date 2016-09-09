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

killall skynet

echo "run svrd start"
cd $PROJECTROOT/$PROJECTDIR/loginsvrd
$PROJECTROOT/$PROJECTSKYNET config_loginsvrd &

cd $PROJECTROOT/$PROJECTDIR/gamesvrd
$PROJECTROOT/$PROJECTSKYNET config_gamesvrd &

cd $PROJECTROOT/$PROJECTDIR/robotsvrd
$PROJECTROOT/$PROJECTSKYNET config_robotsvrd &


cd $PROJECTROOT/$PROJECTDIR/gmsvrd
$PROJECTROOT/$PROJECTSKYNET config_gmsvrd &

cd $PROJECTROOT/$PROJECTDIR/httpsvrd
$PROJECTROOT/$PROJECTSKYNET config_httpsvrd &

cd $PROJECTROOT/$PROJECTDIR/msgsvrd
$PROJECTROOT/$PROJECTSKYNET config_msgsvrd &

cd $PROJECTROOT/$PROJECTDIR/rechargesvrd
$PROJECTROOT/$PROJECTSKYNET config_rechargesvrd &
echo "run svrd end"

echo "-------run success---------"
