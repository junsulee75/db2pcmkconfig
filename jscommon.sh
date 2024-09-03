#!/bin/bash
##########################################
 # program name : jscommon.sh
 # Copyright ? 2021 Jun Su Lee. All rights reserved.
 # Author : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : Common usage for all kind of shell scripts
 #
 # Category : DB2 support
 # Usage
 # Date : Apr.09, 2021
 #
 # Revision History
 # - Nov. 30, 2018 : 
##########################################

SSH_NO_BANNER="-q -o LogLevel=QUIET -o StrictHostKeyChecking=no"  # example full ssh command : ssh -q -o LogLevel=QUIET hostname command  


# Command return value check and exit 1 if non zero
cmdRetChk(){
	if [ $? -ne 0 ]; then
		echo "failure. Exit.."
        exit 1 
	else
	    echo "success !!! "
	fi
}

timestamp()
{
    date +'%Y-%m-%d %H:%M:%S.%3N'
}


stop_immediately () {
    [[ -z "$1" ]] || logger_error "REASON: $1"
    exit 1
}


logger ()
{
    if [ -z "$PRODUCT_LOGFILE" ]; then
        export PRODUCT_LOGFILE=db2ps_install.log.$$
    fi
    # Print caller's source file, line number and function name
    # Skip two functions that are usually top of the stack
    # i.e. logger_xxxx and logger
    echo "[$(timestamp)] - $(basename ${BASH_SOURCE[2]}):${BASH_LINENO[1]}(${FUNCNAME[2]}) - $*" >> $PRODUCT_LOGFILE
    return 0
}

logger_error ()
{
    local LEVEL="ERROR"
    if [ -n "$1" ]; then
        logger " $LEVEL: $1"
        echo " $LEVEL: $1"
    else
        while read IN
        do
            logger "$LEVEL: $IN"
            echo "$LEVEL: $IN"
        done
    fi
    return 0
}

disp_msglvl2(){
	echo
	echo "**********************************************"
	echo $1
	echo "**********************************************"
    echo
}

disp_msglvl1(){
	echo
	echo
	echo "###########################################################################################"
	echo $1
	echo "###########################################################################################"
	echo
}


# install software if the command does not exist. This is only for the current host.   
# For multiple hosts, I don't put a common function here yet as it's more complex.   
# call this function like this listing up package name split by a space 
# ex) swChk podman jq vim tmux skopeo
## jq : JSON command line
## 

swCmdChk(){

    disp_msglvl1 "Software check and install if not exist"
    for i in "$@"
    do
        disp_msglvl2 "Checking $i"
    	which $i
    	[ $? -ne 0 ] && yum install $i -y
    done
}

pyChk(){
    which python3
    if [ $? -ne 0 ] ; then
        disp_msglvl2 "installaing python3"   
    	yum install python3 -y
    fi
    disp_msglvl2 "Python necessary library installation"    
    # need to install library even if there is existing python3   
    pip3 install -U pyyaml
}    