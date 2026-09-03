# ---------------------------------------------------------------------------
# Restart_ArcGIS_Server_Service.ps1
# ---------------------------------------------------------------------------
# Stops and restarts the ArcGIS Server Windows service
# ---------------------------------------------------------------------------

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

$FromEmail = "GISSRV@tohowater.com"

$ToEmail = @(
    "mnkum@tohowater.com",
    "bmugalu@tohowater.com",
    "mseidita@tohowater.com"
)

# Controls whether a SUCCESS email is sent.
# $true  = send success emails
# $false = do not send success emails

$SendSuccessEmail = $false


# ---------------------------------------------------------------------------
# CREATE LOG DIRECTORY IF IT DOES NOT EXIST
# ---------------------------------------------------------------------------

if (!(Test-Path $LogFolder)) {

    New-Item `
        -ItemType Directory `
        -Path $LogFolder `
        -Force | Out-Null
}


# ---------------------------------------------------------------------------
# LOGGING FUNCTION
# ---------------------------------------------------------------------------

function Write-Log {

    param (
        [string]$Message
    )

    $CurrentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $LogMessage = "$CurrentTime - $Message"

    Write-Host $LogMessage

    Add-Content `
        -Path $LogFile `
        -Value $LogMessage
}


# ---------------------------------------------------------------------------
# EMAIL FUNCTION
# ---------------------------------------------------------------------------

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

        # -------------------------------------------------------
        # LOG RECIPIENT INFORMATION BEFORE ATTACHING LOG FILE
        # -------------------------------------------------------

        Write-Log "Preparing email for $($ToEmail.Count) recipient(s)..."

        foreach ($Recipient in $ToEmail) {
            Write-Log "Email recipient: $Recipient"
        }


        # -------------------------------------------------------
        # CREATE EMAIL MESSAGE
        # -------------------------------------------------------

        $MailMessage = New-Object System.Net.Mail.MailMessage

        $MailMessage.From = $FromEmail


        # -------------------------------------------------------
        # ADD MULTIPLE RECIPIENTS
        # -------------------------------------------------------

        foreach ($Recipient in $ToEmail) {
            $MailMessage.To.Add($Recipient)
        }


        $MailMessage.Subject = $Subject
        $MailMessage.Body = $Message
        $MailMessage.Priority = "Normal"


        # -------------------------------------------------------
        # ATTACH LOG FILE
        # IMPORTANT:
        # Do not call Write-Log after this point until
        # the attachment has been disposed.
        # -------------------------------------------------------

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


        # -------------------------------------------------------
        # CREATE SMTP CLIENT
        # -------------------------------------------------------

        $SmtpClient = New-Object `
            System.Net.Mail.SmtpClient($SmtpServer)


        # -------------------------------------------------------
        # SEND ONE EMAIL TO ALL RECIPIENTS
        # -------------------------------------------------------

        $SmtpClient.Send($MailMessage)


        # -------------------------------------------------------
        # RELEASE ATTACHMENT FIRST
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


        # Now the log file is unlocked again
        Write-Log "Email sent successfully to $($ToEmail.Count) recipient(s)."

    }

    catch {

        $EmailError = $_.Exception.Message

        if ($_.Exception.InnerException) {
            $EmailError = "$EmailError | Inner Error: $($_.Exception.InnerException.Message)"
        }


        # -------------------------------------------------------
        # RELEASE OBJECTS BEFORE WRITING ERROR TO LOG
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


        Write-Log "Failed to send email."
        Write-Log "Email error: $EmailError"

    }
}


# ---------------------------------------------------------------------------
# MAIN PROCESS
# ---------------------------------------------------------------------------

try {

    Write-Log "============================================"
    Write-Log "Starting ArcGIS Server Windows service restart"
    Write-Log "============================================"


    # -----------------------------------------------------------------------
    # VERIFY ARCGIS SERVER WINDOWS SERVICE EXISTS
    # -----------------------------------------------------------------------

    $Service = Get-Service `
        -Name $ServiceName `
        -ErrorAction Stop


    Write-Log "Service found: $($Service.DisplayName)"
    Write-Log "Current status: $($Service.Status)"


    # -----------------------------------------------------------------------
    # STOP ARCGIS SERVER WINDOWS SERVICE
    # -----------------------------------------------------------------------

    if ($Service.Status -ne "Stopped") {

        Write-Log "Stopping ArcGIS Server Windows service..."


        Stop-Service `
            -Name $ServiceName `
            -Force `
            -ErrorAction Stop


        # Wait up to 5 minutes for Windows to confirm stop

        $Service.WaitForStatus(
            "Stopped",
            (New-TimeSpan -Minutes 5)
        )


        Write-Log "ArcGIS Server Windows service stopped successfully."

    }

    else {

        Write-Log "ArcGIS Server Windows service is already stopped."

    }


    # -----------------------------------------------------------------------
    # WAIT BEFORE RESTART
    # -----------------------------------------------------------------------

    Write-Log "Waiting 60 seconds before restart..."

    Start-Sleep -Seconds 60


    # -----------------------------------------------------------------------
    # START ARCGIS SERVER WINDOWS SERVICE
    # -----------------------------------------------------------------------

    Write-Log "Starting ArcGIS Server Windows service..."


    Start-Service `
        -Name $ServiceName `
        -ErrorAction Stop


    # Wait up to 5 minutes for Windows to confirm startup

    $Service.WaitForStatus(
        "Running",
        (New-TimeSpan -Minutes 5)
    )


    # Refresh service status

    $Service = Get-Service `
        -Name $ServiceName `
        -ErrorAction Stop


    Write-Log "Current status: $($Service.Status)"


    # -----------------------------------------------------------------------
    # VERIFY SERVICE IS RUNNING
    # -----------------------------------------------------------------------

    if ($Service.Status -eq "Running") {

        Write-Log "ArcGIS Server Windows service restarted successfully."

    }

    else {

        throw "ArcGIS Server Windows service did not return to Running state."

    }


    Write-Log "============================================"
    Write-Log "ArcGIS Server restart completed successfully."
    Write-Log "============================================"


    # -----------------------------------------------------------------------
    # EMAIL NOTIFICATION WHEN SERVICE RESTART IS SUCCESSFUL
    # -----------------------------------------------------------------------

    if ($SendSuccessEmail) {

        Send-Email `
            -Subject "ArcGIS Server Service Restart Summary" `
            -Message "The ArcGIS Server Windows service was restarted successfully on $env:COMPUTERNAME." `
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


    # -----------------------------------------------------------------------
    # EMAIL NOTIFICATION WHEN SERVICE RESTART IS UNSUCCESSFUL
    # -----------------------------------------------------------------------

    Send-Email `
        -Subject "ArcGIS Server Service Restart - FAILED" `
        -Message "The ArcGIS Server Windows service restart failed on $env:COMPUTERNAME.`n`nError: $ErrorMessage" `
        -Attachment $LogFile


    exit 1
}