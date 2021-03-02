#############################################################################
# Contributing Author  : Tyler Cox
# Inital Author: wilsonphan-pd (github name)
# 
# Special Thanks: Slightly Adapted from https://github.com/PagerDuty/scom-powershell-integration
#
# Version : 2.0
# Created : 6/24/2019
# Modified : 3/2/2021
#
# Purpose : This script is used to integrate SCOM command line function to send alerts to PagerDuty
#
# Requirements: Ran on computer with the SCOM console installed
#             
# Change Log:   Ver 2.0 - (Edited by tcox8) - Added dynamic module importing. 
#                                           - Added dynamic variables (logfile, routingkey)
#                                           - Added logic to handle alerts with larger than 1024 characters
#
#               Ver 1.0 - Initial release
#############################################################################


Param (
	[Parameter(Position=0,mandatory=$true)]		[String]$AlertID,
	[Parameter(Position=1,mandatory=$false)]	[String]$RoutingKey = "",
	[Parameter(Position=2,mandatory=$false)]	[String]$Url = "https://events.pagerduty.com/v2/enqueue",
    	[Parameter(Position=3,mandatory=$false)]    [string]$loglfile = ""
)

#Import the OperationsManager module and connect to the management group
Try 
    {
        #Tested in SCOM 2012 R2 and SCOM 2019 (Update Rollup 2)
        $SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
        $SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory "OperationsManager"
        Import-module $SCOMModulePath -ErrorAction Stop
    }
Catch 
    {
        Write-Host "Error! Failed to import Ops Manager module! Please make sure the script is running on a computer with the Console installed!"
    }   


# Get Alert Information
$Alert = Get-SCOMAlert -id $AlertID

# Determine the Event Action
switch ($Alert.ResolutionState){
        0       	{$Event="trigger"}
        254		{$Event="resolve"} 
        255     	{$Event="resolve"}
        default 	{$Event="trigger"}
    }

# Determine the Severity
switch ($Alert.Severity){
	"Information"	{$Severity="info"}
	"Warning"	{$Severity="warning"}
	"Error"		{$Severity="error"}
	"Critical"	{$Severity="critical"}
	default		{$Severity="critical"}
}


# Determine Host

[String]$Hostname = if($Alert.NetbiosComputerName){$Alert.NetbiosComputerName}
elseif($Alert.MonitoringObjectPath){$Alert.MonitoringObjectFullName}
elseif($Alert.MonitoringObjectName){$Alert.MonitoringObjectName}
else {"Hostname Not Available"}


# Construct PagerDuty Event Summary

#Have to deal with Alert Summary's greater than 1024 characters due to PagerDuty's limitations
[String]$AlertSummary = ($Hostname + " - " + $Alert.Name + " - " + $Alert.Description).Trim()
If (($AlertSummary | measure -character).Characters -ge 1023)
    {
        $AlertSummary = ($Hostname + " - " + $Alert.Name + " - " + "Details in Custom Fields").Trim()
        $Summary = $Alert.Description
    }
Else
    {
        $Summary = "Not Available"
    }

# Look Up Custom Details

[String]$Priority	= if ($Alert.Priority){$Alert.Priority} else {"Not Available"}
[String]$CustomField1 	= if ($Alert.CustomField1){$Alert.CustomField1} else {"Not Available"}
[String]$CustomField2	= if ($Alert.CustomField2){$Alert.CustomField2} else {"Not Available"}
[String]$CustomField3 	= if ($Alert.CustomField3){$Alert.CustomField3} else {"Not Available"}
[String]$CustomField4	= if ($Alert.CustomField4){$Alert.CustomField4} else {"Not Available"}
[String]$CustomField5	= if ($Alert.CustomField5){$Alert.CustomField5} else {"Not Available"}
[String]$CustomField6	= if ($Alert.CustomField6){$Alert.CustomField6} else {"Not Available"}
[String]$CustomField7	= if ($Alert.CustomField7){$Alert.CustomField7} else {"Not Available"}
[String]$CustomField8	= if ($Alert.CustomField8){$Alert.CustomField8} else {"Not Available"}
[String]$CustomField9	= if ($Alert.CustomField9){$Alert.CustomField9} else {"Not Available"}
[String]$CustomField10	= if ($Alert.CustomField10){$Alert.CustomField10} else {"Not Available"}

# Construct PagerDuty Events Payload


$AlertPayload = @{
	routing_key 			= $RoutingKey
	event_action 			= $Event
	dedup_key 			= $AlertID.Trim('{}')
	payload = @{
		summary 		= $AlertSummary
		severity 		= $Severity
		source			= $Hostname
		timestamp		= $Alert.TimeRaised.ToString("o")
		custom_details		= @{
			Priority	= $Priority
            Summary = $Summary
			CustomField1 	= $CustomField1
			CustomField2	= $CustomField2
			CustomField3 	= $CustomField3
			CustomField4	= $CustomField4
			CustomField5	= $CustomField5
			CustomField6	= $CustomField6
			CustomField7	= $CustomField7
			CustomField8	= $CustomField8
			CustomField9	= $CustomField9
			CustomField10	= $CustomField10
		}
	}
}

# Convert Events Payload to JSON

$json = ConvertTo-Json -InputObject $AlertPayload

$logEvents = $logfile


# Send to PagerDuty and Log Results

$LogMtx = New-Object System.Threading.Mutex($False, "LogMtx")
$LogMtx.WaitOne() | Out-Null

try {
    Invoke-RestMethod	-Method Post `
    					-ContentType "application/json" `
    					-Body $json `
    					-Uri $Url `
    					| Out-File $logEvents -Append
}

catch {
    out-file -InputObject "Exception Type: $($_.Exception.GetType().FullName) Exception Message: $($_.Exception.Message) AlertID = $AlertID Alert = $Alert ResolutionState = $Alert.ResolutionState Summary = $AlertSummary" -FilePath $logEvents -Append
}

finally {
	$LogMtx.ReleaseMutex() | Out-Null
}
