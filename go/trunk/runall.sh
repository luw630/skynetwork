#!/bin/bash

source server.env


killall skynet

echo "run svrd start"
cd $PROJECTROOT/$PROJECTDIR/loginsvrd
skynet config_loginsvrd 

echo "run svrd end"

echo "-------run success---------"
