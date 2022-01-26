########################################################################################################################
#
#             Program: Sync-AAGLogins.ps1
#
#             Author: Victor Bajada
#
#             Created On: May 13, 2020
#
#             Modified By:
#
#             Department: 
#
#             Function: Keep SQL Login Permissions in Sync in a SQL Always On Environment 
#
#########################################################################################################################


Import-Module dbatools

function Sync-AllDBALogins{
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]$SQLNode
    )
    try{
    $cred=(Get-Credential -Message "Enter your EP Credentials to connect to SQL")
    $inst = Connect-DbaInstance $SQLNode
    $AGs=Get-DbaAvailabilityGroup -SqlInstance $inst

            foreach($AG in $AGs){
                if($AG.localreplicarole -match "Secondary"){
                Write-Host "This Node does not host the Primary Replica for" $AG.Name -ForegroundColor Red
                Write-Host "Stopping..." -ForegroundColor Red
                Exit
                }
            }
                
                    $Primary=@()
                    $Secondaries=@()
                    $AGName=$AG.Name
                    $Replicas=Get-DbaAgReplica -SqlInstance $inst -AvailabilityGroup $AGName
                        foreach($Replica in $Replicas){
                            if($Replica.Role -match 'Primary'){
                            $Primary=[string]$Replica.Name
                            Write-Host "The Primary Replica for" $AGName "is $Primary" -ForegroundColor Yellow
                }
                    else{ 
                    $Secondaries+=$Replica.Name 
                    }
                        }

                        foreach ($Secondary in $Secondaries){
                            $Secondary=[string]$Secondary
                            Write-Host "The Secondary Replicas for" $AGName "are $Secondaries" -ForegroundColor Yellow
                            Copy-DbaLogin -Source $Primary -SourceSqlCredential $cred -Destination $Secondary -DestinationSqlCredential $cred -WhatIf
                            Sync-DbaLoginPermission -source $Primary -SourceSqlCredential $cred -destination $Secondary -DestinationSqlCredential $cred -WhatIf
                        }
            
         
                
    }
        catch{
            #$msg = $_.Exception.Message
            Write-Host "Error while syncing logins for Availability Group" $AGName
            Write-Host "Chances are this is not the Primary Replica for this AG, please try again on another one"
        }

}
function Sync-AGLogins {
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]$AvailabilityGroupName,
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]$SQLNode
    )
    try {
        $cred=(Get-Credential -Message "Enter your EP Credentials to connect to SQL")
        $inst = Connect-DbaInstance $SQLNode
        $Primary=@()
        $Secondaries=@()
        $Replicas=Get-DbaAgReplica -SqlInstance $inst -AvailabilityGroup $AvailabilityGroupName
            foreach($Replica in $Replicas){
                if($Replica.Role -match 'Primary'){
                    $Primary=[string]$Replica.Name
                    Write-Host "The Primary Replica for" $AvailabilityGroupName "is $Primary" -ForegroundColor Yellow
                }
                    else{ 
                    $Secondaries+=$Replica.Name 
                    }
            }

                        foreach ($Secondary in $Secondaries){
                            $Secondary=[string]$Secondary
                            Write-Host "The Secondary Replicas for" $AvailabilityGroupName "are $Secondaries" -ForegroundColor Yellow
                            Copy-DbaLogin -Source $Primary -SourceSqlCredential $cred -Destination $Secondary -DestinationSqlCredential $cred
                            Sync-DbaLoginPermission -source $Primary -SourceSqlCredential $cred -destination $Secondary -DestinationSqlCredential $cred
                        }
            }
            catch{
                #$msg = $_.Exception.Message
                Write-Host "Error while syncing logins for Availability Group" $AvailabilityGroupName
                Write-Host "Chances are this is not the Primary Replica for this AG, please try again on another one"
            }
}

function Copy-AllSQLLogins{
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]$SourceServer,
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]$DestinationServer
    )
    $cred=(Get-Credential -Message "Enter your EP Credentials to connect to SQL")
    Copy-DbaLogin -Source $SourceServer -SourceSqlCredential $cred -Destination $DestinationServer -DestinationSqlCredential $cred -WhatIf
    Sync-DbaLoginPermission -source $SourceServer -SourceSqlCredential $cred -destination $DestinationServer -DestinationSqlCredential $cred -WhatIf
}



Write-Host "Which action would you like to perform today?" -ForegroundColor Cyan
Write-Host "1. Sync ALL Logins for ALL Availability Groups to all Replicas - Please note all Availability Groups need to be running on 1 node for this to work" -ForegroundColor Yellow
Write-Host "2. Sync ALL Logins for a specific Availability Group to all Replicas" -ForegroundColor Yellow

$choice=Read-Host -Prompt "Please enter the corresponding number of your choice"

if($choice -eq 1){
    Sync-AllDBALogins
}
elseif ($choice -eq 2) {
    Sync-AGLogins
}
else{
    Write-Host "Invalid choice"
}
Exit