[Go to main page](https://github.ibm.com/junsulee/c)

# Pacemaker operations   



## Contents

- [Pacemaker operations](#pacemaker-operations)
  - [Contents](#contents)
  - [Pacemaker Stop / Start](#pacemaker-stop--start)
  - [Normal HADR takeover](#normal-hadr-takeover)
    - [db2diag](#db2diag)
    - [/var/log/pacemaker/pacemaker.log](#varlogpacemakerpacemakerlog)
  - [Add VIP when it's not set yet](#add-vip-when-its-not-set-yet)


## Primary host down

```
Fri Jul 12 23:20:09 PDT 2024
```



Reference      
https://www.ibm.com/docs/en/db2/11.5?topic=pm-applying-rolling-updates-pacemaker-managed-hadr-db2-instance   

Stop & start cluster and pacemaker:   

```
Standby:
systemctl stop pacemaker
systemctl stop corosync
systemctl stop corosync-qdevice

Primary:
systemctl stop pacemaker
systemctl stop corosync
systemctl stop corosync-qdevice

Primary:
systemctl start pacemaker
systemctl start corosync
systemctl start corosync-qdevice

Standby:
systemctl start pacemaker
systemctl start corosync
systemctl start corosync-qdevice
```
- [Go to content](#contents)


## Normal HADR takeover   


```
[v11580@pcmk2 ~]$ db2 takeover hadr on db hadrdb
DB20000I  The TAKEOVER HADR ON DATABASE command completed successfully.
[v11580@pcmk2 ~]$ exit
logout
[root@pcmk2 ~]# crm status
Cluster Summary:
  * Stack: corosync
  * Current DC: pcmk1 (version 2.1.2-4.db2pcmk.el8-ada5c3b36e2) - partition with quorum
  * Last updated: Fri Jun  9 20:26:47 2023
  * Last change:  Wed Jun  7 18:37:35 2023 by root via cibadmin on pcmk1
  * 2 nodes configured
  * 6 resource instances configured

Node List:
  * Online: [ pcmk1 pcmk2 ]

Full List of Resources:
  * db2_pcmk1_eth0	(ocf::heartbeat:db2ethmon):	 Started pcmk1
  * db2_pcmk2_eth0	(ocf::heartbeat:db2ethmon):	 Started pcmk2
  * db2_pcmk1_v11580_0	(ocf::heartbeat:db2inst):	 Started pcmk1
  * db2_pcmk2_v11580_0	(ocf::heartbeat:db2inst):	 Started pcmk2
  * Clone Set: db2_v11580_v11580_HADRDB-clone [db2_v11580_v11580_HADRDB] (promotable):
    * Masters: [ pcmk2 ]    <===
    * Slaves: [ pcmk1 ]
```
- [Go to content](#contents)
 
### db2diag   

On original primary.    

It says `non-forced` .    
```
2023-06-09-20.26.08.204400-420 I367560E454           LEVEL: Info
PID     : 255662               TID : 139733690738432 PROC : db2sysc 0
INSTANCE: v11580               NODE : 000            DB   : HADRDB
HOSTNAME: pcmk1.fyre.ibm.com
EDUID   : 128                  EDUNAME: db2hadrp.0.1 (HADRDB) 0
FUNCTION: DB2 UDB, High Availability Disaster Recovery, hdrPriTkHandleInitialRequest, probe:56040
MESSAGE : Primary has started non-forced takeover request.
```

```
2023-06-09-20.26.08.238097-420 E368015E479           LEVEL: Event
PID     : 255662               TID : 139733749458688 PROC : db2sysc 0
INSTANCE: v11580               NODE : 000            DB   : HADRDB
APPHDL  : 0-24708              APPID: *LOCAL.DB2.230610032608
HOSTNAME: pcmk1.fyre.ibm.com
EDUID   : 143                  EDUNAME: db2agnti (HADRDB) 0
FUNCTION: DB2 UDB, base sys utilities, sqeDBMgr::StartUsingLocalDatabase, probe:13
START   : Received TAKEOVER HADR command.

...
2023-06-09-20.26.10.655241-420 E380152E504           LEVEL: Event
PID     : 255662               TID : 139733724292864 PROC : db2sysc 0
INSTANCE: v11580               NODE : 000            DB   : HADRDB
APPHDL  : 0-24710              APPID: *LOCAL.DB2.230610032610
HOSTNAME: pcmk1.fyre.ibm.com
EDUID   : 144                  EDUNAME: db2agent (HADRDB) 0
FUNCTION: DB2 UDB, High Availability Disaster Recovery, hdrSetHdrState, probe:10000
CHANGE  : HADR state set to HDR_S_PEER (was HDR_P_PEER), connId=1
```

When take over back to original primary.   

```
2023-06-09-20.32.39.522612-420 E419524E513           LEVEL: Event
PID     : 255662               TID : 139733694932736 PROC : db2sysc 0
INSTANCE: v11580               NODE : 000            DB   : HADRDB
APPHDL  : 0-24715              APPID: *LOCAL.v11580.230610033239
AUTHID  : V11580               HOSTNAME: pcmk1.fyre.ibm.com
EDUID   : 149                  EDUNAME: db2agent (HADRDB) 0
FUNCTION: DB2 UDB, base sys utilities, sqeDBMgr::StartUsingLocalDatabase, probe:13
START   : Received TAKEOVER HADR command.  

2023-06-09-20.32.41.901131-420 E452366E448           LEVEL: Event
PID     : 255662               TID : 139733690738432 PROC : db2sysc 0
INSTANCE: v11580               NODE : 000            DB   : HADRDB
HOSTNAME: pcmk1.fyre.ibm.com
EDUID   : 128                  EDUNAME: db2hadrs.0.0 (HADRDB) 0
FUNCTION: DB2 UDB, High Availability Disaster Recovery, hdrSetHdrState, probe:10000
CHANGE  : HADR state set to HDR_P_PEER (was HDR_S_PEER), connId=1
```

Some other expected pattern.    
`Master` was on `pcmk2`.    
```
2023-06-09-20.32.42.215187-420 I452815E697           LEVEL: Event
PID     : 1759557              TID : 140691770255232 PROC : db2havend (db2ha)
INSTANCE: v11580               NODE : 000
HOSTNAME: pcmk1.fyre.ibm.com
FUNCTION: DB2 Common, Pacemaker, db2CMVendorPCMKExecute, probe:409
DATA #1 : String, 22 bytes
/usr/sbin/crm_resource
DATA #2 : String, 44 bytes
--resource db2_v11580_v11580_HADRDB --locate
DATA #3 : String, 0 bytes
Object not dumped: Address: 0x00007FFE3A8A9D80 Size: 0 Reason: Zero-length data
DATA #4 : String, 117 bytes
resource db2_v11580_v11580_HADRDB is running on: pcmk2 Master  <==
resource db2_v11580_v11580_HADRDB is running on: pcmk1
DATA #5 : signed integer, 4 bytes
1759558
```

Updating by `attrd_updater`.     
```
2023-06-09-20.32.42.336106-420 I453513E638           LEVEL: Event
PID     : 1759559              TID : 140232270264192 PROC : db2havend (db2ha)
INSTANCE: v11580               NODE : 000
HOSTNAME: pcmk1.fyre.ibm.com
FUNCTION: DB2 Common, Pacemaker, db2CMVendorPCMKExecute, probe:409
DATA #1 : String, 23 bytes
/usr/sbin/attrd_updater
DATA #2 : String, 43 bytes
-n db2hadr-v11580_v11580_HADRDB -Q -N pcmk1
DATA #3 : String, 0 bytes
Object not dumped: Address: 0x00007FFCEAD94C10 Size: 0 Reason: Zero-length data
DATA #4 : String, 59 bytes
name="db2hadr-v11580_v11580_HADRDB" host="pcmk1" value="1"
DATA #5 : signed integer, 4 bytes
1759560

...

2023-06-09-20.32.53.605528-420 I466932E638           LEVEL: Event
PID     : 1759559              TID : 140232270264192 PROC : db2havend (db2ha)
INSTANCE: v11580               NODE : 000
HOSTNAME: pcmk1.fyre.ibm.com
FUNCTION: DB2 Common, Pacemaker, db2CMVendorPCMKExecute, probe:409
DATA #1 : String, 23 bytes
/usr/sbin/attrd_updater
DATA #2 : String, 43 bytes
-n db2hadr-v11580_v11580_HADRDB -Q -N pcmk1
DATA #3 : String, 0 bytes
Object not dumped: Address: 0x00007FFCEAD94C10 Size: 0 Reason: Zero-length data
DATA #4 : String, 59 bytes
name="db2hadr-v11580_v11580_HADRDB" host="pcmk1" value="2"
DATA #5 : signed integer, 4 bytes
1760447

2023-06-09-20.32.54.170050-420 I467571E873           LEVEL: Event
PID     : 1759559              TID : 140232270264192 PROC : db2havend (db2ha)
INSTANCE: v11580               NODE : 000
HOSTNAME: pcmk1.fyre.ibm.com
FUNCTION: DB2 Common, Pacemaker, db2CMVendorPCMKExecute, probe:409
DATA #1 : String, 22 bytes
/usr/sbin/crm_resource
DATA #2 : String, 92 bytes
--resource db2_v11580_v11580_HADRDB --set-parameter is-managed --meta --parameter-value true
DATA #3 : String, 0 bytes
Object not dumped: Address: 0x00007FFCEAD95DD0 Size: 0 Reason: Zero-length data
DATA #4 : String, 245 bytes
Performing update of 'is-managed' on 'db2_v11580_v11580_HADRDB-clone', the parent of 'db2_v11580_v11580_HADRDB'
Set 'db2_v11580_v11580_HADRDB-clone' option: id=db2_v11580_v11580_HADRDB-clone-meta_attributes-is-managed name=is-managed value=true
DATA #5 : signed integer, 4 bytes
1760448

2023-06-09-20.32.54.170651-420 I468445E1589          LEVEL: Event
PID     : 255662               TID : 139733690738432 PROC : db2sysc 0
INSTANCE: v11580               NODE : 000            DB   : HADRDB
HOSTNAME: pcmk1.fyre.ibm.com
EDUID   : 128                  EDUNAME: db2hadrs.0.0 (HADRDB) 0
FUNCTION: DB2 UDB, high avail services, sqlhaPcmkEnableHADRResource, probe:221
DATA #1 : String, 22 bytes
HADR Resource enabled.
DATA #2 : String, 24 bytes
db2_v11580_v11580_HADRDB
DATA #3 : String, 6 bytes
v11580
DATA #4 : String, 6 bytes
v11580
DATA #5 : String, 6 bytes
HADRDB
DATA #6 : String, 28 bytes
db2hadr-v11580_v11580_HADRDB
DATA #7 : unsigned integer, 8 bytes
21
CALLSTCK: (Static functions may not be resolved correctly, as they are resolved to the nearest symbol)
  [0] 0x00007F165D9835F2 sqlhaPcmkEnableHADRResource + 0xCF2
  [1] 0x00007F165D977EE4 _Z43sqlhaEnableClusterAutomationForHADRResourceP16sqeLocalDatabaseP19SQLHA_CONTROL_BLOCKb + 0xB94
  [2] 0x00007F165D8768AA _ZN8HDR_DBCB14hdrSetHdrStateE9HDR_STATE + 0xA4A
  [3] 0x00007F165D8FD109 _Z26hdrStbyTkHandlePrimaryDoneP6hdrEduP8HDR_DBCB + 0x1519
  [4] 0x00007F165D90820B _ZN6hdrEdu14hdrSDoTakeoverEP20HDR_MESSAGE_TAKEOVERP17HDR_RQST_TAKEOVER + 0x9FB
  [5] 0x00007F165D8C233B _ZN6hdrEdu7hdrEduSEPm + 0x28EB
  [6] 0x00007F165D8C368C _ZN6hdrEdu11hdrEduEntryEv + 0xD1C
  [7] 0x00007F165D8C4C57 _ZN6hdrEdu6RunEDUEv + 0x27
  [8] 0x00007F1667E43E64 _ZN9sqzEDUObj9EDUDriverEv + 0x1A4
  [9] 0x00007F16660B4209 sqloEDUEntry + 0x2A9
  [10] 0x00007F166CE2E1CA /lib64/libpthread.so.0 + 0x81CA
  [11] 0x00007F165A10DE73 clone + 0x43

2023-06-09-20.32.54.198631-420 I470035E576           LEVEL: Event
PID     : 255662               TID : 139733690738432 PROC : db2sysc 0
INSTANCE: v11580               NODE : 000            DB   : HADRDB
HOSTNAME: pcmk1.fyre.ibm.com
EDUID   : 128                  EDUNAME: db2hadrs.0.0 (HADRDB) 0
FUNCTION: DB2 UDB, high avail services, sqlhaEnableClusterAutomationForHADRResource, probe:15373
MESSAGE : HADR enable/unlock resource action
DATA #1 : Codepath, 8 bytes
3
DATA #2 : String, 0 bytes
Object not dumped: Address: 0x00007F1648FD2E20 Size: 0 Reason: Zero-length data
```

[Go to content](#contents) 

### /var/log/pacemaker/pacemaker.log   

```
Jun 09 20:26:20.658 pcmk1.fyre.ibm.com pacemaker-attrd     [730741] (attrd_peer_update)         notice: Setting master-db2_v11580_v11580_HADRDB[pcmk1]: 10000 -> 8000 | from pcmk1
Jun 09 20:26:20.659 pcmk1.fyre.ibm.com pacemaker-based     [730738] (cib_process_request)       info: Forwarding cib_modify operation for section status to all (origin=local/attrd/24)
Jun 09 20:26:20.662 pcmk1.fyre.ibm.com pacemaker-attrd     [730741] (write_attribute)   info: Sent CIB request 24 with 2 changes for master-db2_v11580_v11580_HADRDB (id n/a, set n/a)
Jun 09 20:26:20.668 pcmk1.fyre.ibm.com pacemaker-based     [730738] (cib_perform_op)    info: Diff: --- 0.44.0 2
Jun 09 20:26:20.668 pcmk1.fyre.ibm.com pacemaker-based     [730738] (cib_perform_op)    info: Diff: +++ 0.44.1 (null)
Jun 09 20:26:20.668 pcmk1.fyre.ibm.com pacemaker-based     [730738] (cib_perform_op)    info: +  /cib:  @num_updates=1
Jun 09 20:26:20.668 pcmk1.fyre.ibm.com pacemaker-based     [730738] (cib_perform_op)    info: +  /cib/status/node_state[@id='1']/transient_attributes[@id='1']/instance_attributes[@id='status-1']/nvpair[@id='status-1-master-db2_v11580_v11580_HADRDB']:  @value=8000
Jun 09 20:26:20.668 pcmk1.fyre.ibm.com pacemaker-based     [730738] (cib_process_request)       info: Completed cib_modify operation for section status: OK (rc=0, origin=pcmk1/attrd/24, version=0.44.1)
Jun 09 20:26:20.669 pcmk1.fyre.ibm.com pacemaker-attrd     [730741] (attrd_cib_callback)        info: CIB update 24 result for master-db2_v11580_v11580_HADRDB: OK | rc=0
Jun 09 20:26:20.669 pcmk1.fyre.ibm.com pacemaker-attrd     [730741] (attrd_cib_callback)        info: * master-db2_v11580_v11580_HADRDB[pcmk2]=8000
Jun 09 20:26:20.669 pcmk1.fyre.ibm.com pacemaker-attrd     [730741] (attrd_cib_callback)        info: * master-db2_v11580_v11580_HADRDB[pcmk1]=8000
Jun 09 20:26:20.669 pcmk1.fyre.ibm.com pacemaker-controld  [730743] (abort_transition_graph)    info: Transition 4257 aborted by status-1-master-db2_v11580_v11580_HADRDB doing modify master-db2_v11580_v11580_HADRDB=8000: Transient attribute change | cib=0.44.1 source=abort_unless_down:314 path=/cib/status/node_state[@id='1']/transient_attributes[@id='1']/instance_attributes[@id='status-1']/nvpair[@id='status-1-master-db2_v11580_v11580_HADRDB'] complete=true
Jun 09 20:26:20.670 pcmk1.fyre.ibm.com pacemaker-controld  [730743] (do_state_transition)       notice: State transition S_IDLE -> S_POLICY_ENGINE | input=I_PE_CALC cause=C_FSA_INTERNAL origin=abort_transition_graph
Jun 09 20:26:20.694 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (determine_online_status)   info: Node pcmk1 is online
Jun 09 20:26:20.695 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (determine_online_status)   info: Node pcmk2 is online
Jun 09 20:26:20.695 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (determine_op_status)       info: Probe found db2_pcmk1_v11580_0 active on pcmk1 at Jun  6 22:00:52 2023
Jun 09 20:26:20.695 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (determine_op_status)       info: Probe found db2_pcmk1_v11580_0 active on pcmk1 at Jun  6 22:00:52 2023
Jun 09 20:26:20.696 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (determine_op_status)       info: Probe found db2_v11580_v11580_HADRDB:0 active on pcmk1 at Jun  6 22:37:38 2023
Jun 09 20:26:20.696 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (determine_op_status)       info: Probe found db2_pcmk2_v11580_0 active on pcmk2 at Jun  6 22:35:10 2023
Jun 09 20:26:20.696 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (determine_op_status)       info: Probe found db2_pcmk2_v11580_0 active on pcmk2 at Jun  6 22:35:10 2023
Jun 09 20:26:20.697 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (determine_op_status)       info: Probe found db2_v11580_v11580_HADRDB:1 active on pcmk2 at Jun  6 22:37:38 2023
Jun 09 20:26:20.697 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (determine_op_status)       info: Probe found db2_v11580_v11580_HADRDB:1 active on pcmk2 at Jun  6 22:37:38 2023
Jun 09 20:26:20.698 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (pcmk__set_instance_roles)  info: Promoting db2_v11580_v11580_HADRDB:0 (Master pcmk1)
Jun 09 20:26:20.698 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (pcmk__set_instance_roles)  info: db2_v11580_v11580_HADRDB-clone: Promoted 1 instances of a possible 1
Jun 09 20:26:20.698 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (rsc_action_default)        info: Leave   db2_pcmk1_eth0    (Started pcmk1)
Jun 09 20:26:20.698 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (rsc_action_default)        info: Leave   db2_pcmk2_eth0    (Started pcmk2)
Jun 09 20:26:20.698 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (rsc_action_default)        info: Leave   db2_pcmk1_v11580_0        (Started pcmk1)
Jun 09 20:26:20.698 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (rsc_action_default)        info: Leave   db2_pcmk2_v11580_0        (Started pcmk2)
Jun 09 20:26:20.699 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (rsc_action_default)        info: Leave   db2_v11580_v11580_HADRDB:0        (Master pcmk1)
Jun 09 20:26:20.699 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (rsc_action_default)        info: Leave   db2_v11580_v11580_HADRDB:1        (Slave pcmk2)
Jun 09 20:26:20.699 pcmk1.fyre.ibm.com pacemaker-schedulerd[730742] (pcmk__log_transition_summary)      notice: Calculated transition 4258, saving inputs in /var/lib/pacemaker/pengine/pe-input-36.bz2
Jun 09 20:26:20.700 pcmk1.fyre.ibm.com pacemaker-controld  [730743] (do_state_transition)       info: State transition S_POLICY_ENGINE -> S_TRANSITION_ENGINE | input=I_PE_SUCCESS cause=C_IPC_MESSAGE origin=handle_response
Jun 09 20:26:20.700 pcmk1.fyre.ibm.com pacemaker-controld  [730743] (do_te_invoke)      info: Processing graph 4258 (ref=pe_calc-dc-1686367580-5650) derived from /var/lib/pacemaker/pengine/pe-input-36.bz2
Jun 09 20:26:20.700 pcmk1.fyre.ibm.com pacemaker-controld  [730743] (pcmk__execute_graph)       notice: Transition 4258 (Complete=0, Pending=0, Fired=0, Skipped=0, Incomplete=0, Source=/var/lib/pacemaker/pengine/pe-input-36.bz2): Complete
Jun 09 20:26:20.700 pcmk1.fyre.ibm.com pacemaker-controld  [730743] (do_log)    info: Input I_TE_SUCCESS received in state S_TRANSITION_ENGINE from notify_crmd
Jun 09 20:26:20.700 pcmk1.fyre.ibm.com pacemaker-controld  [730743] (do_state_transition)       notice: State transition S_TRANSITION_ENGINE -> S_IDLE | input=I_TE_SUCCESS cause=C_FSA_INTERNAL origin=notify_crmd
Jun 09 20:26:25.673 pcmk1.fyre.ibm.com pacemaker-based     [730738] (cib_process_ping)  info: Reporting our current digest to pcmk1: c6d24a9eeb32cd92099f13304a11f550 for 0.44.1 (0x55974aa5edf0 0)
...
Jun 09 20:26:30.380 pcmk1.fyre.ibm.com pacemaker-attrd     [730741] (attrd_peer_update)         notice: Setting db2hadr-v11580_v11580_HADRDB[pcmk2]: 1 -> 2 | from pcmk2
```

- [Go to content](#contents)

## Add VIP when it's not set yet       

```
[root@pcmk1 pacemaker]# ping 10.11.113.222
PING 10.11.113.222 (10.11.113.222) 56(84) bytes of data.
^C
--- 10.11.113.222 ping statistics ---
3 packets transmitted, 0 received, 100% packet loss, time 2047ms

[root@pcmk1 pacemaker]# /home/v11580/sqllib/bin/db2cm -create -primaryVIP 10.11.113.222 -db hadrdb -instance v11580
Primary VIP resource created successfully.
[root@pcmk1 pacemaker]# crm status
Cluster Summary:
  * Stack: corosync
  * Current DC: pcmk1 (version 2.1.2-4.db2pcmk.el8-ada5c3b36e2) - partition with quorum
  * Last updated: Fri Jun  9 21:22:54 2023
  * Last change:  Fri Jun  9 21:22:47 2023 by root via cibadmin on pcmk1
  * 2 nodes configured
  * 7 resource instances configured

Node List:
  * Online: [ pcmk1 pcmk2 ]

Full List of Resources:
  * db2_pcmk1_eth0	(ocf::heartbeat:db2ethmon):	 Started pcmk1
  * db2_pcmk2_eth0	(ocf::heartbeat:db2ethmon):	 Started pcmk2
  * db2_pcmk1_v11580_0	(ocf::heartbeat:db2inst):	 Started pcmk1
  * db2_pcmk2_v11580_0	(ocf::heartbeat:db2inst):	 Started pcmk2
  * Clone Set: db2_v11580_v11580_HADRDB-clone [db2_v11580_v11580_HADRDB] (promotable):
    * Masters: [ pcmk1 ]
    * Slaves: [ pcmk2 ]
  * db2_v11580_v11580_HADRDB-primary-VIP	(ocf::heartbeat:IPaddr2):	 Started pcmk1
```

IP is added to the interface.    
```
[root@pcmk1 pacemaker]# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:00:0a:0b:71:6e brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    altname ens3
    inet 10.11.113.110/20 brd 10.11.127.255 scope global dynamic noprefixroute eth0
       valid_lft 32200sec preferred_lft 32200sec
    inet 10.11.113.222/20 brd 10.11.127.255 scope global secondary eth0      <========
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:20:09:1e:6c:81 brd ff:ff:ff:ff:ff:ff
    altname enp0s7
    altname ens7
    inet 9.30.108.129/23 brd 9.30.109.255 scope global dynamic noprefixroute eth1
       valid_lft 32200sec preferred_lft 32200sec
```    

Takeover test. VIP moved.        
```
[v11580@pcmk2 ~]$ db2 takeover hadr on db hadrdb
DB20000I  The TAKEOVER HADR ON DATABASE command completed successfully.
[v11580@pcmk2 ~]$ exit
logout
[root@pcmk2 ~]# crm status
Cluster Summary:
  * Stack: corosync
  * Current DC: pcmk1 (version 2.1.2-4.db2pcmk.el8-ada5c3b36e2) - partition with quorum
  * Last updated: Fri Jun  9 21:28:55 2023
  * Last change:  Fri Jun  9 21:22:47 2023 by root via cibadmin on pcmk1
  * 2 nodes configured
  * 7 resource instances configured

Node List:
  * Online: [ pcmk1 pcmk2 ]

Full List of Resources:
  * db2_pcmk1_eth0	(ocf::heartbeat:db2ethmon):	 Started pcmk1
  * db2_pcmk2_eth0	(ocf::heartbeat:db2ethmon):	 Started pcmk2
  * db2_pcmk1_v11580_0	(ocf::heartbeat:db2inst):	 Started pcmk1
  * db2_pcmk2_v11580_0	(ocf::heartbeat:db2inst):	 Started pcmk2
  * Clone Set: db2_v11580_v11580_HADRDB-clone [db2_v11580_v11580_HADRDB] (promotable):
    * Masters: [ pcmk2 ]
    * Slaves: [ pcmk1 ]
  * db2_v11580_v11580_HADRDB-primary-VIP	(ocf::heartbeat:IPaddr2):	 Started pcmk2  <===
```

- [Go to content](#Contents)
 