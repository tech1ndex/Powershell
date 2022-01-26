########################################################################################################################
#
#             Program: Uninstall-MSTeams.ps1
#
#             Author: Victor Bajada
#
#             Created On: May 6, 2020
#
#             Modified By:
#
#             Department: 
#
#             Function: Cleanup Leftover Files from MS Teams Uninstall.
#
#########################################################################################################################

#Check if Teams is still running and Kill it
$Teams=Get-Process teams -ErrorAction SilentlyContinue
if($Teams){
    $Teams.CloseMainWindow()
    Start-Sleep -Seconds 5
    $Teams | Stop-Process -Force
}

#Check if Outlook is Running and Kill it
$Outlook=Get-Process outlook -ErrorAction SilentlyContinue
if($Outlook){
    $Outlook.CloseMainWindow()
    Start-Sleep -Seconds 5
        if(!$Outlook.HasExited){
            $Outlook | Stop-Process -Force
        }
}

#Check for Local/Appdata Teams Folder
$TeamsDirs="$env:LOCALAPPDATA\Microsoft\Teams","$env:APPDATA\Microsoft Teams","$env:APPDATA\Microsoft\Teams"
foreach($TeamsDir in $TeamsDirs){
    if(Get-Childitem -Path $TeamsDir) {
        Remove-Item $TeamsDir -Recurse 
    }
}

#Check for Registry Keys
$TeamsRegKeys="HKCU:\Software\Microsoft\Office\Teams"
if(Test-Path $TeamsRegKeys){
    Remove-Item -Path $TeamsRegKeys 
}
