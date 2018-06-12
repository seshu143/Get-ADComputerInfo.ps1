# Requires the following component is installed:
# Remote Server Administration Tools > Active Directory Module for Powershell
# Nash Pherson 2017-03-15
# 

# Set the name of the output CSV file...
$output = "CompList-$(get-date -f yyyy-MM-dd-hh.mm.ss).csv"

# Check to see if ActiveDirectory Module is installed...
If (!(Get-Module -ListAvailable -Name ActiveDirectory))
    {
        # No AD Module installed... End user needs to install RSAT first
        If ([System.Environment]::OSVersion.Version.Build -lt 17682) {
            Write-Warning "To use this script, you must install the Active Directory Module for PowerShell (part of RSAT).";Break
        }
 
        # No AD Module installed... Try to install it via Features on Demand (Win 10 Build 17682 and above)
        Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
        If (!(Get-Module -ListAvailable -Name ActiveDirectory)) {
            Write-Warning "To use this script, you must install the Active Directory Module for PowerShell. Could not install RSAT for you.";Break
        }
    }   

# Load the ActiveDirctory module...
If (!(Get-Module ActiveDirectory)) {Import-Module ActiveDirectory}

# Enumerate domains this user/device can see...
$Domains = (Get-ADForest).Domains

# Find all computer objects from all domains...
$AllComputers = @()
Foreach ($i in $Domains)
    {
        $Computers = Get-ADComputer -Filter {OperatingSystem -Like "*Windows*"} -Server $i -Properties lastlogontimestamp,enabled,operatingSystem,operatingSystemVersion,operatingSystemServicePack,distinguishedName,description | `
        select-object Name,@{Name="lastLogonTimestamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}},Enabled,operatingSystem,operatingSystemVersion,operatingSystemServicePack,distinguishedName,Description,@{Name="Domain"; Expression={$i}}
        $AllComputers += $Computers
    }

# Write computer object data to CSV file...
$AllComputers | Export-CSV $output -NoClobber -NoTypeInformation