

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
