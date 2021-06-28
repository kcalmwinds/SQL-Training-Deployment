# Configure the cluster for Always On

It is a simple step. Open up an administrative PowerShell console on SQL1VM and run:

```powershell
# can be run on a single node

import-module FailoverClusters

new-cluster -name 'TrainCluster' -node 'SQL1VM','SQL2VM', 'SQL3VM' -NoStorage -StaticAddress '10.2.0.10' -AdministrativeAccessPoint 'ActiveDirectoryAndDns' -force
```

The next portion will enable High Availability for the sql instance but service restart may or may not happen.
If it doesnt happen, please use `restart-computer -force` on all of the nodes as restart-service sometimes will not restart. rebooting is faster and accomplishes the same goal.

```powershell
# Not reliable when restarting service.  put in plan to implement service restarting
# use : restart-computer -force : on all nodes
enable-sqlalwayson -ServerInstance "sql1vm" -force
enable-sqlalwayson -ServerInstance "sql2vm" -force
enable-sqlalwayson -ServerInstance "sql3vm" -force
```

Any further configuration would be done by design choice

- what quorum you are going to use
- StorageSpaces or S2D
- DNN or VNN decisions
