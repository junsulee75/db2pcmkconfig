[Go to main page](https://github.ibm.com/junsulee/c)

# Pacemaker PD

## Contents

- [Pacemaker PD](#pacemaker-pd)
  - [Contents](#contents)
  - [pacemaker log files](#pacemaker-log-files)
  - [collection](#collection)
    - [db2cm -dump](#db2cm--dump)
    - [Commands](#commands)
  - [files](#files)
    - [monitoring scripts](#monitoring-scripts)
  - [MISC](#misc)
    - [db2cm error (?)](#db2cm-error-)
    - [db2 code : db2cm.C](#db2-code--db2cmc)


## pacemaker log files   

/var/log/cluster/corosync.log    
/var/log/pacemaker/pacemaker.log     

/tmp/db2cm/db2cm.log
/tmp/db2cm/db2cm.run.log.xxx  # after running db2cm command, find the file matching time.       


## collection

### db2cm -dump   

/home/db2inst1/sqllib/bin/db2cm -dump   

### Commands   

> `#` : by root user,  `$` : by db2 instance user   

```
# corosync-cmapctl
$ db2pd -pdcollection index=corosync-cmapctl
```

```
db2pd -pdcollection index=corosync_conf
```

```
# crm configure show
$ db2pd -pdcollection index=crm_configure_show
```

[content](#contents) 

## files  

### monitoring scripts 


```
INSTALL_PATH=/opt/ibm/db2/V11.5_mod8
ls $INSTALL_PATH/ha/pcmk
# file $INSTALL_PATH/ha/pcmk/*
/opt/ibm/db2/V11.5_mod8/ha/pcmk/db2ethmon:    POSIX shell script, UTF-8 Unicode text executable, with very long lines
/opt/ibm/db2/V11.5_mod8/ha/pcmk/db2fs:        POSIX shell script, ASCII text executable
/opt/ibm/db2/V11.5_mod8/ha/pcmk/db2hadr:      POSIX shell script, ASCII text executable
/opt/ibm/db2/V11.5_mod8/ha/pcmk/db2inst:      POSIX shell script, ASCII text executable, with very long lines
/opt/ibm/db2/V11.5_mod8/ha/pcmk/db2partition: Bourne-Again shell script, ASCII text executable
```

The files are copied into the path.   

```
# ls /usr/lib/ocf/resource.d/heartbeat/db2*
/usr/lib/ocf/resource.d/heartbeat/db2        /usr/lib/ocf/resource.d/heartbeat/db2fs    /usr/lib/ocf/resource.d/heartbeat/db2inst
/usr/lib/ocf/resource.d/heartbeat/db2ethmon  /usr/lib/ocf/resource.d/heartbeat/db2hadr  /usr/lib/ocf/resource.d/heartbeat/db2partition
```

[content](#contents) 


## MISC  
### db2cm error (?)     
```
# /home/db2inst1/sqllib/bin/db2cm -create -instance db2inst1 -host pacemakertest2
*****************************************************************************************
*  Systems must only be used for conducting IBMs business.				*
*  IBM may exercise rights to manage and enforce security, monitor use,			*
*  remove access or block traffic to and from this system, as well as			*
*  any other rights listed in ITSS.							*
*											*
*  Users must comply with DevIT service terms of use, IBM policies,			*
*  directives and corporate instructions including, import/export of data,		*
*  BCGs, Corporate Instructions, Standards, Addenda as well as all other		*
*  responsibilities listed in ITSS							*
*****************************************************************************************
Error: Db2 instance db2inst1 does not exist on pacemakertest2.
```

```

[root@pacemakertest1 tmp]# pwd
/work/hadr_pacemaker_on_fyre/db2cm/db2cmDump/tmp
[root@pacemakertest1 tmp]# ls
db2cm.run.log.2023-04-20_00-37-04  db2cm.run.log.2023-04-20_00-37-46  db2cm.run.log.2023-04-20_00-43-04  db2cm.run.log.2023-04-20_00-53-11  db2cm.run.log.2023-04-20_00-55-16
db2cm.run.log.2023-04-20_00-37-28  db2cm.run.log.2023-04-20_00-37-49  db2cm.run.log.2023-04-20_00-46-21  db2cm.run.log.2023-04-20_00-53-58  db2cm.run.log.2023-04-20_01-01-38
db2cm.run.log.2023-04-20_00-37-43  db2cm.run.log.2023-04-20_00-37-51  db2cm.run.log.2023-04-20_00-48-33  db2cm.run.log.2023-04-20_00-54-58  db2cm.run.log.2023-04-20_01-02-57
```

```
2023-04-20-01.01.38.245980 [db2cm] Start db2cm -create -instance db2inst1 -host pacemakertest2
..
2023-04-20-01.01.39.776677 [execCmd][1046] Start ssh pacemakertest2 "su db2inst1 -s /bin/bash -c '. /home/db2inst1/sqllib/db2profile > /dev/null 2>&1; printenv DB2INSTANCE'"
db2inst1
2023-04-20-01.01.40.109280 [execCmd][1046] End
2023-04-20-01.01.40.112144 [db2cm] End execution with exit code 1 on line 1863
```

### db2 code : db2cm.C    


[content](#contents)     