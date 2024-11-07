#!/bin/bash

#source `pwd`/conf ## for /bin/ksh
source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh


DB2VER_INPUT=$1  # Not mandatory. If there is the parameter.     
#DB2VER_TWO=${DBVER_INPUT:0:2}    # not working 
#echo "|$DB2VER_INPUT|   |$DB2VER_TWO|"
EXTRACT_PATH="server_dec"  # Db2 installation image extracted relative path  
PKG_NAME="server"  # Db2 package name to install. Different each version. Putting recent version here. Override if necessary.   

echo "Preparing to install DB2 version $DB2VER_INPUT...."   
# To override to a specific version
case "$1" in

	1157 )  DB2_IMAGE_FILE_NAME=$V1157_IMAGE;DB2_INSTALL_PATH=$V1157_INSTALL_PATH;DB2LICPATH=$DB2115LICPATH;DB2LIC=$DB2115LIC
	        ;;
	1158 )  DB2_IMAGE_FILE_NAME=$V1158_IMAGE;DB2_INSTALL_PATH=$V1158_INSTALL_PATH;DB2LICPATH=$DB2115LICPATH;DB2LIC=$DB2115LIC
	        ;;
	1159 )  DB2_IMAGE_FILE_NAME=$V1159_IMAGE;DB2_INSTALL_PATH=$V1159_INSTALL_PATH;DB2LICPATH=$DB2115LICPATH;DB2LIC=$DB2115LIC
	        ;;

    * ) 
		echo "No input parameter for specific version or no valid input. Installing a default version for Redhat OS"   
	;;

esac

##
copyImage(){

	disp_msglvl2 "Downloading DB2 installation image..."
	## download to /root directory   
	# old way using scp
	#scp root@$DB2_IMAGE_DOWNLOAD_SERVER:$DB2_IMAGE_PATH_ON_SERVER/$DB2_IMAGE_FILE_NAME /root
	# new way by curl ( I set web server for this. ) 
	echo "Downloading from http://$DB2_IMAGE_DOWNLOAD_SERVER/$DB2_IMAGE_PATH_ON_SERVER/$DB2_IMAGE_FILE_NAME"   
	curl http://$DB2_IMAGE_DOWNLOAD_SERVER/$DB2_IMAGE_PATH_ON_SERVER/$DB2_IMAGE_FILE_NAME -o /root/$DB2_IMAGE_FILE_NAME


	for HOST in $HOST_OTHER
	do
		disp_msglvl2 "Copy DB2 installation image to $HOST..."
		scp /root/$DB2_IMAGE_FILE_NAME  root@$HOST:/root
	done
}

extractImage(){

	for HOST in $ALLHOST
	do
	    ## Remove existing extracted paths   
		ssh $SSH_NO_BANNER $HOST "test -d \"/root/server_dec\""
		if [ $? -eq 0 ]; then
			disp_msglvl2 "There is existing image path /root/server_dec. Will remove it."
			ssh $SSH_NO_BANNER $HOST "rm -rf /root/server_dec"
		fi
		
		ssh $SSH_NO_BANNER $HOST "test -d \"/root/server\""
		if [ $? -eq 0 ]; then
			disp_msglvl2 "There is existing image path /root/server. Will remove it."
			ssh $SSH_NO_BANNER $HOST "rm -rf /root/server"
		fi

		ssh $SSH_NO_BANNER $HOST "test -d \"/root/server_t\""
		if [ $? -eq 0 ]; then
			disp_msglvl2 "There is existing image path /root/server_t. Will remove it."
			ssh $SSH_NO_BANNER $HOST "rm -rf /root/server_t"
		fi

		disp_msglvl2 "Extracting DB2 installation image on $HOST"
		ssh $SSH_NO_BANNER $HOST "tar xvfz /root/$DB2_IMAGE_FILE_NAME"
	done
}

