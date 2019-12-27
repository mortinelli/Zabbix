#
# THIS SCRIPT IS READY TO USE
#

# Install Zabbix agent on Windows
# Tested on Windows Server 2016, 2019
# Version 1.07
# Created by Twikki
# Last updated 13/11/2019
# Installs Zabbix Agent 4.2.8


#Gets the server host name
$serverHostname =  Invoke-Command -ScriptBlock {hostname}


# Asks the user for the IP address of their Zabbix server
$ServerIP = "1.1.1.1"

$Dir = "c:\Program Files\zabbix"
$ZipfilePath = $Dir + "\zabbix.zip"
$agentConfFilePath = $Dir + "\zabbix_agentd.conf"
$agentExeFilePath = $Dir + "\zabbix_agentd.exe"
$LogFilePath = $Dir + "\zabbix_agentd.log"
$LogFileReplaceTo = "LogFile=" + $LogFilePath

# Creates Zabbix DIR
mkdir $Dir


# Downloads version 4.2.8 from Zabbix.com
Invoke-WebRequest "https://www.zabbix.com/downloads/4.2.8/zabbix_agents-4.2.8-win-amd64.zip" -outfile $ZipfilePath

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

# Unzipping file to c:\zabbix
Unzip $ZipfilePath $Dir      


# Sorts files in c:\zabbix
Move-Item ($Dir + "\bin\zabbix_agentd.exe") -Destination $Dir


# Sorts files in c:\zabbix
Move-Item ($Dir + "\conf\zabbix_agentd.conf") -Destination $Dir

# Replaces 127.0.0.1 with your Zabbix server IP in the config file
(Get-Content -Path $agentConfFilePath) | ForEach-Object {$_ -Replace '127.0.0.1', "$ServerIP"} | Set-Content -Path $agentConfFilePath

# Replaces hostname in the config file
(Get-Content -Path $agentConfFilePath) | ForEach-Object {$_ -Replace 'Windows host', "$ServerHostname"} | Set-Content -Path $agentConfFilePath

# Replace Log File Path
(Get-Content -Path $agentConfFilePath) | ForEach-Object {$_ -Replace "LogFile=c:\\zabbix_agentd.log", $LogFileReplaceTo} | Set-Content -Path $agentConfFilePath

# Attempts to install the agent with the config in c:\zabbix
$expInstall = "& " + "'" + $agentExeFilePath + "'" +" --config " + "'" + $agentConfFilePath + "'" + " --install"
Invoke-Expression $expInstall

# Attempts to start the agent
$expStart = "& " + "'" + $agentExeFilePath + "'" +" --start "
Invoke-Expression $expStart

# Creates a firewall rule for the Zabbix server
New-NetFirewallRule -DisplayName "Allow Zabbix communication" -Direction Inbound -Program $agentExeFilePath -RemoteAddress $ServerIP -Action Allow

