#!/bin/bash

## Script when running by db2 instance user.  
## It has all steps.
## Use this only for test purpose
## junsulee@au1.ibm.com
##

source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh


ACTIVE_LOG_PATH=$HOME/active_log_path
ARCHIVE_LOG_PATH=$HOME/archive_log_path

BACKUP_PATH=$HOME/backup

function confHadrPrimary {
db2stop
db2set DB2COMM=TCPIP
db2 -v update dbm cfg using SVCENAME $PORT
db2start

if [ $DBNAME  = "sample" ]; then
	db2sampl
else
	db2 -v create db $DBNAME
fi

mkdir -p $ACTIVE_LOG_PATH
mkdir -p $ARCHIVE_LOG_PATH

db2 -v update db cfg for $DBNAME using NEWLOGPATH $ACTIVE_LOG_PATH
db2 -v update db cfg for $DBNAME using LOGARCHMETH1 DISK:$ARCHIVE_LOG_PATH
#db2 restore db $DBNAME

db2 -v update db cfg for $DBNAME using HADR_LOCAL_HOST $PRIMARY_HOST
db2 -v update db cfg for $DBNAME using HADR_REMOTE_HOST $STANDBY_HOST
db2 -v update db cfg for $DBNAME using HADR_LOCAL_SVC $HADR_PORT
db2 -v update db cfg for $DBNAME using HADR_REMOTE_SVC $HADR_PORT
db2 -v update db cfg for $DBNAME using HADR_REMOTE_INST $REMOTE_INST
db2 -v update db cfg for $DBNAME using HADR_PEER_WINDOW 300
db2 -v update db cfg for $DBNAME using  LOGINDEXBUILD ON

db2 -v backup db $DBNAME to /dev/null
db2 -v activate db $DBNAME

}

function bkupCopyRestore {
        mkdir -p $BACKUP_PATH
        ssh $STANDBY_HOST mkdir -p $BACKUP_PATH

	# create the log paths before restore on standby
	ssh $STANDBY_HOST mkdir -p $ACTIVE_LOG_PATH
        ssh $STANDBY_HOST mkdir -p $ARCHIVE_LOG_PATH
        rm $BACKUP_PATH/*
        ssh $STANDBY_HOST rm $BACKUP_PATH/*
        #db2 -v deactivate db $DBNAME  ## Making the database to be standalone first.
        db2 -v backup db $DBNAME online to $BACKUP_PATH
        scp $BACKUP_PATH/* $REMOTE_INST@$STANDBY_HOST:$BACKUP_PATH
        ssh $STANDBY_HOST db2start   ## added this as sometimes DB2 instance is not started
        ssh $STANDBY_HOST db2 -v restore db $DBNAME from $BACKUP_PATH
}

function confHadrStandby {
        ssh $STANDBY_HOST db2stop
        ssh $STANDBY_HOST db2set DB2COMM=TCPIP
        ssh $STANDBY_HOST db2 update dbm cfg using SVCENAME $PORT
        ssh $STANDBY_HOST db2start

        ssh $STANDBY_HOST db2 update db cfg for $DBNAME using HADR_REMOTE_HOST $PRIMARY_HOST HADR_LOCAL_HOST $STANDBY_HOST HADR_LOCAL_SVC $HADR_PORT HADR_REMOTE_SVC $HADR_PORT HADR_REMOTE_INST $REMOTE_INST HADR_PEER_WINDOW 300 LOGINDEXBUILD ON


}

function startHadr {
        ssh $STANDBY_HOST db2 start hadr on db $DBNAME as standby
        db2 start hadr on db $DBNAME as primary

        db2pd -db $DBNAME -hadr

}


confHadrPrimary
bkupCopyRestore
confHadrStandby

startHadr

