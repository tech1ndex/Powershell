########################################################################################################################
#
#             Program: Uninstall-MSTeamsALLUsers.ps1
#
#             Author: Victor Bajada
#
#             Created On: May 13, 2020
#
#             Modified By: Victor Bajada - July 31, 2020
#
#             Department: 
#
#             Function: Search through all local user profiles and Cleanup Leftover Files from MS Teams Install.
#
#########################################################################################################################

#Check if Teams is still running and Kill it
$Teams=Get-Process teams -ErrorAction SilentlyContinue
if($Teams){
    $Teams | Stop-Process -Force
}

#Check if Outlook is Running and Kill it
$Outlook=Get-Process outlook -ErrorAction SilentlyContinue
if($Outlook){
    $Outlook | Stop-Process -Force
        }

#Get List of User Profiles on Local Machine
$users=Get-WmiObject win32_userprofile | Select-Object localpath,sid

foreach ($User in $users){
#Check for Local/Appdata Teams Folder
$userdir=$user.localpath
$TeamsDirs="$userdir\AppData\Local\Microsoft\Teams","$userdir\AppData\Roaming\Microsoft Teams","$userdir\AppData\Roaming\Microsoft\Teams","$userdir\AppData\Local\Microsoft\TeamsMeetingAddin","$userdir\AppData\Local\Microsoft\TeamsPresenceAddin"
foreach($TeamsDir in $TeamsDirs){
    if(Get-Childitem -Path $TeamsDir) {
        Remove-Item $TeamsDir -Recurse 
    }
}

#Check for Registry Keys
$usersecid=$user.sid
$TeamsRegKeys="HKEY_USERS\$usersecid\Software\Microsoft\Teams\"
if(Test-Path $TeamsRegKeys){
    Remove-Item -Path $TeamsRegKeys 
}
}

