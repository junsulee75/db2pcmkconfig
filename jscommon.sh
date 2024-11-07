#!/bin/bash
##########################################
 # program name : jscommon.sh
 # Copyright ? 2021 Jun Su Lee. All rights reserved.
 # Author : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : Common usage for all kind of shell scripts
 #               For this, I prefer not to put dependencies with other scripts.  
 #
 # Category : DB2 support
 # Usage
 # Date : Apr.09, 2021
 #
 # Revision History
 # - Nov. 30, 2018 : 
##########################################

# To avoid login message
SSH_NO_BANNER="-q -o LogLevel=QUIET -o StrictHostKeyChecking=no"  # example full ssh command : ssh -q -o LogLevel=QUIET hostname command  

#################################################
# Package manager command to use.  yum or apt 
#################################################
pkgmgr="yum"  # Linus package manager command. set this as yum as it's more popular  
version_id=""
if [[ -f /etc/os-release ]]; then   ## make sure to run with bash. Otherwise, will get error.   
    os=$(grep '^ID=' /etc/os-release | awk -F= '{print $2}' | tr -d '"')    # remove the quote " if there is
    version_id=$(grep '^VERSION_ID=' /etc/os-release | awk -F= '{print $2}' | tr -d '"')    # remove the quote " if there is
    
    if [[ "$os" == "rhel" || "$os" == "fedora" || "$os" == "centos" ]]; then
        pkgmgr="yum"
    elif [[ "$os" == "ubuntu" || "$os" == "debian" ]]; then
        pkgmgr="apt"
    else
        echo "Unsupported OS : $os    . Exiting !!"
        exit 1
    fi
else 
    echo "Cannot find /etc/os-release file. Is this Linux OS ? Check again. Exiting now !!"
    exit 1
fi


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
        export PRODUCT_LOGFILE=/tmp/kube_install.log.$$
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

print2(){
	disp_msglvl2 "$1"
}

disp_msglvl1(){
	echo
	echo
	echo "###########################################################################################"
	echo $1
	echo "###########################################################################################"
	echo
}

print1(){
	disp_msglvl1 "$1"
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
    	[ $? -ne 0 ] && $pkgmgr install $i -y
    done
}


# Install python3 package and necessary libraries  
pyChk(){
    which python3
    if [ $? -ne 0 ] ; then
        disp_msglvl2 "installaing python3"   
    	$pkgmgr install python3 -y
    fi
    which pip3  # On Redhat 8.10, had to install this again. Python3 install didn add this somehow.  
    if [ $? -ne 0 ] ; then
        disp_msglvl2 "installing pip3"
        # From the previous logic, this is set when OS is ubuntu
        # To install pip3, there are some other steps in ubuntu
        if [[ "$pkgmgr" == "apt" ]]; then
            sudo add-apt-repository universe -y
            sudo $pkgmgr update -y
            
            # To prevent pop up message asking to restart outdated service package.     
            # For this, needrestart package is necessary.  If the conf file does not exist, install the package
            if [ ! -f "/etc/needrestart/needrestart.conf" ]; then
                echo "/etc/needrestart/needrestart.conf does not exist. Installing needstart package"
                sudo $pkgmgr install needrestart -y
            fi                

            # change i (interactive) to a (automatically) 
            sudo sed -i 's/$nrconf{restart} = '\''i'\'';/$nrconf{restart} = '\''a'\'';/' /etc/needrestart/needrestart.conf
            # Then uncomment
            sudo sed -i 's/^\#$nrconf{restart}/$nrconf{restart}/' /etc/needrestart/needrestart.conf

            # Ubuntu 22.04 : working fine. 
            # Ubuntu 24.04 . on some systems, gets error: E: Package 'python3-pip' has no installation candidate.
            #                Didn't have the issue on fresh install ubuntu 24.04. But on some cloud provisioned system, this happens. 
            #              If error happens, will try to get around with other way once.  
            #              However, it may be fine as we can still use 'apt install' to install xml library in 24.04. Therefore, ignore the error for now. JSTODO   
            sudo $pkgmgr install python3-pip -y
            if [ $? -ne 0 ] ; then
                print2 "pip3 installation failure on $version_id . Trying other way soon. "  
                curl -sS https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
                sudo python3 /tmp/get-pip.py --break-system-packages
            fi    
            
        else  ## non ubuntu, mostly Redhat
            $pkgmgr install python3-pip -y  
        fi
    fi
    disp_msglvl2 "Python necessary library installation"    
    # need to install library even if there is existing python3  
    
    if [[ "$pkgmgr" == "apt" ]]; then
        # Ubuntu 24.04 : pip3 install -U pyyaml => Error: externally-managed-environment
        # Since Ubuntu 24.04, PEP 668 specification prevents system-wide Python environments from being modified directly via pip  
        # Therefore, I think there are two options.  
        # sudo apt install python3-yaml -y 
        # or 
        # sudo pip3 install -U pyyaml --break-system-packages
        case "$version_id" in
            "24.04"|"Some future version to add")
                sudo apt install python3-yaml -y       
                ;;
            "22.04")
                pip3 install -U pyyaml
                ;;
            *)
                sudo apt install python3-yaml -y # If unknown version, just try new way.   
                ;;

        esac
    else   
        pip3 install -U pyyaml
    fi
    
    # JSTODO : 

    # Let's do test   
    # JSTODO : 
    # Also for Ubuntu, consider the case sudo may need password.    
}


goChk(){
    which go && go version
    if [ $? -ne 0 ] ; then

        GOVER="1.23.2"
        disp_msglvl2 "installaing golang version $GOVER"
        wget -P /root https://go.dev/dl/go${GOVER}.linux-amd64.tar.gz
        rm -rf /usr/local/go && tar -C /usr/local -xzf /root/go${GOVER}.linux-amd64.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
        source ~/.bashrc
        go version
        which go

    fi
}    