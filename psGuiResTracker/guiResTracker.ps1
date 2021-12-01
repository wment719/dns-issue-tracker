Import-Module -Force $PSScriptRoot\uielements.ps1
#Import-Module -Force "C:\Users\wmiller\OneDrive - Ent Credit Union\utilities\uielements.ps1"
$IPPattern = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"

class trackedIP {
    [string]$ip
    [bool]$isResolvingFWD
    [bool]$isResolvingREV
    [bool]$isPinging
    [string]$lastResFWD
    [string]$lastResREV
    [string]$lastPing
}
class monitorState {
    [array]$ipList
    [string]$operatorUsername
    [string]$targetMachine
    [string]$expectedIP
    [string]$targetUsername
}
function determinePinging($targetIP) {
    if ((test-connection $targetIP -count 1 -quiet) -or (test-connection $targetIP -count 1 -quiet)) {
        return $true
    }
    else{return $false}
}
function determineNSResolution($inputState) {
    $modifiedState = ConvertFrom-Json $inputState
    $newIPs = @()
    $lookupResults = (Resolve-DnsName $modifiedState.targetMachine)
    foreach ($previouslySeenIP in $modifiedState.ipList){
        $previouslySeenIP.isResolvingFWD = $false
    }
    foreach ($record in $lookupResults){
        if($record.Type -eq 'A'){
            $unique = $true
            foreach ($previouslySeenIP in $modifiedState.ipList){
                if ($record.IPAddress -eq $previouslySeenIP.ip){
                    $previouslySeenIP.isResolvingFWD = $True
                    $previouslySeenIP.lastResFWD = (Get-Date -format "hh:mmtt")
                    $unique = $false
                }
            }
            if($unique){
                $newIPs += $record.IPAddress
            }
            
        }
    }
    foreach ($previouslySeenIP in $modifiedState.ipList){
        if ($previouslySeenIP.isResolvingFWD -or ($previouslySeenIP.ip -eq $modifiedState.expectedIP)){
            if (determinePinging($previouslySeenIP.ip)){
                $previouslySeenIP.isPinging = $true
                $previouslySeenIP.LastPing  = (Get-Date -format "hh:mmtt")
            }
            else{$previouslySeenIP.isPinging = $false}
            if((Resolve-DnsName $previouslySeenIP.ip).NameHost.tolower().contains($modifiedState.targetMachine.ToLower())){
                $previouslySeenIP.isResolvingREV = $true
                $previouslySeenIP.lastResREV = (Get-Date -format "hh:mmtt")
            }
            else {$previouslySeenIP.isResolvingREV = $false}
        }
    }

    return @($modifiedState, $newIPs)
}
function formatOutput($inputState) {
    $msgbox.Text = ""
    foreach ($trackedIP in $inputState.ipList){
        $line = ""
        if($trackedIP.isResolvingFWD -or ($trackedIP.ip -eq $inputState.expectedIP)){
            if($msgBox.Text){$line+="`n`n"}
            $line += ($trackedIP.ip+"  forward:")
            if($trackedIP.isResolvingFWD){$line += "GOOD"}
            else{$line += "BAD"}
            $line += "    (last resolved "+$trackedIP.lastResFWD+")"
            $line += "`n    [last pinged - "+$trackedIP.LastPing+" ]"
            $line += "`n reverse: "
            if($trackedIP.isResolvingREV){$line += "GOOD"}
            else{$line += "BAD"}
            $line += "    (last "+$trackedIP.lastResREV+")"
            $msgBox.Text += $line
        }
    }
}

function statusUpdate($inputState) {
    $resolvingCount=0
    $pingingCount=0
    $resolveAndPingCount=0
    foreach($trackedIP in $inputState.iplist){
        if($trackedIP.isResolvingFWD){$resolvingCount += 1}
        if($trackedIP.isPinging){$resolvingCount += 1}
        if($trackedIP.isResolvingFWD -and $trackedIP.isPinging){$resolveAndPingCount += 1}
    if($resolveAndPingCount){$form0.BackColor="green"    }
    }
}


$addFunctions= [scriptblock]::Create(@"
    function determinePinging { $Function:determinePinging }
    function determineNSResolution { $Function:determineNSResolution }
"@)

#main script
$global:currentState = [monitorState]::new()
$global:currentState.operatorUsername = ((whoami) -split "\\")[1]
(whoami)[7..(whoami).length] -join ''

$timer.Interval = 150
$timer.Add_Tick({
    if (-not $global:currentState.ipList){
        $newIPObject = [trackedIP]::new()
        $newIPObject.lastPing = "never"
        $newIPObject.lastResFWD = "never"
        $newIPObject.lastResREV = "never"
        $newIPObject.ip = $global:currentState.expectedIP
        $global:currentState.ipList += $newIPObject
    }
    if (-not (Get-job)) {
        $jsonState=ConvertTo-Json $global:currentState 
        $global:nsresjob = Start-Job -InitializationScript $addFunctions -ScriptBlock {param($inputObject) determineNSResolution $inputObject} -ArgumentList $jsonState
    }
    elseif ((Get-Job) -and ((Get-Job)[0].state -like "Completed")){
        Receive-Job -job $global:nsresjob -OutVariable newState
        $global:currentState = $newState[0]
        foreach($newip in $newState[1]){
            $newIPObject = [trackedIP]::new()
            $newIPObject.isResolvingFWD = $True
            $newIPObject.lastPing = "never"
            $newIPObject.lastResFWD = (Get-Date -format "hh:mmtt")
            $newIPObject.ip = $newip
            $global:currentState.ipList += $newIPObject
        }
        Remove-Job -job $global:nsresjob
        formatOutput($global:currentState)
        statusUpdate($global:currentState)
    }
    elseif ((Get-Job)[0].state -notlike "Running"){
        Remove-Job -job $global:nsresjob
    }
})
$timer.enabled = $false

#default values for ease of testing
#$usernameTBox.Text = "wm"
#$hostnameTBox.Text = "lap402216"
#$ipTBox.Text = "1.3.3.7"
###Display window
$form0.ShowDialog()