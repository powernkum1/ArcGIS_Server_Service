# ArcGIS Server Windows Service Restart

PowerShell automation for restarting the **ArcGIS Server Windows
service** on a scheduled basis. It is intended for ArcGIS Enterprise
environments running ArcGIS Server on Windows and can be scheduled
through **Windows Task Scheduler**.

## Purpose

The scripts can:

-   Check the ArcGIS Server Windows service status.
-   Stop and restart the Windows service.
-   Wait for Windows to confirm service state changes.
-   Verify that the service returns to `Running`.
-   Create timestamped execution logs.
-   Send an email notification when a restart fails.
-   Optionally send an email after a successful restart.

This restarts the **Windows service hosting ArcGIS Server**, not
individual MapServer, FeatureServer, or other ArcGIS services.

## Files

``` text
ArcGIS_Server_Service/
├── Restart_ArcGIS_Server_Service.ps1
├── Restart_ArcGIS_Server_Service_Test_commentout.ps1
├── README.md
└── Logs/
```

`Restart_ArcGIS_Server_Service.ps1` is the production script with the
Windows service stop/start operations enabled.

`Restart_ArcGIS_Server_Service_Test_commentout.ps1` is the test version
for validating execution, logging, and email behavior without
intentionally performing the production restart where the stop/start
commands are commented out.

## Requirements

-   Windows Server
-   ArcGIS Server
-   Windows PowerShell
-   An account with permission to stop/start the ArcGIS Server Windows
    service
-   Windows Task Scheduler for scheduled execution
-   Access to an SMTP relay if email notifications are enabled

For Task Scheduler, enable **Run with highest privileges**.

## Email Configuration

Success emails can be controlled with:

``` powershell
$SendSuccessEmail = $false
```

With `$false`, successful runs are logged without sending a success
email. Failure notifications are still sent.

To enable success notifications:

``` powershell
$SendSuccessEmail = $true
```

## Logging

Each execution creates a timestamped log in the configured `Logs`
directory.

Example:

``` text
Logs/
└── ArcGIS_Server_Restart_2026-09-02_14-26-16.log
```

Failure emails can include the corresponding log as an attachment.

## Manual Execution

Run from an elevated Command Prompt or PowerShell session:

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\path\to\ArcGIS_Server_Service\Restart_ArcGIS_Server_Service.ps1"
```

For initial validation:

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\path\to\ArcGIS_Server_Service\Restart_ArcGIS_Server_Service_Test_commentout.ps1"
```

## Windows Task Scheduler

For a biweekly schedule, create a **Weekly** trigger configured to recur
every **2 weeks**.

### Program/script

``` text
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
```

### Arguments

``` text
-NoProfile -ExecutionPolicy Bypass -File "C:\path\to\ArcGIS_Server_Service\Restart_ArcGIS_Server_Service.ps1"
```

Recommended settings:

-   Run whether the user is logged on or not.
-   Run with highest privileges.
-   Use an account with permission to control the ArcGIS Server Windows
    service.
-   Schedule the restart during an approved maintenance window.
-   Run the task manually once after configuration to verify execution
    and permissions.

## Email Notifications

Recommended production behavior:

-   **Failure:** send an email with the execution log attached.
-   **Success:** optional, controlled by `$SendSuccessEmail`.

Avoid committing environment-specific SMTP credentials or other secrets
to GitHub.

## Security

Do not commit passwords, authentication tokens, private certificates, or
other credentials.

Before publishing a repository, review scripts for internal information
such as server names, DNS names, SMTP hosts, email addresses, usernames,
and infrastructure-specific paths. Replace them with configuration
values or placeholders as appropriate.

## Testing

Before enabling the production scheduled task:

1.  Run the test version manually.
2.  Confirm that the ArcGIS Server Windows service is detected.
3.  Confirm logging works.
4.  Confirm email behavior.
5.  Verify the Task Scheduler account and privileges.
6.  Run the task manually from Task Scheduler.
7.  Review the generated log.
8.  Enable the production restart after validation.

## Why PowerShell?

PowerShell provides native Windows service-management commands:

``` powershell
Get-Service
Stop-Service
Start-Service
```

This keeps the implementation lightweight and avoids additional runtime
dependencies for a Windows service-management task.

## Disclaimer

Test this automation in a non-production environment or during an
approved maintenance window before production use. Restarting the ArcGIS
Server Windows service temporarily makes services hosted by that ArcGIS
Server instance unavailable.
