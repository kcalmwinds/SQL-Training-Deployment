# Configure the cluster for Always On

It is a simple step. Open up an administrative PowerShell console on SQL1VM and run:

```powershell
# can be run on a single node

import-module FailoverClusters

new-cluster -name 'TrainCluster' -node 'SQL1VM','SQL2VM', 'SQL3VM' -NoStorage -StaticAddress '10.2.0.10' -AdministrativeAccessPoint 'ActiveDirectoryAndDns' -force
test-cluster
```
