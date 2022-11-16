<#
.SYNOPSIS
    
    Checks for broken accounts or "SIDS" in groups, namely the local administrators group
.DESCRIPTION
    
    The primary purpose of this script is to fix the Get-LocalGroupMember powershell cmndlet when a machine is dis-joined from an Active Directory domain, then joined to an AzureAD domain.
    
    This will typically leave SIDS from the previous domain on the computer that may not show up when looking through computer management or through the traditional "net user" command.
    
    I believe that this will also work if a machine is removed from one domain, then moved to a new domain as there are bound to be SIDS from the previous domain still are still present in groups. This has not been tested.

.NOTES

    The script as presented was designed to be deployed through NinjaRMM. Please see example to see how to adapt to non-NinjaRMM deployments.
    
    This does use ADSI to make changes.

    Use at your own risk, I assume no responsibility for how you use this script. 

    I'm no powershell pro, there might be a better way to do this?
    
    Please understand what the script is doing before running.

    After running this script, you 'should' be able to run the Get-LocalGroupMember cmdlet from powershell and it not return an error.

.EXAMPLE
    This was adapted to be deployed through NinjaRMM.
    
    $GroupPath and $GroupName are expecting preset parameters or parameters sent when you run a script from NinjaRMM.

    When deployed through NinjaRMM the paramters should be designed as "WinNT://./Administrators" "Administrators" (with quotes and case sensitive) 

    For example, to check and remove any broken SIDs in the Power Users group you would use "WinNT://./Power Users" "Power Users" as your preset or manual parameters.    
    
    If you're not using NinjaRMM to deploy this script, please adjust the $GroupPath parameter with the full path as above. You can ditch the variable completely if you choose.
    
    Regardless of how you deploy, the (([ADSI]"$GroupPath"). or (([ADSI]"WinNT://./Adminstrators"). IS case-senstive and MUST be wrapped with " "
    
#>

param(
  
    [string]$GroupPath = '',
    [string]$GroupName = '',
    [string]$LocalMachine = "$env:COMPUTERNAME/*",
    [string]$AzDomain = "AzureAD/*",
    [string]$AdDomain = #"DOMAIN/*"#
)


$LocalSids = @(([ADSI]"$GroupPath").psbase.Invoke('Members') | % { $_.GetType().InvokeMember('AdsPath', 'GetProperty', $null, $($_), $null) }) -match '^WinNT';

$LocalSids = $LocalSids -replace "WinNT://", ""

Write-Output "The following SIDS were found in the $GroupPath path."

$LocalSids

Write-Output "Parsing through accounts in the $GroupPath path and removing any that do not match the local machine, AzureAD, or AD domain."

foreach ($LocalSids in $LocalSids) {

    if ($LocalSids -like $LocalMachine -or $LocalSids -like $AzDomain -or $LocalSids -like $AdDomain) {
        continue;
    }

    Remove-LocalGroupMember -group $GroupName -member $LocalSids -Verbose
  
}

Get-LocalGroupMember -Group $GroupName