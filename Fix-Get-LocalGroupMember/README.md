This script 'should' fix the error below when trying to run Get-LocalGroupMember when the machine has be been disjoined from an Active Directory domain, then joined to an AzureAD domain.




```
Get-LocalGroupMember : Failed to compare two elements in the array.
At C:\ProgramData\NinjaRMMAgent\scripting\customscript_gen_17.ps1:74 char:1
+ Get-LocalGroupMember -Group $GroupName
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Get-LocalGroupMember], InvalidOperationException
    + FullyQualifiedErrorId : An unspecified error occurred.,Microsoft.PowerShell.Commands.GetLocalGroupMemberCommand
```

I believe this may also solve 'domain-to-domain' transitions, but I have not tested this.


This was designed to be deployed through NinjaRMM as it sits right now, but can be modified to be deployed normally through powershell. It actually took me longer to get it to work with NinjaRMM than it did to get it working in the first place.


# Ninja RMM Deployment

## Parameters Explained

I recommend using preset paramters so that you don't have to type the parameters out every time you run the script.

If you want to clear the broken SIDs that are in the Administrators group, you would use the following preset parameters

***Note: CaSe SeNsItIvE*** (at least on the first parameter)

```
"WinNT://./Administrators" "Administrators"
```

What is does is sets the two parameters within the script to their respective value.

```
[string]$GroupPath = '', 
[string]$GroupName = '',
```
becomes

```
[string]$GroupPath = "WinNT://./Administrators,
[string]$GroupName = "Administrators,
```

## Creating Parameters in NinjaRMM

Inside the script editor you just need to type out the parameter in the preset parameter section, then click the "+" symbol.

It should look like this:



![Ninja Preset Parameters](/Fix%20Get-LocalGroupMember/Images/PPNinjaRMM.png)


When you deploy the script, you MUST select the appropriate parameters, otherwise the script will not run properly.

![Ninja Launching Script](/Fix%20Get-LocalGroupMember/Images/DeployScript.png)
