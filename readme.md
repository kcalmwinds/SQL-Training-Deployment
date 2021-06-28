# **Training Environment for SQL Server**

---

## **How To Use This Package**

---

```git
git clone https://github.com/kcalmwinds/SQL-Training-Deployment.git
```

---

### **What's Inside?**

---

An HTML Version of these instructions are located in .\readme of this package if you are working locally.

This package is to be used for deploying 4 servers.

| Purpose                           | Name    | IP       | IP Type |
| --------------------------------- | ------- | -------- | ------- |
| A DNS Server                      | SQLDCVM | 10.2.0.4 | Static  |
| SQL Server 2019 Developer Edition | SQLVM1  | 10.2.0.5 | Static  |
| SQL Server 2019 Developer Edition | SQLVM2  | 10.2.0.6 | Static  |
| SQL Server 2019 Developer Edition | SQLVM3  | 10.2.0.7 | Static  |

- Bastion for VM access
- VNET

  - default subnet
  - subnet for Bastion
  - preconfigured DNS entry for 10.2.0.4
  - 3 SQLVM Resource Providers
  - 1 Availability Set for all 3 SQL Servers

- Powershell script to install AzureCLI on your local machine
- Script to create the DC and AD for SQLTRAIN.com
- Script to join the SQLTRAIN domain
- a basic configuration script for SQL configuration
  - Firewall Rules for ports
    - 1433
    - 5022
    - 59999 - healthprobe
  - Install latest SQLSERVER cmdlets
  - Install AzureCLI
  - Install Google Chrome to bypass IE Security to get other tools
  - Creates Windows login for SQLVM1, 2, and 3 and makes them SA on all SQL Server Instances
  - Enables TCP for SQL Server (Developer default is disabled)
  - Creates a directory C:\Adventureworks and Downloads Adventureworks2017.bak
  - Creates a folder C:\snapshot _for replications practice_

---

---

### **What You Need To Know**

---

This deployment does not attach any disks or preconfigure stripting. Each VM deploys with the OS disk sized at 1tb. Though data disks are not attached, there is nothing stopping an engineer from practicing how to work with Storage Spaces and Deploying Azure Managed Disks to do striping exercises.

SQL VM agent is installed but it is only configured enough to access SQL Server to configure connectivity private within vnet, port 1433 open, and configure SQL Login to adminuser/Password123!.

> With the above written, this is not meant to host or contain actual user data. If you do use this environment for production or reproduction purposes, **CHANGE THE USERNAME AND PASSWORD IN THE PARAMETER FILE**

```JSON
{
  "osAndSQLLogin": {
    "value": "adminuser"
  },
  "osandSQLPw": {
    "value": "Password123!"
  }
}
```

Bastion connectivity was implemented due to policy pushed to deployments in some organizations creating very restrictive Network Security Group rules that make it very difficult to use RDP. Bastion bypasses all of that and hosts the RDP session directly in the browser through the Azure portal.

With Bastion, you can only copy and paste text to and from your local machine to the remote machine and back. It shares a clipboard. There will be some steps where you will do exactly this and when using hte DNS configuration file, you will need to copy the contents of the XML file locally into a new xml file on the remote machine.

---

### **Steps**

---

All steps will take place in the folder you cloned this repository to.

---

---

#### **1 Install Azure CLI**

---

Open up a powershell process in administrator mode and run the following.

```powershell
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
```

---

#### **2 templates\ deploy 4 servers using deploy.azcli**

---

From the root of the clone directory using Administrative PowerShell window:

```
az group create -g SqlTrainRG -l centralus
az deployment group create -g sqlTrainRG -f .\templates\template.json -p .\templates\parameters.json
```

The entire process takes about 20 minutes if you monitor the resource group deployment from the portal. Most of that time is Bastion deploying and configuring itself.

Once the deployment is complete, open a Bastion session to **SQLDCVM, SQL1VM, SQL2VM, and SQL3VM**

---

#### **3 create_dns_ad\\ : Create DC/AD**

---

In your Bastion session to **SQLDCVM**, create a text file then copy and paste the contents of ./create_dns_ad/DNSConfigTemplate.xml into the new text file and save it. Change the .txt extension to .xml. You may have use the view ribbon in File Explorer to enable showing extensions to properly change it.

Open an administrative PowerShell console on **SQLDCVM** and run:

```powershell
#to be run on the to-be domain controller
Install-WindowsFeature -ConfigurationFilePath DNSConfigTemplate.xml
#
# Windows PowerShell script for AD DS Deployment
#
$securepass = ConvertTo-SecureString "Password123!" -AsPlainText -Force
Import-Module ADDSDeployment
Install-ADDSForest `
    -SafeModeAdministratorPassword $securepass `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\windows\NTDS" `
    -DomainMode "WinThreshold" `
    -DomainName "sqltrain.com" `
    -DomainNetbiosName "SQLTRAIN" `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -LogPath "C:\windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\windows\SYSVOL" `
    -Force:$true
```

This will configure the DNS and setup the AD forest SQLTRAIN.

You will see a connection lost message from bastion but let it continue to reconnect. Once Bastion is connected to **SQLDCVM** again, you can begin domain joining the SQL VMs.

---

#### **4 add_to_domain\\ : Add SQL Nodes to AD**

---

In your Bastions sessions to the SQLVM servers, open up an administrative PowerShell console and run the following:

```powershell
Add-Computer -DomainName sqltrain.com -Credential sqltrain\adminuser -Restart
```

It will prompt you for the password. Enter it and the VM will restart. Do not close your Bastion session. The next section can only be done as the local admin of the server. Once the Bastion session is reconnected, proceed to step 5

---

#### **5 sqlconfigure\\ Configuring SQL On All Nodes**

---

This is where the majority of the configuration happens. You will find all the things this powershell does at the top of the document. Open up an administrator PowerShell console and run the following.

```powershell
# If you modified the ARM template in any way, please adjust the appropriate commands below


