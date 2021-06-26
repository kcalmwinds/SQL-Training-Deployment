

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
