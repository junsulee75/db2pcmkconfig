
#  HADR Pacemaker manual configuration on V11.5.6.0

Same for V11.5.7.0 ~ 11.5.8.0   

## Create hosts from fyre menu.     
* Platform x    
* Image Redhat 8.2  (Supported from V11.5.6.0) 
* Size : as your preference    
* Quantity 3   

## Get DB2 image
```
[root@pacemakertest1 ~]# scp root@lamps1.fyre.ibm.com:/root/db2_image/v11.5.6_linuxx64_server_dec.tar.gz . 

[root@pacemakertest1 ~]# scp v11.5.6_linuxx64_server_dec.tar.gz root@pacemakertest2:/root

[root@pacemakertest1 ~]# scp v11.5.6_linuxx64_server_dec.tar.gz root@pacemakertest3:/root
```

## Prerequisite software installation. (on all hosts. )  
```
yum -y install libstdc++ sg3_utils libstdc++.so.6 perl-Sys-Syslog patch binutils cpp gcc-c++ ksh python2 perl-Sys-Syslog perl dnf 

dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm 

yum -y install python3-dnf-plugin-versionlock   ## necessary only on Linux
```

## Db2 installation   (on all hosts)    

> NOTE : May not need to full DB2 installation on 3rd host. 

[Reference](https://www.ibm.com/docs/en/db2/11.5?topic=pacemaker-installing-using-db2-installer)


```
[root@pacemakertest1 server_dec]# ./db2_install
..
Task #46 start
Description: Pacemaker 
Estimated time 100 second(s) 
Task #46 end
..

```

Installation log   
```
..
Installing: PCMK
..

The Db2 resource agent scripts are used by the Pacemaker cluster manager with the Db2 HA feature.

These Db2 resource agent scripts are located at /usr/lib/ocf/resource.d/heartbeat. The
database product installer detects whether these Db2 resource agent scripts need to
be installed or updated.

User response:

No action is required.
``


```

### Check installed RPM ( all hosts )

```
[root@pacemakertest1 server_dec]# rpm -qa |grep -i pacemaker
rpm -qa |grep -i pacemaker
pacemaker-schemas-2.0.4-2.db2pcmk.el8.noarch
pacemaker-cli-2.0.4-2.db2pcmk.el8.x86_64
pacemaker-remote-debuginfo-2.0.4-2.db2pcmk.el8.x86_64
pacemaker-cli-debuginfo-2.0.4-2.db2pcmk.el8.x86_64
pacemaker-debugsource-2.0.4-2.db2pcmk.el8.x86_64
pacemaker-cluster-libs-2.0.4-2.db2pcmk.el8.x86_64
pacemaker-libs-devel-2.0.4-2.db2pcmk.el8.x86_64
pacemaker-cluster-libs-debuginfo-2.0.4-2.db2pcmk.el8.x86_64
pacemaker-doc-2.0.4-2.db2pcmk.el8.noarch
pacemaker-debuginfo-2.0.4-2.db2pcmk.el8.x86_64
pacemaker-remote-2.0.4-2.db2pcmk.el8.x86_64
pacemaker-libs-debuginfo-2.0.4-2.db2pcmk.el8.x86_64
pacemaker-libs-2.0.4-2.db2pcmk.el8.x86_64
pacemaker-2.0.4-2.db2pcmk.el8.x86_64
pacemaker-cts-2.0.4-2.db2pcmk.el8.noarch

[root@pacemakertest1 ~]# rpm -qa |grep -i coro
corosync-debuginfo-3.0.4-2.db2pcmk.el8.x86_64
corosync-qdevice-debuginfo-3.0.0-4.db2pcmk.el8.x86_64
corosync-debugsource-3.0.4-2.db2pcmk.el8.x86_64
corosync-qdevice-debugsource-3.0.0-4.db2pcmk.el8.x86_64
corosynclib-devel-3.0.4-2.db2pcmk.el8.x86_64
corosync-qnetd-3.0.0-4.db2pcmk.el8.x86_64
corosync-qdevice-3.0.0-4.db2pcmk.el8.x86_64
corosync-3.0.4-2.db2pcmk.el8.x86_64
corosynclib-debuginfo-3.0.4-2.db2pcmk.el8.x86_64
corosync-vqsim-debuginfo-3.0.4-2.db2pcmk.el8.x86_64
corosynclib-3.0.4-2.db2pcmk.el8.x86_64
corosync-qnetd-debuginfo-3.0.0-4.db2pcmk.el8.x86_64
corosync-vqsim-3.0.4-2.db2pcmk.el8.x86_64

[root@pacemakertest1 ~]# rpm -qa |grep crmsh
crmsh-test-4.2.0-0.db2pcmk.el8.noarch
crmsh-scripts-4.2.0-0.db2pcmk.el8.noarch
crmsh-4.2.0-0.db2pcmk.el8.noarch

[root@pacemakertest1 ~]# rpm -qa | grep corosync-qdevice
corosync-qdevice-debuginfo-3.0.0-4.db2pcmk.el8.x86_64
corosync-qdevice-debugsource-3.0.0-4.db2pcmk.el8.x86_64
corosync-qdevice-3.0.0-4.db2pcmk.el8.x86_64

[root@pacemakertest1 ~]# rpm -qa *qnetd*
corosync-qnetd-3.0.0-4.db2pcmk.el8.x86_64
corosync-qnetd-debuginfo-3.0.0-4.db2pcmk.el8.x86_64

```

On 3rd host, make sure the following packages are installed.  
(The packages are needed for qdevice host) 
```
[root@pacemakertest1 ~]# ssh pacemakertest3 rpm -qa *qnetd*
corosync-qnetd-debuginfo-3.0.0-4.db2pcmk.el8.x86_64
corosync-qnetd-3.0.0-4.db2pcmk.el8.x86_64
```



## Configure HADR database

use `03_hadr_conf.sh` as Db2 instance user.      


## Pacemaker configuration  

On one of cluster host, by 'root' user  
```
[root@pacemakertest1 ~]# /home/db2inst1/sqllib/bin/db2cm
db2cm usage:

./db2cm
-create
   -cluster -domain <domainName> -host <host> -publicEthernet <publicEthernetDeviceName> -host <host> -publicEthernet <publicEthernetDeviceName>
   -instance <instanceName> -host <host>
   -db <databaseName> -instance <localInstanceName>
   -publicEthernet <publicEthernetDeviceName> -host <host>
   -primaryVIP <VIPAddress> [-netmask <subnetMask>] -db <databaseName> -instance <localInstanceName>
   -standbyVIP <VIPAddress> [-netmask <subnetMask>] -db <databaseName> -instance <localInstanceName>
   -qdevice <quorumDeviceHostName>
-delete
   -cluster
   -publicEthernet <publicEthernetDeviceName> -host <host>
   -instance <instanceName> -host <host>
   -db <databaseName> -instance <instanceName>
   -primaryVIP -db <databaseName> -instance <localInstanceName>
   -standbyVIP -db <databaseName> -instance <localInstanceName>
   -qdevice
-disable
   -all
   -instance <instanceName> -host <host>
-enable
   -all
   -instance <instanceName> -host <host>
-list
-dump
-import <full path to a previously saved configuration generated by the -export option>
-export <full path to a new file storing the current configuration>
-copy_resources <resourceAgentsPath> -host <host>
-help

```

### create domain

```
[root@pacemakertest1 ~]# /home/db2inst1/sqllib/bin/db2cm -cluster -create -domain db2domain -host pacemakertest1 -publicEthernet eth0 -host pacemakertest2 -publicEthernet eth0
Created db2_pacemakertest1_eth0 resource.
Created db2_pacemakertest2_eth0 resource.
Cluster created successfully.
```

### create instance resource   
```
[root@pacemakertest1 ~]# /home/db2inst1/sqllib/bin/db2cm -create -instance db2inst1 -host pacemakertest1
Created db2_pacemakertest1_db2inst1_0 resource.
Instance resource for db2inst1 on pacemakertest1 created successfully.
[root@pacemakertest1 ~]# /home/db2inst1/sqllib/bin/db2cm -create -instance db2inst1 -host pacemakertest2
Created db2_pacemakertest2_db2inst1_0 resource.
Instance resource for db2inst1 on pacemakertest2 created successfully.

[root@pacemakertest1 ~]# which crm
/usr/sbin/crm
[root@pacemakertest1 ~]# crm status
Cluster Summary:
  * Stack: corosync
  * Current DC: pacemakertest2 (version 2.0.4-2.db2pcmk.el8-2deceaa3ae) - partition with quorum
  * Last updated: Sat Sep 18 18:53:52 2021
  * Last change:  Sat Sep 18 18:53:09 2021 by root via cibadmin on pacemakertest1
  * 2 nodes configured
  * 4 resource instances configured

Node List:
  * Online: [ pacemakertest1 pacemakertest2 ]

Full List of Resources:
  * db2_pacemakertest1_eth0	(ocf::heartbeat:db2ethmon):	 Started pacemakertest1
  * db2_pacemakertest2_eth0	(ocf::heartbeat:db2ethmon):	 Started pacemakertest2
  * db2_pacemakertest1_db2inst1_0	(ocf::heartbeat:db2inst):	 Started pacemakertest1
  * db2_pacemakertest2_db2inst1_0	(ocf::heartbeat:db2inst):	 Started pacemakertest2
```

### Create DB resource 
```
[root@pacemakertest1 ~]# /home/db2inst1/sqllib/bin/db2cm -create -db sample -instance db2inst1
Database resource for SAMPLE created successfully.
[root@pacemakertest1 ~]# 
[root@pacemakertest1 ~]# crm status
Cluster Summary:
  * Stack: corosync
  * Current DC: pacemakertest2 (version 2.0.4-2.db2pcmk.el8-2deceaa3ae) - partition with quorum
  * Last updated: Sat Sep 18 18:55:26 2021
  * Last change:  Sat Sep 18 18:55:14 2021 by root via cibadmin on pacemakertest1
  * 2 nodes configured
  * 6 resource instances configured

Node List:
  * Online: [ pacemakertest1 pacemakertest2 ]

Full List of Resources:
  * db2_pacemakertest1_eth0	(ocf::heartbeat:db2ethmon):	 Started pacemakertest1
  * db2_pacemakertest2_eth0	(ocf::heartbeat:db2ethmon):	 Started pacemakertest2
  * db2_pacemakertest1_db2inst1_0	(ocf::heartbeat:db2inst):	 Started pacemakertest1
  * db2_pacemakertest2_db2inst1_0	(ocf::heartbeat:db2inst):	 Started pacemakertest2
  * Clone Set: db2_db2inst1_db2inst1_SAMPLE-clone [db2_db2inst1_db2inst1_SAMPLE] (promotable):
    * Masters: [ pacemakertest1 ]
    * Slaves: [ pacemakertest2 ]
```

### Create VIP 

```
[root@pacemakertest1 ~]# /home/db2inst1/sqllib/bin/db2cm -create -primaryVIP 10.11.71.150 -db sample -instance db2inst1
Primary VIP resource created successfully.
[root@pacemakertest1 ~]# crm status
Cluster Summary:
  * Stack: corosync
  * Current DC: pacemakertest2 (version 2.0.4-2.db2pcmk.el8-2deceaa3ae) - partition with quorum
  * Last updated: Sat Sep 18 18:57:59 2021
  * Last change:  Sat Sep 18 18:57:52 2021 by root via cibadmin on pacemakertest1
  * 2 nodes configured
  * 7 resource instances configured

Node List:
  * Online: [ pacemakertest1 pacemakertest2 ]

Full List of Resources:
  * db2_pacemakertest1_eth0	(ocf::heartbeat:db2ethmon):	 Started pacemakertest1
  * db2_pacemakertest2_eth0	(ocf::heartbeat:db2ethmon):	 Started pacemakertest2
  * db2_pacemakertest1_db2inst1_0	(ocf::heartbeat:db2inst):	 Started pacemakertest1
  * db2_pacemakertest2_db2inst1_0	(ocf::heartbeat:db2inst):	 Started pacemakertest2
  * Clone Set: db2_db2inst1_db2inst1_SAMPLE-clone [db2_db2inst1_db2inst1_SAMPLE] (promotable):
    * Masters: [ pacemakertest1 ]
    * Slaves: [ pacemakertest2 ]
  * db2_db2inst1_db2inst1_SAMPLE-primary-VIP	(ocf::heartbeat:IPaddr2):	 Started pacemakertest1

[root@pacemakertest1 ~]# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:00:0a:0b:47:7f brd ff:ff:ff:ff:ff:ff
    inet 10.11.71.127/20 brd 10.11.79.255 scope global dynamic noprefixroute eth0
       valid_lft 42395sec preferred_lft 42395sec
    inet 10.11.71.150/20 brd 10.11.79.255 scope global secondary eth0   <=========
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:20:09:1e:92:8b brd ff:ff:ff:ff:ff:ff
    inet 9.30.146.139/23 brd 9.30.147.255 scope global dynamic noprefixroute eth1
       valid_lft 42435sec preferred_lft 42435sec
```


```
[root@pacemakertest1 ~]# crm config show
node 1: pacemakertest1 \
        attributes db2hadr-db2inst1_db2inst1_SAMPLE_reint=-1
node 2: pacemakertest2 \
        attributes db2hadr-db2inst1_db2inst1_SAMPLE_reint=-1
primitive db2_db2inst1_db2inst1_SAMPLE db2hadr \
        params instance="db2inst1,db2inst1" dbname=SAMPLE \
        op demote interval=0s timeout=900s \
        op monitor interval=9s role=Master timeout=60s \
        op monitor interval=10s role=Slave timeout=60s \
        op promote interval=0s timeout=900s \
        op start interval=0s timeout=900s \
        op stop interval=0s timeout=900s
primitive db2_db2inst1_db2inst1_SAMPLE-primary-VIP IPaddr2 \
        params ip=10.11.71.150 cidr_netmask=20 \
        op monitor interval=30s \
        op start interval=0s timeout=20s \
        op stop interval=0s timeout=20s \
        meta is-managed=true
primitive db2_pacemakertest1_db2inst1_0 db2inst \
        params instance=db2inst1 hostname=pacemakertest1 \
        op monitor timeout=120s interval=10s on-fail=restart \
        op start interval=0s timeout=900s \
        op stop interval=0s timeout=900s \
        meta migration-threshold=0 is-managed=true
primitive db2_pacemakertest1_eth0 db2ethmon \
        params interface=eth0 hostname=pacemakertest1 repeat_count=4 repeat_interval=4 \
        op monitor timeout=30s interval=4 \
        op start timeout=60s interval=0s \
        op stop interval=0s timeout=20s \
        meta is-managed=true
primitive db2_pacemakertest2_db2inst1_0 db2inst \
        params instance=db2inst1 hostname=pacemakertest2 \
        op monitor timeout=120s interval=10s on-fail=restart \
        op start interval=0s timeout=900s \
        op stop interval=0s timeout=900s \
        meta migration-threshold=0 is-managed=true
primitive db2_pacemakertest2_eth0 db2ethmon \
        params interface=eth0 hostname=pacemakertest2 repeat_count=4 repeat_interval=4 \
        op monitor timeout=30s interval=4 \
        op start timeout=60s interval=0s \
        op stop interval=0s timeout=20s \
        meta is-managed=true
ms db2_db2inst1_db2inst1_SAMPLE-clone db2_db2inst1_db2inst1_SAMPLE \
        meta resource-stickiness=5000 migration-threshold=1 ordered=true promotable=true is-managed=true
colocation db2_db2inst1_db2inst1_SAMPLE-primary-VIP-colocation inf: db2_db2inst1_db2inst1_SAMPLE-primary-VIP:Started db2_db2inst1_db2inst1_SAMPLE-clone:Master
location loc-rule-db2_db2inst1_db2inst1_SAMPLE-eth0-pacemakertest1 db2_db2inst1_db2inst1_SAMPLE-clone \
        rule -inf: db2ethmon-eth0 eq 0
location loc-rule-db2_db2inst1_db2inst1_SAMPLE-eth0-pacemakertest2 db2_db2inst1_db2inst1_SAMPLE-clone \
        rule -inf: db2ethmon-eth0 eq 0
location loc-rule-db2_db2inst1_db2inst1_SAMPLE-node-pacemakertest1 db2_db2inst1_db2inst1_SAMPLE-clone \
        rule -inf: db2inst-pacemakertest1_db2inst1_0 eq 0
location loc-rule-db2_db2inst1_db2inst1_SAMPLE-node-pacemakertest2 db2_db2inst1_db2inst1_SAMPLE-clone \
        rule -inf: db2inst-pacemakertest2_db2inst1_0 eq 0
location no-probe-db2_pacemakertest1_db2inst1_0 db2_pacemakertest1_db2inst1_0 resource-discovery=never -inf: pacemakertest2
location no-probe-db2_pacemakertest1_eth0 db2_pacemakertest1_eth0 resource-discovery=never -inf: pacemakertest2
location no-probe-db2_pacemakertest2_db2inst1_0 db2_pacemakertest2_db2inst1_0 resource-discovery=never -inf: pacemakertest1
location no-probe-db2_pacemakertest2_eth0 db2_pacemakertest2_eth0 resource-discovery=never -inf: pacemakertest1
order order-rule-db2_db2inst1_db2inst1_SAMPLE-then-primary-VIP Mandatory: db2_db2inst1_db2inst1_SAMPLE-clone:start db2_db2inst1_db2inst1_SAMPLE-primary-VIP:start
location prefer-db2_pacemakertest1_db2inst1_0 db2_pacemakertest1_db2inst1_0 100: pacemakertest1
location prefer-db2_pacemakertest1_eth0 db2_pacemakertest1_eth0 100: pacemakertest1
location prefer-db2_pacemakertest2_db2inst1_0 db2_pacemakertest2_db2inst1_0 100: pacemakertest2
location prefer-db2_pacemakertest2_eth0 db2_pacemakertest2_eth0 100: pacemakertest2
location prefer-db2inst1-pacemakertest1-SAMPLE-primary-VIP db2_db2inst1_db2inst1_SAMPLE-primary-VIP 100: pacemakertest1
location prefer-db2inst1-pacemakertest2-SAMPLE-primary-VIP db2_db2inst1_db2inst1_SAMPLE-primary-VIP 100: pacemakertest2
location prefer-pacemakertest1-db2inst1-db2_db2inst1_db2inst1_SAMPLE-clone db2_db2inst1_db2inst1_SAMPLE-clone 100: pacemakertest1
location prefer-pacemakertest2-db2inst1-db2_db2inst1_db2inst1_SAMPLE-clone db2_db2inst1_db2inst1_SAMPLE-clone 100: pacemakertest2
property cib-bootstrap-options: \
        stonith-enabled=false \
        no-quorum-policy=ignore \
        stop-all-resources=false \
        cluster-recheck-interval=60 \
        symmetric-cluster=true \
        have-watchdog=false \
        dc-version=2.0.4-2.db2pcmk.el8-2deceaa3ae \
        cluster-infrastructure=corosync \
        cluster-name=db2domain
rsc_defaults rsc-options: \
        failure-timeout=10
rsc_defaults rsc_defaults-options: \
        is-managed=false
(END)
```

### Create qdevice

```
[root@pacemakertest1 ~]# /home/db2inst1/sqllib/bin/db2cm -create -qdevice pacemakertest3
Successfully configured qdevice on nodes pacemakertest1 and pacemakertest2
Attempting to start qdevice on pacemakertest3
Quorum device pacemakertest3 added successfully.
[root@pacemakertest1 ~]# 
[root@pacemakertest1 ~]# which corosync-qdevice-tool
/usr/sbin/corosync-qdevice-tool
[root@pacemakertest1 ~]# 
[root@pacemakertest1 ~]# corosync-qdevice-tool -s
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
QNetd host:		pacemakertest3:5403
Algorithm:		LMS
Tie-breaker:		Node with lowest node ID
State:			Connected

[root@pacemakertest1 ~]# ssh pacemakertest3 corosync-qnetd-tool -l
Cluster "db2domain":
    Algorithm:		LMS
    Tie-breaker:	Node with lowest node ID
    Node ID 1:
        Client address:		::ffff:10.11.71.127:50038
        Configured node list:	1, 2
        Membership node list:	1, 2
        Vote:			ACK (ACK)
    Node ID 2:
        Client address:		::ffff:10.11.71.180:48260
        Configured node list:	1, 2
        Membership node list:	1, 2
        Vote:			ACK (ACK)
```

