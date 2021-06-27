# **Training Environment for SQL Server**

---

## **How To Use This Package**

---

### **What's Inside?**

---

An HTML Version of these instructions are located in [.\readme](.\readme\readme.html) of this package if you are working locally.

This package is to be used for deploying 4 servers.

| Purpose                           | Name    | IP       | IP Type |
| --------------------------------- | ------- | -------- | ------- |
| A DNS Server                      | SQLDCVM | 10.2.0.4 | Static  |
| SQL Server 2019 Developer Edition | SQLVM1  | 10.2.0.5 | Static  |
| SQL Server 2019 Developer Edition | SQLVM2  | 10.2.0.6 | Static  |
| SQL Server 2019 Developer Edition | SQLVM3  | 10.2.0.7 | Static  |

- Bastion for VM access due to corp policy
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
  - Creates login for SQLVM1, 2, and 3 and makes them SA on all SQL Server Instances
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

#### **2 templates\ deploy 4 servers using deploy.azcli**

---

From the root of the clone directory using Administrative PowerShell window:

```
az group create -g SqlTrainRG -l centralus
az deployment group create -g sqlTrainRG -f .\templates\template.json -p .\templates\parameters.json
```

The entire process takes about 20 minutes if you monitor the resource group deployment from the portal. Most of that time is Bastion deploying and configuring itself.

---

#### **3 Create DC/AD using create_dns_ad\\**

---

stuff

---

#### **4 Add SQL Nodes to AD using add_to_domain\\**

---

stuff

---

#### **5 Configuring SQL On All Nodes Using sqlconfigure\\**

---

stuff

---

## I'm Done! Now What?

This is the easy part. Simply destroy the entire resource group.

```
az group delete -g SqlTrainRG -y
```

It does not need to be monitored. Destroying the resource group will destroy all deployed resources. This follows the model of:

- Deploy It
- Configure It
- Reproduce It
- Destroy it

### **Contributors**

Mark Cameron - MARKCAME - MARKCAME@microsoft.com
