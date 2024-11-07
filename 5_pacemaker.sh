#!/bin/bash

#source `pwd`/conf ## for /bin/ksh
source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh


USER_HOME=$(eval echo ~$INST_USER)
echo "Home directory of $INST_USER : |$USER_HOME|"

chkDb2cm(){

	if [ ! -f $USER_HOME/sqllib/bin/db2cm ] ; then
		disp_msglvl2 "Error, the file $USER_HOME/sqllib/bin/db2cm does not exist..... Ensure pacemaker installation has done correctly.  "
		exit 1
	fi
	disp_msglvl2 "The file $USER_HOME/sqllib/bin/db2cm exists. So we continue... "
}

createDomain(){

    disp_msglvl1 "creating new domain..."
	echo "After creation, NIC resource may show Stopped status. It's expected. It will be started after creating instance resource later on"
	$USER_HOME/sqllib/bin/db2cm -cluster -create -domain db2domain -host $PRIMARY_HOST -publicEthernet eth0 -host $STANDBY_HOST -publicEthernet eth0 -remote_cmd "ssh $SSH_NO_BANNER" 
	crm status
}
createInstanceResource(){

    disp_msglvl1 "creating instance resources..."
	$USER_HOME/sqllib/bin/db2cm -create -instance $INST_USER -host $PRIMARY_HOST -remote_cmd "ssh $SSH_NO_BANNER" 
	$USER_HOME/sqllib/bin/db2cm -create -instance $REMOTE_INST -host $STANDBY_HOST -remote_cmd "ssh $SSH_NO_BANNER" 
	crm status
}
createDBResource(){

    disp_msglvl1 "creating DB resource..."
	$USER_HOME/sqllib/bin/db2cm -create -db $DBNAME -instance $INST_USER -remote_cmd "ssh $SSH_NO_BANNER" 
	crm status
}
createVIP(){

	if [ "$VIP" = "123.123.123.123" ] || [ -z "$VIP" ] ; then   # not changed or not set

		# If fyre provisioned, I know what to do   
		hostname | grep fyre >/dev/null
		if [ $? -eq 0 ] ; then  # This is for IBM fyre provisioned system. It will grab "eth0" for internal ip address. From tests, no need to specify iface. flannel will use it automatically.   
			ipaddr=$(ip addr | grep "inet 10.*dynamic" | awk '{print $2}' | sed 's/\/.*//' )
			subnetMask=$(ip addr | grep "inet 10.*dynamic" | awk '{print $2}' | sed 's/.*\///' )
			print2 "GOLANG(freeip) : Running other program to find an available IP address under the same subnet of IP $ipaddr/$subnetMask"
			OUTPUT=$(./freeip/freeip_$(uname -p) "$ipaddr" "$subnetMask")
			if [ $? -eq 0 ]; then
				VIP="$OUTPUT"
				echo "OK. Found the available IP address $VIP . Will use it as VIP\n\n"
			else
				echo "Failed to find an available IP address for VIP. Find and try again manually later. SKipping VIP configuration...\n\n"
				return 1
			fi
		else
			echo "You haven't set the correct VIP in config.ini. Find and try again manually later. SKipping VIP configuration...\n\n" 
			return 1
		fi
	
	fi



    disp_msglvl1 "creating VIP resource..."
	$USER_HOME/sqllib/bin/db2cm -create -primaryVIP $VIP -db $DBNAME -instance $INST_USER -remote_cmd "ssh $SSH_NO_BANNER" 
	## TODO : fix error Error: the VIP address 10.11.71.150 is not within the same subnet as host with IP 10.11.100.236
	##        In this case, the IP 10.11.100.50 worked.   
	crm status
    disp_msglvl2 "IP information...check secondary VIP $VIP is added to the network resource" 
	ip addr
	
}
createQdevice(){

    disp_msglvl2 "creating Qdevice..."
	$USER_HOME/sqllib/bin/db2cm -create -qdevice $QUORUM_HOST -remote_cmd "ssh $SSH_NO_BANNER" 
	sleep 10
	/usr/sbin/corosync-qdevice-tool -s

    disp_msglvl2 "ssh $QUORUM_HOST corosync-qnetd-tool -l"
	ssh $SSH_NO_BANNER $QUORUM_HOST corosync-qnetd-tool -l
}
	

chkDb2cm
createDomain
createInstanceResource
createDBResource
createVIP
createQdevice