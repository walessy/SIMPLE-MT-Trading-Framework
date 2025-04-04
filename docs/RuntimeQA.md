# Best practice for starters
## Running powershell
Open Powershell ISE as administrator

## Some Runtime issues
### 1. 
 File C:\Projetcs\SIMPLE MT-Trading-Framework\Easy-Setup.ps1 cannot be loaded because running scripts is disabled on this system. For more information, see about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170.
    + CategoryInfo          : SecurityError: (:) [], ParentContainsErrorRecordException
    + FullyQualifiedErrorId : UnauthorizedAccess

Running scripts locally is disabled

Solution:
Changing the Execution Policy

1. Temporarily Bypass Execution Policy
    
    To run a script temporarily without changing the policy permanently, use the following command:

    powershell -ExecutionPolicy Bypass -File script.ps1