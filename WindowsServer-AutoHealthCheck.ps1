########################################################################################################################
#
#             Program: WindowsServer-AutoHealthCheck.ps1
#
#             Author: Victor Bajada
#
#             Created On: October 2, 2015
#
#             Modified By: Victor Bajada - May 16, 2016
#                          Victor Bajada - April 22, 2021
#
#             Department: 
#
#             Function: To check for Services that are set to Automatic but are not running and try to restart them
#
#########################################################################################################################
Param(
    [switch]$NoReboot
)

$Scriptdir=".\Check-WindowsAutosvc"
Set-Location $Scriptdir


$IgnoreSvcs=@( 
    'Microsoft .NET Framework NGEN v4.0.30319_X64', 
    'Microsoft .NET Framework NGEN v4.0.30319_X86', 
    'Multimedia Class Scheduler', 
    'Performance Logs and Alerts', 
    'SBSD Security Center Service', 
    'Shell Hardware Detection', 
    'Software Protection', 
    'TPM Base Services',
    'Remote Registry'; 
)

$IgnoreIds=@(
    '36871';
)

#Get List of Servers to Check
$Servers=Import-Csv -Path ".\Import\Servers.csv"

#Try to restart Service on each server
foreach ($server in $Servers){
    try{
    $LogfileName=($env:UserName) + "_" + (Get-Date -Format yyyyMMdd) + "_" + $server.name + ".log"
        New-Item -Name $LogfileName -ItemType File -Force
        $LogFile=Get-ChildItem .\$LogfileName

            if(!($NoReboot)){
                Restart-Computer -ComputerName $server.name -Wait -For WinRM -Force
                Start-Sleep -Seconds 60
             }

                    #Check Auto Services that failed to start
                    $Services=Get-WmiObject Win32_Service -ComputerName $server.name | Where-Object {$_.StartMode -eq 'Auto' -and $IgnoreSvcs -notcontains $_.DisplayName -and $_.State -ne 'Running'}
                    
                    #Check Last Boot Up Time and Write to Log
                    $uptime=get-wmiobject win32_operatingsystem -computername $server.name | Select-Object @{LABEL='LastBootUpTime' ;EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
                    Add-Content $Logfile ((Get-Date -Format HH:mm:ss) + "-" + "$($server.name) 'Last Boot Time:' $($uptime.LastBootUptime)")
                               
                    #Check Certificate Expiry and write to Log
                    $ExpiringCertsPersonal=Get-ChildItem -path cert:\localmachine\my | Select-Object subject, notafter | Where-Object {$_.notafter -lt (Get-Date).AddDays(60)}
                    $ExpiringCertsRoot=Get-ChildItem -path cert:\localmachine\root | Select-Object subject, notafter | Where-Object {$_.notafter -lt (Get-Date).AddDays(60)}
                    Add-Content $Logfile ((Get-Date -Format HH:mm:ss) + "-" + $ExpiringCertsPersonal)
                    Add-Content $Logfile ((Get-Date -Format HH:mm:ss) + "-" + $ExpiringCertsRoot)
            

# If any services were found fitting the above description... 
if ($Services) { 
    # Loop through each service in services 
    ForEach ($Service in $Services) { 
        # Attempt to restart the service 
        $Service.StartService()
         
        # Pause for 5 seconds 
        Start-Sleep -s 5

        # Recheck the Service information in order to recheck its status 
        $StoppedService=Get-WmiObject Win32_Service -ComputerName $server.name | Where-Object {$_.DisplayName -eq  $Service.Displayname}
        $StoppedServiceName=$StoppedService.Name

        # If the service failed to restart... 
        If ($StoppedService.State -ne 'Running') { 
            Add-Content $Logfile ((Get-Date -Format HH:mm:ss) + "-" + "$StoppedServiceName 'Service failed to start on:' $($server.name)")
       }
       else{
        Add-Content $Logfile ((Get-Date -Format HH:mm:ss) + "-" + "$StoppedServiceName 'Service was successfully started on:' $($server.name)")
        }
         
        #Check the System Event Log for any Critical, Error or Warning Messages from the current day and print them to a log file
        $BadThings=Get-WinEvent -ComputerName BAJADAV01AL -ErrorAction SilentlyContinue -FilterHashtable @{logname='system','application'; level='1','2'; StartTime=(Get-Date).date} | Where-Object {$_.Id -notmatch $IgnoreIds}

        if ($BadThings){
            Add-Content $Logfile ((Get-Date -Format HH:mm:ss) + "-" + "'Warning! Error events detected on:' $($server.name) 'Please check logs'")
            $BadThings | Select-Object Logname, TimeCreated, LevelDisplayName, Message | Export-Csv -NoTypeInformation "$scriptdir\$($server.name).csv"
        }
        else{
            Add-Content $Logfile ((Get-Date -Format HH:mm:ss) + "-" + "'Warning! Error events detected on:' $($server.name)")
        }

        # Clear the StoppedService variable 
        if ($StoppedService)   { 
        Clear-Variable StoppedService
                               } 
                                    } 
               }
               else{
               Write-Host "All Automatic Services on" $Server.Name "are already running! Nothing to do!"
                   }

                                    #Check Hotfix Information and Write to Log
                                    $InstalledHotfixes=get-hotfix -ComputerName $server.name | Where-Object {$_.InstalledOn -gt (Get-Date).AddDays(-30) } | Sort-Object InstalledOn | Select-Object HotfixId,InstalledOn
                                    Add-Content $Logfile ((Get-Date -Format HH:mm:ss) + "-" + $($InstalledHotfixes.HotfixId) + "-" + $($InstalledHotfixes.InstalledOn))
                
}
Catch {
[system.exception]
Write-Host "Failed to restart $($server.name) `n$error[0]"
}

 
 
                            }