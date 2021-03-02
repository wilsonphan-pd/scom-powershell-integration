# SCOM

## Description
This integration uses the powershell command line function within Microsoft System Center Operations Manager to send alerts to PagerDuty.

## Setup

### Step 1 - SCOM Channel
In the Operations Console, head to Administration and create a new Command Notification Channel. When prompted for the following Settings information in the Command Notification Channel, provide the following values. Be sure to input your variables for the "File", "RoutingKey", and "Logfile" parameters. More information on those below:

	Full Path of the Command File:		C:\windows\system32\windowspowershell\v1.0\powershell.exe
	Command Line Parameters:		-File "PATHTOSCRIPT" -AlertID "$Data[Default='NotPresent']/Context/DataItem/AlertId$" -RoutingKey "YOURROUTINGKEY" -$logfile "PATHTOLOGFILE"
	Startup Folder for the Command Line:	C:\windows\system32\windowspowershell\v1.0\

### Step 2 - SCOM Subscriber
In the Operations Console, create a Subscriber. When prompted for the settings, provide the following values:
	
	Address Name:		PagerDuty
	Channel Type:		Command
	Command Channel:	The name of the command channel you created in step 1
	Schedule: 		This is up to you, but I chose to "Always send notifications"

### Step 3 - SCOM Subscription
In the Operations Console, create a Subscription. When prompted for the settings, provide the following values:

	Subscription Name:	PagerDuty
	Scope:			These settings are up to you, I left them on the default to notify on all alerts
	Criteria:		These settings are up to you, I chose "Severity Equals Critical" AND "Resolution State Does Not Equal Resolved or Closed"
	Subscribers:		Select the Subscriber you created in step 2 above.
	Channels:		Select the Channel you created in step 1 above.
	

#### Note
Parameters:

	File: This is the path to the "pagerduty.ps1" file. 
	Logfile: This is the path to the log file.
	RoutingKey: This is your Integration Key from pager duty. More info below.

To obtain an "Integration Key" to be passed into the Command Line Parameter, go into your PagerDuty Account > Configuration > Services and select the service you want to send alerts to. Create the integration "Microsoft SCOM" and you'll be provided an "Integration Key".

This integration uses the Operations Manager Module to obtain Alert information. 
