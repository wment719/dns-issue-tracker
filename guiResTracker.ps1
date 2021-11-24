### Function and variable definitions

$me=(whoami)[7..(whoami).length] -join ''
$IPPattern = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"
$trackedIPs = @()
function determinePinging($targetIP) {
    if ((test-connection $targetIP -count 1 -quiet) -or (test-connection $targetIP -count 1 -quiet)) {
        foreach ($knownIP in $trackedIPs){
            if ($knownIP.Address -eq $targetIP){
                $knownIP.LastPinged = (Get-Date -DisplayHint Time).tostring()
            }
        }
        return @(1,'None')
    }
    else{
        $lastping = 'Never'
        foreach ($knownIP in $trackedIPs){
            if ($knownIP.Address -eq $targetIP){
                $lastping = $knownIP.LastPinged
            }
        }
        return @(0, $lastping)
    }
}

function determineNSResolution($hostnameToResolve) {
    $addresses = @()
    $lookupResults = (Resolve-DnsName $hostnameToResolve)
    foreach ($record in $lookupResults){
        if($record.Type -eq 'A'){
            $addresses += $record.IPAddress
        }
    }
    foreach ($justSeenIP in $addresses){
        $unique = 1
        foreach ($knownIP in $trackedIPs){
            if ($knownIP.Address -eq $justSeenIP){
                $knownIP.LastResoled = (Get-Date -DisplayHint Time).tostring()
                $unique = 0
            }
            if ($unique){
                $trackedIPs += @{Address = $justSeenIP; LastResolved = (Get-Date -DisplayHint Time).tostring(); LastPinged = "Never" }
            }
        }
    }
    return $addresses
}

function checkReverse() {
    $reverseList = @()
    foreach ($ip in $currentResolution){
        if((Resolve-DnsName $ip).NameHost.tolower().contains($targetMachine.ToLower())){
            $reverseList += @($ip, 1)
        }
        else {
            $reverseList += @($ip, 0)
        }
    } 
    $Global:reverseResolution = $reverseList   
}

function mainCycle ($hostnameToResolve) {
    return determineNSResolution($hostnameToResolve)
}

$addFunctions= [scriptblock]::Create(@"
    Function determinePinging { $Function:determinePinging }
    function determineNSResolution { $Function:determineNSResolution }
    function checkReverse { $Function:checkReverse }
    function mainCycle { $Function:mainCycle }
"@)
#$status = @("firstrun", (Get-Date -DisplayHint Time).tostring())
    #
    #function statusUpdate($newStatus){
    #    if ($newStatus -ne $Global:status){
    #        $host.ui.rawui.windowtitle = $targetMachine+" "+$userName+" "+$newStatus
    #        if($Global:status -ne 'firstrun'){
    #            msg me $userName+" at "+$targetMachine+"
    #            old status [since "+$Global:status[1]+"] "+$Global:status[0]+"
    #            new status [since "+(Get-Date -DisplayHint Time).tostring()+"] "+$newStatus
    #        }
    #        $Global:status = ($newStatus, (Get-Date -DisplayHint Time).tostring())
    #    }
    #}
#


###Set up UI elements
Add-Type -assembly System.Windows.Forms


$form0 = New-Object System.Windows.Forms.Form
$form0.Width = 400; $form0.Height = 400
$form0.Text = "Enter user info"

$label0 = New-Object System.Windows.Forms.Label
$label0.Text = "User's Name"; $label0.AutoSize = $true
$label0.Location = New-Object System.Drawing.Point(30, 5)
$form0.Controls.Add($label0)

$usernameTBox = New-Object System.Windows.Forms.TextBox
$usernameTBox.AutoSize = $true
$usernameTBox.Location = New-Object System.Drawing.Point(5, 25)
$usernameTBox.Size = New-Object System.Drawing.Size(120,25)
$form0.Controls.Add($usernameTBox)
###
$label1 = New-Object System.Windows.Forms.Label
$label1.Text = "Hostname"; $label1.AutoSize = $true
$label1.Location = New-Object System.Drawing.Point(155, 5)
$form0.Controls.Add($label1)

$hostnameTBox = New-Object System.Windows.Forms.TextBox
$hostnameTBox.AutoSize = $true
$hostnameTBox.Location = New-Object System.Drawing.Point(130, 25)
$hostnameTBox.Size = New-Object System.Drawing.Size(120,25)
$form0.Controls.Add($hostnameTBox)
###
$label2 = New-Object System.Windows.Forms.Label
$label2.Text = "IP Address"; $label2.AutoSize = $true
$label2.Location = New-Object System.Drawing.Point(280, 5)
$form0.Controls.Add($label2)

$ipTBox = New-Object System.Windows.Forms.TextBox
$ipTBox.AutoSize = $true;
$ipTBox.Location = New-Object System.Drawing.Point(255, 25)
$ipTBox.Size = New-Object System.Drawing.Size(120,25)
$form0.Controls.Add($ipTBox)
###

###

$goButton = New-Object System.Windows.Forms.Button
$goButton.Location = New-Object System.Drawing.Point(140,55)
$goButton.Size = New-Object System.Drawing.Size(100,25)
$goButton.Text = "Start"
$goButton.Add_Click({
    $inputFields = @($usernameTBox.Text, $hostnameTBox.Text, $ipTBox.Text)
    $nonEmptyFields = 0
    $goodIP = $false
    $errMsg=""
    foreach ($text in $inputFields){
        if ($text){$nonEmptyFields+=1}
    }
    if($nonEmptyFields -lt $inputFields.length){
        $errMsg += "Missing an input "
    }
    if(($ipTBox.Text -notmatch $IPPattern) -and ($ipTBox.Text)){
        if($errMsg){$errMsg+="and "}
        $errMsg += "Bad IP "
        $ipTBox.Text = ""
    }
    $msgBox.Text = $errMsg
    if(($nonEmptyFields -eq $inputFields.length) -and ($ipTBox.Text)){
        $Global:userName = $usernameTBox.text; $Global:targetMachine = $hostnameTBox.Text; $Global:rightIP = $ipTBox.Text
        $form0.Text=$userName+" at "+$targetMachine+"  expected IP: "+$rightIP
        $timer.Enabled = $True
        $goButton.Visible = $false
    }
})
$form0.Controls.Add($goButton)

$msgBox = New-Object System.Windows.Forms.Label
$msgBox.Text = ""; $msgBox.AutoSize = $false
$msgBox.Location = New-Object System.Drawing.Point(5, 85)
$msgBox.Size = New-Object System.Drawing.Size(375,25)
$msgBox.TextAlign ="MiddleCenter"
$form0.Controls.Add($msgBox)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    if (-not (Get-job)) {
        $global:nsresjob = Start-Job -InitializationScript $addFunctions -ScriptBlock {param($targetMachine) mainCycle $targetMachine} -ArgumentList $targetMachine        
    }
    elseif ((Get-Job) -and ((Get-Job)[0].state -like "Completed")){
        $msgbox.Text = (Receive-Job -Job $global:nsresjob).tostring()
    }
    
})
$timer.Enabled = $False

###Display window


$form0.ShowDialog()
