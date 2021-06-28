# can be run on a single node

import-module FailoverClusters

new-cluster -name 'TrainCluster' -node 'SQL1VM','SQL2VM', 'SQL3VM' -NoStorage -StaticAddress '10.2.0.10' -AdministrativeAccessPoint 'ActiveDirectoryAndDns' -force
test-cluster
