
#  HADR Pacemaker manual configuration on V11.5.5.0

## Create hosts from fyre menu.     
* Platform x    
* Image Redhat 8.1   
* Size : as your preference    
* Quantity 3   


## Prerequisite software installation. (on all hosts. )  
```
yum -y install libstdc++ sg3_utils libstdc++.so.6 perl-Sys-Syslog patch binutils cpp gcc-c++ ksh python2 perl-Sys-Syslog perl dnf


dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm 
```


## Configure HADR database

## Download pacemaker    
For the configuration on V11.5.5.0, you need to download pacemaker package manually.   
(V11.5.6.0 onwards, it's included in Db2 installation. )

https://mrs-ux.mrs-prod-7d4bdc08e7ddc90fa89b373d95c240eb-0000.us-south.containers.appdomain.cloud/marketing/iwm/platform/mrs/assets/mrs_landing_page?source=mrs-db2pcmk&lang=en_US

Db2_v11.5.5.0_Pacemaker_20201118_RHEL8.1_x86_64.tar.gz     

## Pacemaker installation

### First hosts
https://www.ibm.com/support/knowledgecenter/en/SSEPGG_11.5.0/com.ibm.db2.luw.admin.ha.doc/doc/install_pacemaker_cluster.html?pos=2

```
# tar xvfz Db2_v11.5.5.0_Pacemaker_20201118_RHEL8.1_x86_64.tar.gz
```

This tarball contains:

```
    README.md - this file
    CHANGELOG.md - notable changes for these packages
    ERRATA.md - any known outstanding issues, suggestions or corrections to published documentation
    ./Db2/db2cm - setup and configuration utility
    ./Db2agents/ - Db2 supported resource agents
    ./RPMS/<architecture> - Pacemaker and associated utility packages binaries
    ./RPMS/noarch - fencing agents, Scripts and documentation
    ./SRPMS - source RPMs used to build the binary RPMs
```

```
[root@pacemaker1 RPMS]# dnf install */*.rpm

[root@pacemaker1 RPMS]# rpm -q corosync 
corosync-3.0.4-1.db2pcmk.el8.x86_64
[root@pacemaker1 RPMS]# rpm -q pacemaker
pacemaker-2.0.4-1.db2pcmk.el8.x86_64
[root@pacemaker1 RPMS]# rpm -q crmsh 
crmsh-4.2.0-0.db2pcmk.el8.noarch


[root@pacemaker1 Db2]# cp db2cm /home/db2inst1/sqllib/adm
[root@pacemaker1 Db2]# chmod 755 /home/db2inst1/sqllib/adm/db2cm


[root@pacemaker1 Db2agents]# /home/db2inst1/sqllib/adm/db2cm -copy_resources /root/Db2_v11.5.5.0_Pacemaker_20201118_RHEL8.1_x86_64/Db2agents -host pacemaker1
Resources copied from /root/Db2_v11.5.5.0_Pacemaker_20201118_RHEL8.1_x86_64/Db2agents to /usr/lib/ocf/resource.d/heartbeat/ successfully on the local host pacemaker1

[root@pacemaker1 Db2agents]# /home/db2inst1/sqllib/adm/db2cm -copy_resources /root/Db2_v11.5.5.0_Pacemaker_20201118_RHEL8.1_x86_64/Db2agents -host pacemaker2
Failed to copy resources to remote host pacemaker2.
```

### Do the same on the 2nd host.   

```
# tar xvfz Db2_v11.5.5.0_Pacemaker_20201118_RHEL8.1_x86_64.tar.gz

[root@pacemaker2 RPMS]# dnf install */*.rpm

[root@pacemaker2 RPMS]# rpm -q corosync
corosync-3.0.4-1.db2pcmk.el8.x86_64
[root@pacemaker2 RPMS]# rpm -q pacemaker
pacemaker-2.0.4-1.db2pcmk.el8.x86_64
[root@pacemaker2 RPMS]# rpm -q crmsh
crmsh-4.2.0-0.db2pcmk.el8.noarch


[root@pacemaker2 Db2]# cp db2cm /home/db2inst1/sqllib/adm
[root@pacemaker2 Db2]# chmod 755 /home/db2inst1/sqllib/adm/db2cm

[root@pacemaker2 Db2]# /home/db2inst1/sqllib/adm/db2cm -copy_resources /root/Db2_v11.5.5.0_Pacemaker_20201118_RHEL8.1_x86_64/Db2agents -host pacemaker1
The authenticity of host 'pacemaker1 (10.11.82.135)' can't be established.
ECDSA key fingerprint is SHA256:fXfKMGxAtH8w4et4YXhZ5LpPNN3jOeT8zTKm2EA56Q4.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Resources copied from /root/Db2_v11.5.5.0_Pacemaker_20201118_RHEL8.1_x86_64/Db2agents to /usr/lib/ocf/resource.d/heartbeat/ successfully on the remote host pacemaker1

[root@pacemaker2 Db2]# /home/db2inst1/sqllib/adm/db2cm -copy_resources /root/Db2_v11.5.5.0_Pacemaker_20201118_RHEL8.1_x86_64/Db2agents -host pacemaker2
Resources copied from /root/Db2_v11.5.5.0_Pacemaker_20201118_RHEL8.1_x86_64/Db2agents to /usr/lib/ocf/resource.d/heartbeat/ successfully on the local host pacemaker2
```

### qdevice host / softwware installation.

```
[root@pacemaker1 ~]# rpm -qa | grep corosync-qdevice
corosync-qdevice-3.0.0-3.db2pcmk.el8.x86_64
corosync-qdevice-debuginfo-3.0.0-3.db2pcmk.el8.x86_64
corosync-qdevice-debugsource-3.0.0-3.db2pcmk.el8.x86_64

[root@pacemaker2 Db2]# rpm -qa | grep corosync-qdevice
corosync-qdevice-3.0.0-3.db2pcmk.el8.x86_64
corosync-qdevice-debuginfo-3.0.0-3.db2pcmk.el8.x86_64
corosync-qdevice-debugsource-3.0.0-3.db2pcmk.el8.x86_64
```

3rd host
```
[root@pacemaker3 ~]# tar xvfz Db2_v11.5.5.0_Pacemaker_20201118_RHEL8.1_x86_64.tar.gz

[root@pacemaker3 RPMS]# dnf install */*qnetd*

[root@pacemaker3 RPMS]# rpm -qa *qnetd*
corosync-qnetd-3.0.0-3.db2pcmk.el8.x86_64
corosync-qnetd-debuginfo-3.0.0-3.db2pcmk.el8.x86_64
```


## Pacemaker configuration  

On one of cluster host, by 'root' user  
```
[root@pacemaker1 ~]# cd /home/db2inst1/sqllib/adm
```

### create domain

```
[root@pacemaker1 adm]# ./db2cm -cluster -create -domain db2domain -host pacemaker1 -publicEthernet eth0 -host pacemaker2 -publicEthernet eth0
Created db2_pacemaker1_eth0 resource.
Created db2_pacemaker2_eth0 resource.
Cluster created successfully.
```

### create instance resource   
```
[root@pacemaker1 adm]# ./db2cm -create -instance db2inst1 -host pacemaker1
Created db2_pacemaker1_db2inst1_0 resource.
Instance resource for db2inst1 on pacemaker1 created successfully.

[root@pacemaker1 adm]# ./db2cm -create -instance db2inst1 -host pacemaker2
Created db2_pacemaker2_db2inst1_0 resource.
Instance resource for db2inst1 on pacemaker2 created successfully.

[root@pacemaker1 adm]# crm status
Cluster Summary:
  * Stack: corosync
  * Current DC: pacemaker1 (version 2.0.4-1.db2pcmk.el8-2deceaa3ae) - partition with quorum
  * Last updated: Thu Jan  7 14:27:03 2021
  * Last change:  Thu Jan  7 14:26:44 2021 by root via cibadmin on pacemaker1
  * 2 nodes configured
  * 4 resource instances configured

Node List:
  * Online: [ pacemaker1 pacemaker2 ]

Full List of Resources:
  * db2_pacemaker1_eth0    (ocf::heartbeat:db2ethmon):     Started pacemaker1
  * db2_pacemaker2_eth0    (ocf::heartbeat:db2ethmon):     Started pacemaker2
  * db2_pacemaker1_db2inst1_0    (ocf::heartbeat:db2inst):     Started pacemaker1
  * db2_pacemaker2_db2inst1_0    (ocf::heartbeat:db2inst):     Started pacemaker2

```

### Create DB resource 
```
[root@pacemaker1 adm]# ./db2cm -create -db sample -instance db2inst1
Database resource for SAMPLE created successfully.

[root@pacemaker1 adm]# crm status
Cluster Summary:
  * Stack: corosync
  * Current DC: pacemaker1 (version 2.0.4-1.db2pcmk.el8-2deceaa3ae) - partition with quorum
  * Last updated: Thu Jan  7 14:29:32 2021
  * Last change:  Thu Jan  7 14:29:04 2021 by root via cibadmin on pacemaker1
  * 2 nodes configured
  * 6 resource instances configured

Node List:
  * Online: [ pacemaker1 pacemaker2 ]

Full List of Resources:
  * db2_pacemaker1_eth0    (ocf::heartbeat:db2ethmon):     Started pacemaker1
  * db2_pacemaker2_eth0    (ocf::heartbeat:db2ethmon):     Started pacemaker2
  * db2_pacemaker1_db2inst1_0    (ocf::heartbeat:db2inst):     Started pacemaker1
  * db2_pacemaker2_db2inst1_0    (ocf::heartbeat:db2inst):     Started pacemaker2
  * Clone Set: db2_db2inst1_db2inst1_SAMPLE-clone [db2_db2inst1_db2inst1_SAMPLE] (promotable):
    * Masters: [ pacemaker1 ]
    * Slaves: [ pacemaker2 ]
```

### Create VIP 

```
[root@pacemaker1 adm] db2cm -create -primaryVIP 10.11.71.201 -db SAMPLE –instance db2inst1
```

```

[root@pacemaker1 adm]# crm status
Cluster Summary:
  * Stack: corosync
  * Current DC: pacemaker1 (version 2.0.4-1.db2pcmk.el8-2deceaa3ae) - partition with quorum
  * Last updated: Thu Jan  7 14:34:13 2021
  * Last change:  Thu Jan  7 14:34:04 2021 by root via cibadmin on pacemaker1
  * 2 nodes configured
  * 7 resource instances configured

Node List:
  * Online: [ pacemaker1 pacemaker2 ]

Full List of Resources:
  * db2_pacemaker1_eth0    (ocf::heartbeat:db2ethmon):     Started pacemaker1
  * db2_pacemaker2_eth0    (ocf::heartbeat:db2ethmon):     Started pacemaker2
  * db2_pacemaker1_db2inst1_0    (ocf::heartbeat:db2inst):     Started pacemaker1
  * db2_pacemaker2_db2inst1_0    (ocf::heartbeat:db2inst):     Started pacemaker2
  * Clone Set: db2_db2inst1_db2inst1_SAMPLE-clone [db2_db2inst1_db2inst1_SAMPLE] (promotable):
    * Masters: [ pacemaker1 ]
    * Slaves: [ pacemaker2 ]
  * db2_db2inst1_db2inst1_SAMPLE-primary-VIP    (ocf::heartbeat:IPaddr2):     Started pacemaker1
```


```

[root@pacemaker1 adm]# crm config show
node 1: pacemaker1 \
        attributes db2hadr-db2inst1_db2inst1_SAMPLE_reint=-1
node 2: pacemaker2 \
        attributes db2hadr-db2inst1_db2inst1_SAMPLE_reint=-1
primitive db2_db2inst1_db2inst1_SAMPLE db2hadr \
        params instance="db2inst1,db2inst1" dbname=SAMPLE \
        op demote interval=0s timeout=900s \
        op monitor interval=9s role=Master timeout=60s \
        op monitor interval=10s role=Slave timeout=60s \
        op promote interval=0s timeout=900s \
        op start interval=0s timeout=900s \
        op stop interval=0s timeout=900s \
        meta resource-stickiness=5000 migration-threshold=0
primitive db2_db2inst1_db2inst1_SAMPLE-primary-VIP IPaddr2 \
        params ip=10.11.82.200 cidr_netmask=20 \
        op monitor interval=30s \
        op start interval=0s timeout=20s \
        op stop interval=0s timeout=20s \
        meta is-managed=true
primitive db2_pacemaker1_db2inst1_0 db2inst \
        params instance=db2inst1 hostname=pacemaker1 \
        op monitor timeout=120s interval=10s on-fail=restart \
        op start interval=0s timeout=900s \
        op stop interval=0s timeout=900s \
        meta migration-threshold=0 is-managed=true
primitive db2_pacemaker1_eth0 db2ethmon \
        params interface=eth0 hostname=pacemaker1 repeat_count=4 repeat_interval=4 \
        op monitor timeout=30s interval=4 \
        op start timeout=60s interval=0s \
        op stop interval=0s timeout=20s \
        meta is-managed=true
primitive db2_pacemaker2_db2inst1_0 db2inst \
        params instance=db2inst1 hostname=pacemaker2 \
        op monitor timeout=120s interval=10s on-fail=restart \
        op start interval=0s timeout=900s \
        op stop interval=0s timeout=900s \
        meta migration-threshold=0 is-managed=true
primitive db2_pacemaker2_eth0 db2ethmon \
        params interface=eth0 hostname=pacemaker2 repeat_count=4 repeat_interval=4 \
        op monitor timeout=30s interval=4 \
        op start timeout=60s interval=0s \
        op stop interval=0s timeout=20s \
        meta is-managed=true
ms db2_db2inst1_db2inst1_SAMPLE-clone db2_db2inst1_db2inst1_SAMPLE \
        meta resource-stickiness=5000 migration-threshold=0 ordered=true promotable=true is-managed=true
colocation db2_db2inst1_db2inst1_SAMPLE-primary-VIP-colocation inf: db2_db2inst1_db2inst1_SAMPLE-primary-VIP:Started db2_db2inst1_db2inst1_SAMPLE-clone:Master
location loc-rule-db2_db2inst1_db2inst1_SAMPLE-eth0-pacemaker1 db2_db2inst1_db2inst1_SAMPLE-clone \
        rule -inf: db2ethmon-eth0 eq 0
location loc-rule-db2_db2inst1_db2inst1_SAMPLE-eth0-pacemaker2 db2_db2inst1_db2inst1_SAMPLE-clone \
        rule -inf: db2ethmon-eth0 eq 0
location loc-rule-db2_db2inst1_db2inst1_SAMPLE-node-pacemaker1 db2_db2inst1_db2inst1_SAMPLE-clone \
        rule -inf: db2inst-pacemaker1_db2inst1_0 eq 0
location loc-rule-db2_db2inst1_db2inst1_SAMPLE-node-pacemaker2 db2_db2inst1_db2inst1_SAMPLE-clone \
        rule -inf: db2inst-pacemaker2_db2inst1_0 eq 0
location no-probe-db2_pacemaker1_db2inst1_0 db2_pacemaker1_db2inst1_0 resource-discovery=never -inf: pacemaker2
location no-probe-db2_pacemaker1_eth0 db2_pacemaker1_eth0 resource-discovery=never -inf: pacemaker2
location no-probe-db2_pacemaker2_db2inst1_0 db2_pacemaker2_db2inst1_0 resource-discovery=never -inf: pacemaker1
location no-probe-db2_pacemaker2_eth0 db2_pacemaker2_eth0 resource-discovery=never -inf: pacemaker1
order order-rule-db2_db2inst1_db2inst1_SAMPLE-then-primary-VIP Mandatory: db2_db2inst1_db2inst1_SAMPLE-clone:start db2_db2inst1_db2inst1_SAMPLE-primary-VIP:start
location prefer-db2_pacemaker1_db2inst1_0 db2_pacemaker1_db2inst1_0 100: pacemaker1
location prefer-db2_pacemaker1_eth0 db2_pacemaker1_eth0 100: pacemaker1
location prefer-db2_pacemaker2_db2inst1_0 db2_pacemaker2_db2inst1_0 100: pacemaker2
location prefer-db2_pacemaker2_eth0 db2_pacemaker2_eth0 100: pacemaker2
location prefer-db2inst1-pacemaker1-SAMPLE-primary-VIP db2_db2inst1_db2inst1_SAMPLE-primary-VIP 100: pacemaker1
location prefer-db2inst1-pacemaker2-SAMPLE-primary-VIP db2_db2inst1_db2inst1_SAMPLE-primary-VIP 100: pacemaker2
location prefer-pacemaker1-db2inst1-db2_db2inst1_db2inst1_SAMPLE-clone db2_db2inst1_db2inst1_SAMPLE-clone 100: pacemaker1
location prefer-pacemaker2-db2inst1-db2_db2inst1_db2inst1_SAMPLE-clone db2_db2inst1_db2inst1_SAMPLE-clone 100: pacemaker2
property cib-bootstrap-options: \
        stonith-enabled=false \
        no-quorum-policy=ignore \
        stop-all-resources=false \
        cluster-recheck-interval=60 \
        symmetric-cluster=false \
        have-watchdog=false \
        dc-version=2.0.4-1.db2pcmk.el8-2deceaa3ae \
        cluster-infrastructure=corosync \
        cluster-name=db2domain
rsc_defaults rsc-options: \
        failure-timeout=60
rsc_defaults rsc_defaults-options: \
        is-managed=false
(END)
```

### Create qdevice

```
[root@pacemaker1 adm]# ./db2cm -create -qdevice pacemaker3
Successfully configured qdevice on nodes pacemaker1 and pacemaker2
Attempting to start qdevice on pacemaker3
Quorum device pacemaker3 added successfully.

[root@pacemaker1 adm]# corosync-qdevice-tool -s
Qdevice information
-------------------
Model:            Net
Node ID:        1
Configured node list:
    0    Node ID = 1
    1    Node ID = 2
Membership node list:    1, 2

Qdevice-net information
----------------------
Cluster name:        db2domain
QNetd host:        pacemaker3:5403
Algorithm:        LMS
Tie-breaker:        Node with lowest node ID
State:            Connected

[root@pacemaker3 ~]# corosync-qnetd-tool -l
Cluster "db2domain":
    Algorithm:        LMS
    Tie-breaker:    Node with lowest node ID
    Node ID 1:
        Client address:        ::ffff:10.11.82.135:52860
        Configured node list:    1, 2
        Membership node list:    1, 2
        Vote:            ACK (ACK)
    Node ID 2:
        Client address:        ::ffff:10.11.82.136:58330
        Configured node list:    1, 2
        Membership node list:    1, 2
        Vote:            ACK (ACK)
```

