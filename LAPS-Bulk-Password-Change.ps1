########################################################################################################################
#
#             Program: LAPS-Bulk-Password-Change.ps1
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
# Declare Function for Date Selection
Function DatePicker($title) {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
     
    $global:date = $null
    $form = New-Object Windows.Forms.Form
    $form.Size = New-Object Drawing.Size(233,190)
    $form.StartPosition = "CenterScreen"
    $form.KeyPreview = $true
    $form.FormBorderStyle = "FixedSingle"
    $form.Text = $title
    $calendar = New-Object System.Windows.Forms.MonthCalendar
    $calendar.ShowTodayCircle = $false
    $calendar.MaxSelectionCount = 1
    $form.Controls.Add($calendar)
    $form.TopMost = $true
     
    $form.add_KeyDown({
        if($_.KeyCode -eq "Escape") {
            $global:date = $false
            $form.Close()
        }
    })
     
    $calendar.add_DateSelected({
        $global:date = $calendar.SelectionStart
        $form.Close()
    })
     
    [void]$form.add_Shown($form.Activate())
    [void]$form.ShowDialog()
    return $global:date
}
 Function PressAnyKey() {
    Write-Host "Press any key to continue ..."
    $HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
    $HOST.UI.RawUI.Flushinputbuffer()
}

$workingdir=pwd

#Start Logging
$logfile="$workingdir\LAPS-BulkPwdUpdate-$(get-Date -UFormat "%Y-%m-%d").txt"

# Import Required Modules
Import-Module ActiveDirectory
Import-Module AdmPwd.PS 

# Declare Arrays to be used
$rootname=$env:USERDOMAIN
$suffix=$env:USERDNSDOMAIN.Split(".")[1]
$serverou="OU=Servers,DC=$rootname,DC=$suffix"

# Obtain List of Computers that are in Managed OU
$servers=Get-ADComputer -Filter * -SearchBase "$serverou" | Select Name

# Prompt User for date input
Write-Host "Please select effective date for Password reset"
$effective=DatePicker "Effective Date"
$effective=$effective.Date.tostring("MM.dd.yyyy H:mm")

# Reset Passwords
foreach($server in $servers){
try{
Reset-AdmPwdPassword –ComputerName $server.Name –WhenEffective "$effective" | Out-File -Append $logfile
}
catch{
Write-Host "ERROR: Unable to Reset Password for: $server" | Out-File -Append $logfile
                            }
                            }

Write-Host "Script Complete"
PressAnyKey