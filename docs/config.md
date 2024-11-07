# Configuration outputs    

## Files  

Db2 resource agent scripts are located at /usr/lib/ocf/resource.d/heartbeat    

## DBM CFG
```
[db2inst1@pacemakertest1 ~]$ db2 get dbm cfg |grep -i cluster
 Cluster manager                                         = PACEMAKER
[db2inst1@pacemakertest1 ~]$ ssh pacemakertest2 db2 get dbm cfg |grep -i cluster
 Cluster manager                                         = PACEMAKER
```


## VIP    

```
[root@pacemakertest1 hadr_pacemaker_on_fyre]# su - db2inst1
Last login: Tue Sep 13 18:35:54 PDT 2022
[db2inst1@pacemakertest1 ~]$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:00:0a:0b:64:ec brd ff:ff:ff:ff:ff:ff
    inet 10.11.100.236/20 brd 10.11.111.255 scope global dynamic noprefixroute eth0
       valid_lft 34818sec preferred_lft 34818sec
    inet 10.11.100.50/20 brd 10.11.111.255 scope global secondary eth0     <====
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:00:09:1e:e5:cf brd ff:ff:ff:ff:ff:ff
    inet 9.30.229.207/24 brd 9.30.229.255 scope global dynamic noprefixroute eth1
       valid_lft 34818sec preferred_lft 34818sec
``` 

## pacemaker

### crm status
```
[root@pacemakertest1 hadr_pacemaker_on_fyre]# crm status
Cluster Summary:
  * Stack: corosync
  * Current DC: NONE
  * Last updated: Tue Sep 13 18:40:28 2022
  * Last change:  Tue Sep 13 18:32:38 2022 by root via cibadmin on pacemakertest1
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
```

### crm config show
```
[root@pacemakertest1 hadr_pacemaker_on_fyre]# crm config show
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
        params ip=10.11.100.50 cidr_netmask=20 \
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
property cib-bootstrap-options: \
        stonith-enabled=false \
        no-quorum-policy=stop \
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

```

## qdevice
### corosync-qdevice-tool -s   
```
[root@pacemakertest1 hadr_pacemaker_on_fyre]# corosync-qdevice-tool -s
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
```

### configuration on disk  

```
[db2inst1@pacemakertest1 ~]$ cat /etc/corosync/corosync.conf
totem {
    version: 2
    cluster_name: db2domain
    transport: knet
    token: 10000
    crypto_cipher: aes256
    crypto_hash: sha256
}
nodelist {
    node {
        ring0_addr: pacemakertest1
        name: pacemakertest1
        nodeid: 1
    }
    node {
        ring0_addr: pacemakertest2
        name: pacemakertest2
        nodeid: 2
    }
}
logging {
    to_logfile: yes
    logfile: /var/log/cluster/corosync.log
    to_syslog: yes
    timestamp: hires
    function_name: on
    fileline: on
}
quorum {
    provider: corosync_votequorum
    device {
        model: net
        net {
            algorithm: lms
            host: pacemakertest3
        }
    }
}   

[root@pacemakertest1 cluster]# pwd
/var/log/cluster
[root@pacemakertest1 cluster]# ls -l
total 4
-rw-rw-rw- 1 root root    0 Sep 14 03:17 corosync.log
-rw-r--r-- 1 root root 1259 Sep 13 18:09 corosync.log-20220914.gz
```

### Live Configuration   

```
[root@pacemakertest1 cluster]# corosync-cfgtool -s
Printing link status.
Local node ID 1
LINK ID 0
	addr	= 10.11.100.236
	status:
		nodeid  1:	localhost
		nodeid  2:	connected
[root@pacemakertest1 cluster]# ssh pacemakertest2 corosync-cfgtool -s
Printing link status.
Local node ID 2
LINK ID 0
	addr	= 10.11.106.28
	status:
		nodeid  1:	connected
		nodeid  2:	localhost
```
