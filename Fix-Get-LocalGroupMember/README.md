# About the script
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

## Changes that may be required

The following parameter is commented out:

```
[string]$AdDomain = #"DOMAIN/*"#
```
By setting this, it 'should' keep your current AD domain accounts from being removed. I put this in here to account for domain-to-domain transitions or possibly in the case of hybrid. If unsure, leave it commented out.



## Ninja RMM Deployment



### Parameters Explained

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

### Creating Parameters in NinjaRMM

Inside the script editor you just need to type out the parameter in the preset parameter section, then click the "+" symbol.

It should look like this:



![Ninja Preset Parameters](/Fix-Get-LocalGroupMember/Images/PPNinjaRMM.png)


When you deploy the script, you MUST select the appropriate parameters, otherwise the script will not run properly.

![Ninja Launching Script](/Fix-Get-LocalGroupMember/Images/DeployScript.png)


## Example Output from Script

<details><summary>Example 1</summary>

```
Action completed: Run Clear-BrokenSids Result: SUCCESS Output: Action: Run Clear-BrokenSids, Result: Success
The following SIDS were found in the WinNT://./Administrators path.
COMPUTERNAME/Administrator
S-1-5-21-764903313-1875263933-622671684-3771
S-1-5-21-764903313-1875263933-622671684-500
COMPUTERNAME/AnotherAdmin
S-1-12-1-585102207-1128987139-1314167211-2081230094
S-1-12-1-1924940608-1336246390-2787065528-666521730
DOMAIN/volunteer
Parsing through accounts in the WinNT://./Administrators and removing any that do not match the local machine, AzureAD, or AD domain.
VERBOSE: Performing the operation "Remove member S-1-5-21-764903313-1875263933-622671684-3771" on target 
"Administrators".
VERBOSE: Performing the operation "Remove member S-1-5-21-764903313-1875263933-622671684-500" on target 
"Administrators".
VERBOSE: Performing the operation "Remove member S-1-12-1-585102207-1128987139-1314167211-2081230094" on target 
"Administrators".
VERBOSE: Performing the operation "Remove member S-1-12-1-1924940608-1336246390-2787065528-666521730" on target 
"Administrators".


ObjectClass Name                         PrincipalSource
----------- ----                         ---------------
User        DOMAIN\volunteer             AzureAD        
User        COMPUTERNAME\Administrator   Local          
User        COMPUTERNAME\AnotherAdmin    Local          
```

In the example above, the 'volunteer' account does reference the old AD domain under name, but I believe this was due to ADSync being present before the computer was disjoined from AD and rejoined to AzureAD.  It does show the principal source as AzureAD.

New machines don't reference the previous domain as they were never part of it, thus this issue not being present as far as I've been able to tell.

Also, that account is being removed, it was just there as that is the account that did the enrollment. The next step is being able to use Get-LocalGroupMember to remove any extra local admins.
</details>


<details><summary>Example 2</summary>

```
Action completed: Run Clear-BrokenSids Result: SUCCESS Output: Action: Run Clear-BrokenSids, Result: Success
The following SIDS were found in the WinNT://./Administrators path.
COMPUTERNAME/Administrator
S-1-5-21-764903313-1875263933-622671684-3771
S-1-5-21-764903313-1875263933-622671684-500
COMPUTERNAME/AnotherAdmin
S-1-12-1-585102207-1128987139-1314167211-2081230094
S-1-12-1-1924940608-1336246390-2787065528-666521730
AzureAD/AnotherAdmin
Parsing through accounts in the WinNT://./Administrators and removing any that do not match the local machine, AzureAD, or AD domain.
VERBOSE: Performing the operation "Remove member S-1-5-21-764903313-1875263933-622671684-3771" on target 
"Administrators".
VERBOSE: Performing the operation "Remove member S-1-5-21-764903313-1875263933-622671684-500" on target 
"Administrators".
VERBOSE: Performing the operation "Remove member S-1-12-1-585102207-1128987139-1314167211-2081230094" on target 
"Administrators".
VERBOSE: Performing the operation "Remove member S-1-12-1-1924940608-1336246390-2787065528-666521730" on target 
"Administrators".

ObjectClass Name                          PrincipalSource
----------- ----                          ---------------
User        COMPUTERNAME\Administrator    Local          
User        COMPUTERNAME\AnotherAdmin     Local          
User        AzureAD\AnotherAdmin          AzureAD        
```
As you can see in this example, the prevous DOMAIN\ is not listed on the last account. I believe this may be due to this particular domain admin account never logging into this computer so there was no profile that may have been linked in that respect.  I could be wrong though.
</details>