## We install DB2 on all hosts.   
installDB2(){
	for HOST in $ALLHOST
	do
		TSA_LEVEL=`grep tsa_level /root/$EXTRACT_PATH/db2/spec`  # TSA version in the installation image

		# in pacemaker repo, most likely it won't take this logic, to share logic with tsa repo, let's keep it.   
		if [ "$DB2VER_INPUT" == "1157" ] || [ "$DB2VER_INPUT" == "1158" ] || [ "$DB2VER_INPUT" == "1159" ] ; then 
			echo "This is DB2 $DB2VER_INPUT installation"
			if [ "$VERSION_ID" == "8.8" ] ; then  
				echo "This is $ID $VERSION_ID . It's OK to install with TSA : $TSA_LEVEL "	 # This may not be necessary
				ssh $SSH_NO_BANNER $HOST "/root/$EXTRACT_PATH/db2_install -y -b $DB2_INSTALL_PATH -p $PKG_NAME -n"  # for single 
			else
				echo "Check the compatibility with DB2 $DB2VER_INPUT and $ID $VERSION_ID. Exiting ... "  
				exit 1
			fi
		else
			disp_msglvl2 "Installing DB2 on $HOST..."
			ssh $SSH_NO_BANNER $HOST "/root/$EXTRACT_PATH/db2_install -y -b $DB2_INSTALL_PATH -p $PKG_NAME -n"  # for single 
		fi
	done
}

chkDb2Install(){
	disp_msglvl1 "Check the installation"
	#for HOST in $pshost
	for HOST in $ALLHOST
	do
		disp_msglvl2 "Db2 Installation on $HOST..."
		ssh $SSH_NO_BANNER $HOST "db2ls -c"
	done
}

applyLic(){

	disp_msglvl1 "Downloading DB2 license ..."
	## download to /root directory
	# old way using scp
	#scp root@$DB2_IMAGE_DOWNLOAD_SERVER:$DB2_IMAGE_PATH_ON_SERVER/$DB2_IMAGE_FILE_NAME /root
	# new way by curl ( I set web server for this. )
	echo "curl http://$DB2_IMAGE_DOWNLOAD_SERVER/$DB2LICPATH/$DB2LIC -o /root/$DB2LIC"
	curl http://$DB2_IMAGE_DOWNLOAD_SERVER/$DB2LICPATH/$DB2LIC -o /root/$DB2LIC

	for HOST in $HOST_OTHER
	do
		disp_msglvl2 "Copy LIC to $HOST..."
		scp /root/$DB2LIC root@$HOST:/root
	done

	#for HOST in $pshost
	for HOST in $ALLHOST
	do
		disp_msglvl1 "Apply LIC on $HOST..."
		ssh $SSH_NO_BANNER $HOST "$DB2_INSTALL_PATH/adm/db2licm -a /root/$DB2LIC"
	done
}

chkPkg(){
	disp_msglvl1 "Checking installed packages by Db2 installation related to pacemaker... "
	for HOST in $ALLHOST
	do
		disp_msglvl2 "Installed pacemaker check on $HOST..."
		ssh $SSH_NO_BANNER $HOST "rpm -qa |grep -i pacemaker"
		disp_msglvl2 "Installed corosync check on $HOST..."
		ssh $SSH_NO_BANNER $HOST "rpm -qa |grep -i corosync"
		disp_msglvl2 "Installed crmsh check on $HOST..."
		ssh $SSH_NO_BANNER $HOST "rpm -qa |grep -i crmsh"
		disp_msglvl2 "Installed corosync-qdevice check on $HOST..."
		ssh $SSH_NO_BANNER $HOST "rpm -qa |grep -i corosync-qdevice"
		disp_msglvl2 "Installed corosync-qnetd check on $HOST..."
		ssh $SSH_NO_BANNER $HOST "rpm -qa |grep -i corosync-qnetd"
	done
}

copyImage
extractImage
installDB2
chkDb2Install
applyLic
chkPkg