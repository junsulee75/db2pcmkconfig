[Go to main page](https://github.ibm.com/junsulee/c)

# db2cm

Should be run by root user 

```
[db2inst1@jspcmk1 ~]$ db2cm -list
db2cm script must run as root
```

## Contents

- [db2cm](#db2cm)
  - [Contents](#contents)
  - [db2cm -list](#db2cm--list)
  - [more option in V11.5.8.0](#more-option-in-v11580)


## db2cm -list 
Simple HADR example.  

```
[root@jspcmk1 ~]# ~db2inst1/sqllib/bin/db2cm -list
      Cluster Status
 
Domain information:
 
HA configuration          = HADR
 
Domain name               = db2domain
Pacemaker version         = 2.1.2-4.db2pcmk.el8
Corosync version          = 3.1.6
Current domain leader     = jspcmk2
Number of nodes           = 2
Number of resources       = 7
 
Node information:
Name name           State
----------------    --------
jspcmk1             Online
jspcmk2             Online
 
Resource Information:
 
Resource Name             = db2_db2inst1_db2inst1_SAMPLE
  Resource Type                 = HADR
    DB Name                     = SAMPLE
    Managed                     = true
    HADR Primary Instance       = db2inst1
    HADR Primary Node           = jspcmk1
    HADR Primary State          = Online
    HADR Standby Instance       = db2inst1
    HADR Standby Node           = jspcmk2
    HADR Standby State          = Online
 
Resource Name             = db2_db2inst1_db2inst1_SAMPLE-primary-VIP
  State                         = Online
  Managed                       = true
  Resource Type                 = IP
    Node                        = jspcmk1
    Ip Address                  = 10.11.36.250
  Location                      = jspcmk1
 
Resource Name             = db2_jspcmk1_db2inst1_0
  State                         = Online
  Managed                       = true
  Resource Type                 = Instance
    Node                        = jspcmk1
    Instance Name               = db2inst1
 
Resource Name             = db2_jspcmk1_eth0
  State                         = Online
  Managed                       = true
  Resource Type                 = Network Interface
    Node                        = jspcmk1
    Interface Name              = eth0
 
Resource Name             = db2_jspcmk2_db2inst1_0
  State                         = Online
  Managed                       = true
  Resource Type                 = Instance
    Node                        = jspcmk2
    Instance Name               = db2inst1
 
Resource Name             = db2_jspcmk2_eth0
  State                         = Online
  Managed                       = true
  Resource Type                 = Network Interface
    Node                        = jspcmk2
    Interface Name              = eth0
 
Fencing Information:
  Not configured
Quorum Information:
  Qdevice
 
Qdevice information
-------------------
Model:			Net
Node ID:		1
Configured node list:
    0	Node ID = 1
    1	Node ID = 2
Membership node list:	1, 2

Qdevice-net information
----------------------
Cluster name:		db2domain
QNetd host:		jspcmk3:5403
Algorithm:		LMS
Tie-breaker:		Node with lowest node ID
State:			Connected

```

[content](#contents)


## more option in V11.5.8.0

```
[root@pacemakertest1 hadr_pacemaker_on_fyre]# /home/db2inst1/sqllib/bin/db2cm

|-------------------------------------------------------------------|
| Below is the list of command options of db2cm available           |
|   in different HA configurations.                                 |
| Search "db2cm - Db2 cluster manager utility" in IBM Documentation |
|   for detailed command option specifications.                     |
|-------------------------------------------------------------------|

  -create
    (Common):
        -cluster -domain <domainName> -host <host> -publicEthernet <publicEthernetDeviceName> -host <host> -publicEthernet <publicEthernetDeviceName>
        -publicEthernet <publicEthernetDeviceName> -host <host>
        -qdevice <quorumDeviceHostName>
      (Cloud Only):
        -aws -fence
        -azure -fence
    (HADR):
        -instance <instanceName> -host <host>
        -db <databaseName> -instance <instanceName>
        -primaryVIP <VIPAddress> [-netmask <subnetMask>] -db <databaseName> -instance <instanceName>
        -standbyVIP <VIPAddress> [-netmask <subnetMask>] -db <databaseName> -instance <instanceName>
      (Cloud Only):
        -aws -primaryVIP <VIPAddress> -rtb <routing table[,routing tables]> [-profile <AWS Profile>] -db <databaseName> -instance <instanceName>
        -aws -standbyVIP <VIPAddress> -rtb <routing table[,routing tables]> [-profile <AWS Profile>] -db <databaseName> -instance <instanceName>
        -azure -primarylbl <port> -db <databaseName> -instance <instanceName>
        -azure -standbylbl <port> -db <databaseName> -instance <instanceName>

    (Mutual Failover):
        -partition <partitionNum> -instance <instanceName>
        -primaryVIP <VIPAddress> [-netmask <subnetMask>] [-profile <AWS Profile>] -partition <partitionNum> -instance <instanceName>
        -mount <mountPoint> -partition <partitionNum> -instance <instanceName>
        -db <databaseName> -instance <instanceName> -partition <partitionNum>
      (Cloud Only):
        -aws -primaryVIP <VIPAddress> [-profile <AWS Profile>] -rtb <routing table[,routing tables]> -partition <partitionNum> -instance <instanceName>
        -azure -primarylbl <port> -partition <partitionNum> -instance <instanceName>

  -delete
    (Common):
        -cluster
        -publicEthernet <publicEthernetDeviceName> -host <host>
        -qdevice
      (Cloud Only):
        -aws -fence
        -azure -fence
    (HADR):
        -instance <instanceName> -host <host>
        -db <databaseName> -instance <instanceName>
        -primaryVIP -db <databaseName> -instance <instanceName>
        -standbyVIP -db <databaseName> -instance <instanceName>
      (Cloud Only):
        -aws -primaryVIP -db <databaseName> -instance <instanceName>
        -aws -standbyVIP -db <databaseName> -instance <instanceName>
        -azure -primarylbl -db <databaseName> -instance <instanceName>
        -azure -standbylbl -db <databaseName> -instance <instanceName>
    (Mutual Failover):
        -partition <partitionNum> -instance <instanceName>
        -primaryVIP -partition <partitionNum> -instance <instanceName>
        -mount <mountPoint> -partition <partitionNum> -instance <instanceName>
        -db <databaseName> -instance <instanceName> -partition <partitionNum>
      (Cloud Only):
        -aws -primaryVIP -partition <partitionNum> -instance <instanceName>
        -azure -primarylbl -partition <partitionNum> -instance <instanceName>

  -enable / -disable
    (Common):
        -all
    (HADR):
        -instance <instanceName> -host <host>
    (Mutual Failover):
        -partition <partitionNum> -instance <instanceName>

  -add / -remove
    (Mutual Failover):
        -dbMount <databaseName> -partition <partitionNum> -instance <instanceName>

  -move
    (Mutual Failover):
        -partition <partitionNum> -instance <instanceName> -host <hostName>

  -set
    (Mutual Failover):
        –option mountMonitoring <mountPoint> -value <yes|no> -partition <partitionNum> -instance <instanceName>

  -list
  -import <full path to a previously saved configuration generated by the -export option>
  -export <full path to a new file storing the current configuration>
  -dump
  -copy_resources <resourceAgentsPath> -host <host>

Optional remote commands:
  -remote_cmd <path to remote shell command>
  -remote_scp <path to remote copy command>
```

[content](#contents)   

