#!/bin/bash
## It has all steps.
## Use this only for test purpose
## junsulee@au1.ibm.com
##

source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh


USER_HOME=$(eval echo ~$INST_USER)
echo "Home directory of $INST_USER : |$USER_HOME|"

USER_HOME2=$(ssh $SSH_NO_BANNER $STANDBY_HOST eval echo ~$REMOTE_INST)
echo "Home directory of $REMOTE_USER on $STANDBY_HOST : |$USER_HOME2|"
#Added logic in case remote instance user is different name or home directory is different.  

ACTIVE_LOG_PATH="$USER_HOME/active_log_path"
ARCHIVE_LOG_PATH="$USER_HOME/archive_log_path"

ACTIVE_LOG_PATH2="$USER_HOME2/active_log_path"
ARCHIVE_LOG_PATH2="$USER_HOME2/archive_log_path"

BACKUP_PATH="$USER_HOME/backup"
BACKUP_PATH2="$USER_HOME2/backup"

function confHadrPrimary {
        disp_msglvl1 "HADR primary configuration on $PRIMARY_HOST..."
        #echo "ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST db2set DB2COMM=TCPIP"
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST "db2set DB2COMM=TCPIP"
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST "db2 -v update dbm cfg using SVCENAME $PORT"
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST "db2stop force;db2start"

        disp_msglvl2 "Creating DB $DBNAME on $PRIMARY_HOST..."
        if [ $DBNAME  = "sample" ]; then
                ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST db2sampl
        else
                ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST "db2 -v create db $DBNAME"
        fi

        disp_msglvl2 "Create active log directory $ACTIVE_LOG_PATH" 
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST  mkdir -p $ACTIVE_LOG_PATH
        disp_msglvl2 "Create archive log directory $ARCHIVE_LOG_PATH" 
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST  mkdir -p $ARCHIVE_LOG_PATH

        disp_msglvl2 "DB configuration on $PRIMARY_HOST"    
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST "db2 -v update db cfg for $DBNAME using NEWLOGPATH $ACTIVE_LOG_PATH"
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST "db2 -v update db cfg for $DBNAME using LOGARCHMETH1 DISK:$ARCHIVE_LOG_PATH"
        #db2 restore db $DBNAME

        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST  "db2 -v update db cfg for $DBNAME using HADR_LOCAL_HOST $PRIMARY_HOST"
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST  "db2 -v update db cfg for $DBNAME using HADR_REMOTE_HOST $STANDBY_HOST"
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST  "db2 -v update db cfg for $DBNAME using HADR_LOCAL_SVC $HADR_PORT"
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST  "db2 -v update db cfg for $DBNAME using HADR_REMOTE_SVC $HADR_PORT"
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST  "db2 -v update db cfg for $DBNAME using HADR_REMOTE_INST $REMOTE_INST"
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST  "db2 -v update db cfg for $DBNAME using HADR_PEER_WINDOW 300"
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST  "db2 -v update db cfg for $DBNAME using  LOGINDEXBUILD ON"

        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST  "db2 -v backup db $DBNAME to /dev/null"
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST  "db2 -v activate db $DBNAME"

}

function bkupCopyRestore {
        
        disp_msglvl2 "Create directories" 
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST mkdir -p $BACKUP_PATH
        ssh $SSH_NO_BANNER $REMOTE_INST@$STANDBY_HOST mkdir -p $BACKUP_PATH2

	# create the log paths before restore on standby
	ssh $SSH_NO_BANNER $REMOTE_INST@$STANDBY_HOST mkdir -p $ACTIVE_LOG_PATH2
        ssh $SSH_NO_BANNER $REMOTE_INST@$STANDBY_HOST mkdir -p $ARCHIVE_LOG_PATH2

        disp_msglvl2 "Detele old backup images"
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST "rm $BACKUP_PATH/*"
        ssh $SSH_NO_BANNER $REMOTE_INST@$STANDBY_HOST "rm $BACKUP_PATH2/*"
        #db2 -v deactivate db $DBNAME  ## Making the database to be standalone first.
        disp_msglvl2 "Running online backup on $PRIMARY_HOST"
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST "db2 -v backup db $DBNAME online to $BACKUP_PATH"
        disp_msglvl2 "Copying the online backup to $STANDBY_HOST"
        scp $BACKUP_PATH/* $REMOTE_INST@$STANDBY_HOST:$BACKUP_PATH2
        ssh $SSH_NO_BANNER $STANDBY_HOST "chmod -Rf 777 $BACKUP_PATH2"
        disp_msglvl2 "Restoring DB $DBNAME on $STANDBY_HOST"
        ssh $SSH_NO_BANNER $REMOTE_INST@$STANDBY_HOST db2start   ## added this as sometimes DB2 instance is not started
        ssh $SSH_NO_BANNER $REMOTE_INST@$STANDBY_HOST "db2 -v restore db $DBNAME from $BACKUP_PATH2"
}

function confHadrStandby {
        disp_msglvl1 "HADR standby configuration on $STANDBY_HOST..."
        ssh $SSH_NO_BANNER $REMOTE_INST@$STANDBY_HOST db2stop
        ssh $SSH_NO_BANNER $REMOTE_INST@$STANDBY_HOST db2set DB2COMM=TCPIP
        ssh $SSH_NO_BANNER $REMOTE_INST@$STANDBY_HOST db2 -v update dbm cfg using SVCENAME $PORT
        ssh $SSH_NO_BANNER $REMOTE_INST@$STANDBY_HOST db2start

        ssh $SSH_NO_BANNER $REMOTE_INST@$STANDBY_HOST db2 -v update db cfg for $DBNAME using HADR_REMOTE_HOST $PRIMARY_HOST HADR_LOCAL_HOST $STANDBY_HOST HADR_LOCAL_SVC $HADR_PORT HADR_REMOTE_SVC $HADR_PORT HADR_REMOTE_INST $REMOTE_INST HADR_PEER_WINDOW 300 LOGINDEXBUILD ON


}

function startHadr {
        disp_msglvl2 "Starting standby"   
        ssh $SSH_NO_BANNER $REMOTE_INST@$STANDBY_HOST db2 start hadr on db $DBNAME as standby
        disp_msglvl2 "Starting primary"   
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST db2 start hadr on db $DBNAME as primary

        sleep 5
        disp_msglvl2 "Checking HADR status " 
        ssh $SSH_NO_BANNER $INST_USER@$PRIMARY_HOST  db2pd -db $DBNAME -hadr

}


confHadrPrimary

bkupCopyRestore
confHadrStandby
startHadr

