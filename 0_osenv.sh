#!/bin/bash

#source `pwd`/conf ## for /bin/ksh
source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh

# For all hosts, check if the command exist. If not. install.   
swCmdChkAllHost(){

    for SWNAME in "$@"
        do
	    for HOST in $ALLHOST
	        do
    		disp_msglvl2 "Installing $SWNAME on $HOST..."
    		ssh $SSH_NO_BANNER root@$HOST which $SWNAME > /dev/null 
            if [ $? -ne 0 ]; then
                ssh $SSH_NO_BANNER $HOST yum -y install $SWNAME
            else
                echo "$SWNAME is already installed on $HOST"
            fi
    	done
    done
}

setProfile(){
	disp_msglvl2 "setting set -o vi"
	echo "set -o vi" >> /etc/bashrc

	for HOST in $ALLHOST
	do
		echo "copying to $HOST"
		scp /etc/bashrc root@$HOST:/etc
	done
}

#installXterm
swCmdChkAllHost "xterm"
setProfile
pyChk ## install python on the 1st host only. To run setup script, python is needed.   

disp_msglvl1 "Copying frequently used commands to /usr/local/bin"   
for f in menu.py 
do
	rm -f /usr/local/bin/$f
    disp_msglvl2 "Copying `pwd`/$f"
    cp `pwd`/$f /usr/local/bin
    which $f
done