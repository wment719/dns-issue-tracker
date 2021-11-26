#Import-Module -Force $PSScriptRoot\uielements.ps1
Import-Module -Force "C:\Users\wmiller\OneDrive - Ent Credit Union\utilities\uielements.ps1"
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
function checkReverse($ipToCheck, $correctHostnmae) {
    if((Resolve-DnsName $ipToCheck).NameHost.tolower().contains($correctHostnmae.ToLower())){
        return $true
    }
    else{return $false}
}
function determineNSResolution($inputState) {
    $modifiedState = $inputState
    $newIPs = @()
    $lookupResults = (Resolve-DnsName $modifiedState.targetMachine)
    foreach ($previouslySeenIP in $modifiedState.ipList){
        $previouslySeenIP.isResolvingFWD = $false
    }
    foreach ($record in $lookupResults){
        if($record.Type -eq 'A'){
            write-host ($record.IPAddress + " a record")
            $unique = $true
            foreach ($previouslySeenIP in $modifiedState.ipList){
                write-host ($previouslySeenIP.ip + " seen prior")
                if ($record.IPAddress -eq $previouslySeenIP.ip){
                    write-host "wewaszhere3"
                    $previouslySeenIP.isResolvingFWD = $True
                    $previouslySeenIP.lastResFWD = (Get-Date -DisplayHint Time).tostring()
                    $unique = $false
                }
            }
            if($unique){
                $newIPs += $record.IPAddress
                #$newIPObject = [trackedIP]::new()
                #$newIPObject.isResolvingFWD = $True
                #$newIPObject.lastResFWD = (Get-Date -DisplayHint Time).tostring()
                #$newIPObject.ip = $record.IPAddress
                #$modifiedState.ipList += $newIPObject
            }
            
        }
    }
    foreach ($previouslySeenIP in $modifiedState.ipList){
        if ($previouslySeenIP.isResolvingFWD -or ($previouslySeenIP.ip -eq $modifiedState.expectedIP)){
            if (determinePinging($previouslySeenIP.ip)){
                $previouslySeenIP.isPinging = $true
                $previouslySeenIP.LastPing  = (Get-Date -DisplayHint Time).tostring()
            }
            else{$previouslySeenIP.isPinging = $false}

            #if(checkReverse($previouslySeenIP.ip, $modifiedState.targetMachine)){
            #    $previouslySeenIP.isResolvingREV = $true
            #    $previouslySeenIP.lastResREV = (Get-Date -DisplayHint Time).tostring()
            #}
            #else {$previouslySeenIP.isResolvingREV = $false}
        }
    }
    return @($modifiedState, $newIPs)
}
function formatOutput($inputState) {
    $msgbox.Text = ""
    foreach ($trackedIP in $inputState.ipList){
        $line = ""
        if($trackedIP.isResolvingFWD -or ($trackedIP.ip -eq $modifiedState.expectedIP)){
            $line += ($trackedIP.ip+"  forward:")
            if($trackedIP.isResolvingFWD){$line += "GOOD"}
            else{$line += "BAD"}
            $line += "(last "+$trackedIP.lastResFWD+")"
            $line += " reverse: "
            #if($trackedIP.isResolvingREV){$line += "GOOD"}
            #else{$line += "BAD"}
            #$line += "(last "+$trackedIP.lastResREV+")"
            $msgBox.Text += $line
        }
    }
}
$addFunctions= [scriptblock]::Create(@"
    function determinePinging { $Function:determinePinging }
    function determineNSResolution { $Function:determineNSResolution }
    function checkReverse { $Function:checkReverse }
"@)

#main script
$global:currentState = [monitorState]::new()
$global:currentState.operatorUsername = (whoami)[7..(whoami).length] -join ''
$global:currentState.ipList = @()

$timer.Interval = 1000
$timer.Add_Tick({
    if (-not (Get-job)) {
        $global:nsresjob = Start-Job -InitializationScript $addFunctions -ScriptBlock {param($inputObject) determineNSResolution $inputObject} -ArgumentList $global:currentState
    }
    elseif ((Get-Job) -and ((Get-Job)[0].state -like "Completed")){
        Receive-Job -job $global:nsresjob -OutVariable newState
        $global:currentState = $newState[0]
        foreach($newip in $newState[1]){
            $newIPObject = [trackedIP]::new()
            $newIPObject.isResolvingFWD = $True
            $newIPObject.lastResFWD = (Get-Date -DisplayHint Time).tostring()
            $newIPObject.ip = $newip
            $global:currentState.ipList += $newIPObject
        }
        write-host "newstate should be set"
        Remove-Job -job $global:nsresjob
        formatOutput($global:currentState)
    }
    elseif ((Get-Job)[0].state -notlike "Running"){
        Remove-Job -job $global:nsresjob
    }
})
$timer.enabled = $false

#default values for ease of testing
$usernameTBox.Text = "wm"
$hostnameTBox.Text = "lap402216"
$ipTBox.Text = "1.3.3.7"
###Display window
$form0.ShowDialog()