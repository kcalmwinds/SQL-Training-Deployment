# can be run on a single node

import-module FailoverClusters
import-module SqlServer

new-cluster -name 'TrainCluster' -node 'SQL1VM','SQL2VM', 'SQL3VM' -NoStorage -StaticAddress '10.2.0.10' -AdministrativeAccessPoint 'ActiveDirectoryAndDns' -force

# Not reliable when restarting service.  put in plan to implement service restarting 
# use : restart-computer -force : on all nodes
enable-sqlalwayson -ServerInstance "sql1vm" -force
enable-sqlalwayson -ServerInstance "sql2vm" -force
enable-sqlalwayson -ServerInstance "sql3vm" -force