#get adventureworks2017
mkdir c:\adventureworks
Invoke-WebRequest -Uri https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2017.bak -OutFile c:\adventureworks\AdventureWorks2017.bak


#use this to install azure cli
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi


# Firewall Rules
New-NetFirewallRule -DisplayName "SQLEndpoint" -Direction Inbound -protocol TCP -LocalPort 1433  -Action Allow -Enabled True
New-NetFirewallRule -DisplayName "SQLHADREndpoint" -Direction Inbound  -protocol TCP -LocalPort 5022  -Action Allow -Enabled True
New-NetFirewallRule -DisplayName "Healthprobe" -Direction Inbound -protocol TCP -LocalPort 59999 -Action Allow -Enabled True


# latest sqlserver cmdlets
install-module sqlserver -AllowClobber -Force


#after domain join, needs to be done under local adminuser acct -  run powershell as adminuser to do this or login as adminuser.
Invoke-Sqlcmd -Database "master" -Query "CREATE LOGIN [SQLTRAIN\adminuser] FROM WINDOWS WITH DEFAULT_DATABASE=[master]" -ServerInstance "."
Invoke-Sqlcmd -Database "master" -Query "ALTER SERVER ROLE [sysadmin] ADD MEMBER [SQLTRAIN\adminuser]" -ServerInstance "."
Invoke-Sqlcmd -Database "master" -Query "CREATE LOGIN [SQLTRAIN\SQL2VM$] FROM WINDOWS WITH DEFAULT_DATABASE=[master]" -ServerInstance "."
Invoke-Sqlcmd -Database "master" -Query "CREATE LOGIN [SQLTRAIN\SQL1vm$] FROM WINDOWS WITH DEFAULT_DATABASE=[master]" -ServerInstance "."
Invoke-Sqlcmd -Database "master" -Query "CREATE LOGIN [SQLTRAIN\SQL3vm$] FROM WINDOWS WITH DEFAULT_DATABASE=[master]" -ServerInstance "."
Invoke-Sqlcmd -Database "master" -Query "ALTER SERVER ROLE [sysadmin] ADD MEMBER [SQLTRAIN\SQL2VM$]" -ServerInstance "."
Invoke-Sqlcmd -Database "master" -Query "ALTER SERVER ROLE [sysadmin] ADD MEMBER [SQLTRAIN\SQL1vm$]" -ServerInstance "."
Invoke-Sqlcmd -Database "master" -Query "ALTER SERVER ROLE [sysadmin] ADD MEMBER [SQLTRAIN\SQL3vm$]" -ServerInstance "."


#make directory for snapshots -- replication stuff
mkdir c:\snapshot


#grab chrome to bypass IE security
$LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object    System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor = "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ? { $Process2Monitor -contains $_.Name } | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)


# Get access to SqlWmiManagement DLL on the machine with SQL
# we are on, which is where SQL Server was installed.
# Note: this is installed in the GAC by SQL Server Setup.

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement')

# Instantiate a ManagedComputer object which exposes primitives to control the
# installation of SQL Server on this machine.

$wmi = New-Object 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' localhost

# Enable the TCP protocol on the default instance. If the instance is named,
# replace MSSQLSERVER with the instance name in the following line.

$tcp = $wmi.ServerInstances['MSSQLSERVER'].ServerProtocols['Tcp']
$tcp.IsEnabled = $true
$tcp.Alter()

# You need to restart SQL Server for the change to persist
# -Force takes care of any dependent services, like SQL Agent.
# Note: if the instance is named, replace MSSQLSERVER with MSSQL$ followed by
# the name of the instance (e.g. MSSQL$MYINSTANCE)

Restart-Service -Name MSSQLSERVER -Force
```

That's it! Everything else is going to come down what it is you are training with. Classic mirroring, Log Shipping, Availability Groups, Failover Cluster Instances, replication...
this will meet the needs of just about anything you could want. If you get fancy, you can deploy it twice and work with Distributed Availability Groups.

This template was designed with speed of infrastructure deployment in mind. I have provided some basic scripts to accelerate domain configuration. Everything else is up to you!

---

## **I'm Done! Now What?**

This is the easy part. Simply destroy the entire resource group.

```
az group delete -g SqlTrainRG -y
```

It does not need to be monitored. Destroying the resource group will destroy all deployed resources. This follows the model of:

- Deploy It
- Configure It
- Reproduce It
- Destroy it

Now that you have walked through it, lets cut out some of the work:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fkcalmwinds%2FSQL-Training-Deployment%2Fmain%2Ftemplates%2Ftemplate.json)

### **Contributors**

---

Mark Cameron - MARKCAME - MARKCAME@microsoft.com

---

#### **Tools used**

---

| Tool         | Who has it            | How to get it                              |
| ------------ | --------------------- | ------------------------------------------ |
| VSCode       | Microsoft             | [DOWNLOAD](https://code.visualstudio.com/) |
| genterate-md | NPM : markdown-styles | `npm install -g markdown-styles`           |
