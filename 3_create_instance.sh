#!/bin/bash

#source `pwd`/conf ## for /bin/ksh
source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh

## Not related to pacemaker, but I need this 
createUser(){

	for HOST in $db2hosts
	do
		disp_msglvl2 "create user on $HOST..."
		ssh $SSH_NO_BANNER $HOST groupadd  db2iadm1
		ssh $SSH_NO_BANNER $HOST groupadd  db2fadm1

		#ssh $HOST "useradd -u 1002 -g db2iadm1 -m -d /home/db2inst1 $INST_USER"
		#ssh $HOST "useradd -u 1003 -g db2fadm1 -m -d /home/db2fenc1 db2fenc1"

		ssh $SSH_NO_BANNER $HOST "useradd -g db2iadm1 -m -d /home/db2inst1 $INST_USER"  # let's not give id, sometimes failure with conflict   
		ssh $SSH_NO_BANNER $HOST "useradd -g db2fadm1 -m -d /home/db2fenc1 db2fenc1"  
		
		#ssh $HOST passwd $INST_USER
    	#ssh $HOST passwd db2fenc1

			
		echo " setting password with default password |$USERPW|. Change if you want later " 	
		ssh $SSH_NO_BANNER $HOST "echo "$INST_USER:$USERPW" |sudo chpasswd"  # let's set password without prompt   
		ssh $SSH_NO_BANNER $HOST "echo "db2fenc1:$USERPW" |sudo chpasswd"  # let's set password without prompt   

	done
}

sshkeyGen(){
	
	#sudo -u $INST_USER /bin/ssh-keygen -t rsa  # this needs user intervention. Thinking other way below.  

	for host in $db2hosts  ## only need to set pwless between db2 hosts
	do
	
		disp_msglvl2 "Generate SSH key for $INST_USER on $host"
		# example 
		# ssh jspmtest2 "sudo -u jslee /bin/ssh-keygen -t rsa -b 4096 -N \"\" -f ~jslee/.ssh/id_rsa"  ## should use -N "" to -N \"\" .Otherwise too many parameter error
		ssh $SSH_NO_BANNER $host "sudo -u $INST_USER /bin/ssh-keygen -t rsa -b 4096 -N \"\" -f ~$INST_USER/.ssh/id_rsa"  
		
		# also create authorized file with correct permission in advance so that next logic can add keys to this file without creating file by root
		ssh $SSH_NO_BANNER $host "sudo -u $INST_USER touch ~$INST_USER/.ssh/authorized_keys"
		ssh $SSH_NO_BANNER $host "sudo -u $INST_USER chmod 600 ~$INST_USER/.ssh/authorized_keys"

	done	

}

## JS TODO : for now, this is passwordless setting from the 1st host to the 2nd host.   
setPWLess(){
	#disp_msglvl1 "passwordless login setting for $INST_USER..."
	
	for fromhost in $db2hosts  ## only need to set pwless between db2 hosts
	do
		#disp_msglvl2 "passwordless login setting for $host...expect multiple times manual password input"
	    #sudo -u $INST_USER ssh $host 'mkdir -p .ssh'
		#old logic : success to copy the current host instance user file to remote host.   
   		#sudo -u $INST_USER cat /home/$INST_USER/.ssh/id_rsa.pub | sudo -u $INST_USER ssh $host 'cat >> .ssh/authorized_keys'
   		#sudo -u $INST_USER ssh $host date
	
		for tohost in $db2hosts 
		do 
			disp_msglvl2 "Copy root user id_rsa.pub from $fromhost into $INST_USER authorized_keys of $tohost"   
			ROOT_KEY2COPY=`ssh $SSH_NO_BANNER $fromhost cat /root/.ssh/id_rsa.pub`
			echo $ROOT_KEY2COPY   
			ssh $SSH_NO_BANNER $tohost "echo $ROOT_KEY2COPY >> ~$INST_USER/.ssh/authorized_keys" 
						

			disp_msglvl2 "Copy $INST_USER user id_rsa.pub from $fromhost into $INST_USER authorized_keys of $tohost"   
			INSTUSER_KEY2COPY=`ssh $SSH_NO_BANNER $fromhost cat ~$INST_USER/.ssh/id_rsa.pub`
			echo $INSTUSER_KEY2COPY 
			ssh $SSH_NO_BANNER $tohost "echo $INSTUSER_KEY2COPY >> ~$INST_USER/.ssh/authorized_keys" 
			#echo $INSTUSER_KEY2COPY | ssh $SSH_NO_BANNER $tohost 'cat >> /root/db2inst1_authorized_keys'  #for test  
			
		done		
		

	done
}

testPWLess(){


	## It's enough to test from the current host to current host/remote host. 
	## Then we can run remote command to root and db2inst1 user without prompt. Mainly run the commands from the current 1st host.   
	for host in $db2hosts     
	do
		disp_msglvl2 "Passwordless ssh test into $INST_USER of $host"   
		ssh $SSH_NO_BANNER $INST_USER@$host "hostname;id;date"	
	done	
}

createInstance(){

	for HOST in $db2hosts
	do
		disp_msglvl2 "create instance on $HOST..."
		ssh $SSH_NO_BANNER  $HOST "$DB2_INSTALL_PATH/instance/db2icrt -u db2fenc1 $INST_USER"
	done
}

createUser
sshkeyGen
setPWLess
testPWLess
createInstance