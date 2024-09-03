#!/bin/bash

#source `pwd`/conf ## for /bin/ksh
source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh

## Not related to pacemaker, but I need this 
installPrereq(){

	for HOST in $ALLHOST
	do
		disp_msglvl2 "Installing prereq for pacemaker on $HOST..."
		ssh $SSH_NO_BANNER $HOST yum -y install libstdc++ sg3_utils libstdc++.so.6 perl-Sys-Syslog patch binutils cpp gcc-c++ ksh python2 perl-Sys-Syslog perl dnf mksh   ## added mksh due to installation prereq check
		ssh $SSH_NO_BANNER $HOST dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm 
		ssh $SSH_NO_BANNER $HOST yum -y install python3-dnf-plugin-versionlock   ## necessary only on Linux

		ssh $SSH_NO_BANNER $HOST yum -y install compat-openssl10  # db2start: error while loading shared libraries: libcrypto.so.10
	done
}

installPrereq