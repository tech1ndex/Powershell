########################################################################################################################
#
#             Program: LAPS-Bulk-Password-Report.ps1
#
#             Author: Victor Bajada
#
#             Created On: January 6, 2016
#
#             Department: 
#
#             Function: Set Password Reset date for all SERVERS using LAPS
#
#########################################################################################################################

 Function PressAnyKey() {
    Write-Host "Press any key to continue ..."
    $HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
    $HOST.UI.RawUI.Flushinputbuffer()
}

$workingdir=pwd

#Start Logging
$checklogfile="$workingdir\LAPS-BulkPwdUpdate-Check$(get-Date -UFormat "%Y-%m-%d").txt"
$missinglaps="$workingdir\LAPS-Missing-Check$(get-Date -UFormat "%Y-%m-%d").txt"

# Import Required Modules
Import-Module ActiveDirectory
Import-Module AdmPwd.PS 

# Declare Arrays to be used
$rootname=$env:USERDOMAIN
$suffix=$env:USERDNSDOMAIN.Split(".")[1]
$serverou="OU=Servers,DC=$rootname,DC=$suffix"

# Obtain List of Computers that are in Managed OU
$servers=Get-ADComputer -Filter * -SearchBase "$serverou" | Select Name

# Check Passwords
foreach($server in $servers){
try{
Get-AdmPwdPassword –ComputerName $server.Name | Out-File -Append $checklogfile
}
catch{
Write-Host "ERROR: Unable to read Password for: $server" | Out-File -Append $checklogfile
     }
                            }

# List Machines Missing Laps
foreach ($server in $servers){
$passwords=Get-AdmPwdPassword –ComputerName $server.Name

if($passwords.Password -eq $null){
Write-Host $passwords.ComputerName | Out-File -Append $missinglaps
                                 }
}

Write-Host "Script Complete"
PressAnyKey