# ---------------------------------------------------------------------------
# Restart_ArcGIS_Server_Service.ps1
# ---------------------------------------------------------------------------
# Stops and restarts the ArcGIS Server Windows service
# ---------------------------------------------------------------------------
#Program/script: powershell.exe
#C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
#arguments: -NoProfile -ExecutionPolicy Bypass -File "C:\Users\GISSRV\Documents\ArcGIS\asset_script\ArcGIS_Server_Service\Restart_ArcGIS_Server_Service.ps1"

#powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\GISSRV\Documents\ArcGIS\asset_script\ArcGIS_Server_Service\Restart_ArcGIS_Server_Service_Test_commentout.ps1"

$ServiceName = "ArcGIS Server"

$LogFolder = "C:\Users\GISSRV\Documents\ArcGIS\asset_script\ArcGIS_Server_Service\Logs"

$TimeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$LogFile = Join-Path `
    $LogFolder `
    "ArcGIS_Server_Restart_$TimeStamp.log"

# ---------------------------------------------------------------------------
# EMAIL CONFIGURATION
# ---------------------------------------------------------------------------

$SmtpServer = "smtp.tohowater.com"
$FromEmail  = "GISSRV@tohowater.com"

$ToEmail = @(
    "mnkum@tohowater.com"
)

# Controls whether a SUCCESS email is sent.
# $true  = send success emails
# $false = do not send success emails
$SendSuccessEmail = $true


function Send-Email {

    param (
        [string]$Subject,
        [string]$Message,
        [string]$Attachment = $null
    )

    $MailMessage = $null
    $MailAttachment = $null
    $SmtpClient = $null

    try {

        $MailMessage = New-Object System.Net.Mail.MailMessage

        $MailMessage.From = $FromEmail

        foreach ($Recipient in $ToEmail) {
            $MailMessage.To.Add($Recipient)
        }

        $MailMessage.Subject = $Subject
        $MailMessage.Body = $Message
        $MailMessage.Priority = "Normal"

        if (
            $Attachment -and
            (Test-Path $Attachment)
        ) {

            $MailAttachment = New-Object `
                System.Net.Mail.Attachment($Attachment)

            $MailMessage.Attachments.Add(
                $MailAttachment
            )
        }

        $SmtpClient = New-Object `
            System.Net.Mail.SmtpClient($SmtpServer)

        $SmtpClient.Send($MailMessage)

        # -------------------------------------------------------
        # IMPORTANT:
        # Releasing the attachment before writing to the log again.
        # -------------------------------------------------------

        if ($MailAttachment) {
            $MailAttachment.Dispose()
            $MailAttachment = $null
        }

        if ($MailMessage) {
            $MailMessage.Dispose()
            $MailMessage = $null
        }

        if ($SmtpClient) {
            $SmtpClient.Dispose()
            $SmtpClient = $null
        }

        Write-Log "Email sent successfully."

    }
    catch {

        # Release objects if an error occurs
        if ($MailAttachment) {
            $MailAttachment.Dispose()
        }

        if ($MailMessage) {
            $MailMessage.Dispose()
        }

        if ($SmtpClient) {
            $SmtpClient.Dispose()
        }

        Write-Log "Failed to send email."
        Write-Log "Email error: $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# Creating log directory if it does not exist
# ---------------------------------------------------------------------------

if (!(Test-Path $LogFolder)) {
    New-Item `
        -ItemType Directory `
        -Path $LogFolder `
        -Force | Out-Null
}


function Write-Log {

    param(
        [string]$Message
    )

    $CurrentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $LogMessage = "$CurrentTime - $Message"

    Write-Host $LogMessage

    Add-Content `
        -Path $LogFile `
        -Value $LogMessage
}


try {

    Write-Log "============================================"
    Write-Log "Starting ArcGIS Server Windows service restart"
    Write-Log "============================================"

    # -----------------------------------------------------------------------
    # Verifying whether service exists
    # -----------------------------------------------------------------------

    $Service = Get-Service `
        -Name $ServiceName `
        -ErrorAction Stop

    Write-Log "Service found: $($Service.DisplayName)"
    Write-Log "Current status: $($Service.Status)"


    # -----------------------------------------------------------------------
    # STOPPING ARCGIS SERVER WINDOWS SERVICE
    # -----------------------------------------------------------------------

    if ($Service.Status -ne "Stopped") {

        Write-Log "TEST MODE - Would stop ArcGIS Server Windows service."

        #Stop-Service `
        #    -Name $ServiceName `
        #    -Force `
        #    -ErrorAction Stop

        # Wait until Windows confirms that it is stopped
        #$Service.WaitForStatus(
        #    "Stopped",
        #    (New-TimeSpan -Minutes 5)
        #)

        Write-Log "TEST MODE - Stop command is commented out; service was not stopped."

    }
    else {

        Write-Log "ArcGIS Server service is already stopped."

    }


    # -----------------------------------------------------------------------
    # SHORT WAIT BEFORE RESTARTING
    # -----------------------------------------------------------------------

    Write-Log "Waiting 15 seconds before restart..."

    Start-Sleep -Seconds 15


    # -----------------------------------------------------------------------
    # STARTING ARCGIS SERVER WINDOWS SERVICE
    # -----------------------------------------------------------------------

    Write-Log "TEST MODE - Would start ArcGIS Server Windows service."

    #Start-Service `
    #    -Name $ServiceName `
    #    -ErrorAction Stop

    # Allowing up to 5 minutes for Windows service startup
    #$Service.WaitForStatus(
    #    "Running",
    #    (New-TimeSpan -Minutes 5)
    #)


    # Refreshing service status
    $Service = Get-Service -Name $ServiceName

    Write-Log "Current status: $($Service.Status)"


    if ($Service.Status -eq "Running") {

        Write-Log "TEST MODE - ArcGIS Server Windows service is currently running; no restart was performed."

    }
    else {

        throw "ArcGIS Server service did not return to Running state."

    }


    Write-Log "============================================"
    Write-Log "TEST MODE - ArcGIS Server restart test completed successfully; no service restart was performed."
    Write-Log "============================================"
	
    if ($SendSuccessEmail) {

        Send-Email `
            -Subject "TEST - ArcGIS Server Service Restart Script - SUCCESS" `
            -Message "TEST MODE completed successfully on $env:COMPUTERNAME. The stop/start commands are commented out, so the ArcGIS Server Windows service was not restarted." `
            -Attachment $LogFile

    }
    else {

        Write-Log "Success email notification is disabled."

    }

    exit 0

}
catch {

    $ErrorMessage = $_.Exception.Message

    Write-Log "============================================"
    Write-Log "ERROR restarting ArcGIS Server Windows service."
    Write-Log "Error: $ErrorMessage"
    Write-Log "============================================"

    # Failure notifications are always sent.
    Send-Email `
        -Subject "TEST - ArcGIS Server Service Restart Script - FAILED" `
        -Message "The ArcGIS Server Windows service restart failed on $env:COMPUTERNAME.`n`nError: $ErrorMessage" `
        -Attachment $LogFile

    exit 1

}