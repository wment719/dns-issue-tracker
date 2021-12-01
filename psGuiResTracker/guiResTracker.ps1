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
    [hashtable]$state
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
    $resolvingCount=0; $pingingCount=0; $resolveAndPingCount=0
    $expectedResolving = $false; $expectedPinging = $false
    foreach($trackedIP in $inputState.iplist){
        if($trackedIP.isResolvingFWD){
            $resolvingCount += 1
            if($trackedIP.ip -eq $inputState.expectedIP){$expectedResolving = $true}
        }
        if($trackedIP.isPinging){
            $pingingCount += 1
            if($trackedIP.ip -eq $inputState.expectedIP){$expectedPinging = $true}
        }
        if($trackedIP.isResolvingFWD -and $trackedIP.isPinging){$resolveAndPingCount += 1}
    }
    $message=$inputState.targetUsername+"@  "+$inputState.targetMachine+"`n`n"
    if($resolvingCount -eq 0){
        if($expectedPinging){
            $form0.BackColor="#cccc44"#yellow
            $message+="not resolving ANY forward. Expected IP pinging.`n`n"
        } 
        else{
            $form0.BackColor="#ff3535"#ltred
            $message+="not resolving ANY forward.`n`n"
        } 
    }
    elseif($resolvingCount -eq 1){
        if($expectedResolving){
            if($expectedPinging){
                $form0.BackColor="#30d030"# green
                $message+="Pinging Expected`n`n"
            } 

            else{
                $form0.BackColor="#e060ff"#pinkish
                $message+="Resolving expected, not pinging.`n`n"
            } 
        }
        else{
            if($expectedPinging){
                if($pingingCount -gt 1){
                    $form0.BackColor="#30a0e0" #blue
                    $message+="Resolving to unexpected. Expected and other IPs pinging`n`n"
                }
                elseif($pingingCount -eq 0){
                    $form0.BackColor="#ff3535" #ltred
                    $message+="Resolving to unexpected, not pinging any`n`n"
                }
                else{
                    $form0.BackColor="#cccc44"#yellow
                    $message+="Resolving to unexpected, pinging expected`n`n"
                } 
            }
            else{
                if($pingingCount){
                    $form0.BackColor="#ff8010"#orange
                    $message+="Resolving and pinging unexpected. expected not pinging.`n`n"
                } 
                else{
                    $form0.BackColor="#ff3535"#ltred
                    $message+="Resolving unexpected not pinging any.`n`n"
                } 
            }
        } 
    }
    elseif($resolvingCount -gt 1){
        if($expectedResolving){
            if($expectedPinging){
                if($pingingCount -gt 1){
                    $form0.BackColor="#30a0e0"#blue
                    $message+="Expected resolving, pinging expected and others`n`n"
                } 
                else{
                    $form0.BackColor="#cccc44"#yellow
                    $message+="Expected resolving and pinging. Others resolving. `n`n"
                }
            }
            else{
                if($pingingCount){
                    $form0.BackColor="#30a0e0"
                    $message+="Expected resolving but not pinging. Resolving and pinging other(s). `n`n"
                } #blue
                else{
                    $form0.BackColor="#35ff35"
                    $message+="Expected and others resolving but none pinging`n`n"
                }  #ltred
            }
        }
        else{
            if($expectedPinging){
                if($pingingCount -eq 1){
                    $form0.BackColor="#cccc44"
                    $message+="Unexpected resolving but not pinging. Expected resolving and pinging. `n`n"
                } #yellow
                elseif($pingingCount -gt 1){
                    $form0.BackColor="#30a0e0"
                    $message+="Resolving unexpedcted, pinging unexpected and expected`n`n"
                }#blue
            }
            else{
                if($pingingCount){
                    $form0.BackColor="#30a0e0"
                    $message+="Resolving and pinging unexpected`n`n"

                }#blue
                else{
                    $form0.BackColor="#35ff35"
                    $message+="Resolving unexpected. Not pinging any. `n`n"

                }#ltred
            }
        }
    }
    
    $msgbox.text = ($message+$msgbox.text) 
    if($message -ne $inputState.state.state){
        $inputState.state.bounceCounter += 1
        if($inputState.state.bounceCounter -gt $inputState.state.bounceThreshold){
            if(-not ($inputState.state.state -eq "First run")){msg $inputState.operatorUsername ($message +"`nOld Status: "+$inputState.state.state)}
            $inputState.state.state=$message
            $inputState.state.bounceCounter = 0
        }
    }
    elseif($message -eq $inputState.state.state){
        $inputState.state.bounceCounter=0
    }

}

$addFunctions= [scriptblock]::Create(@"
    function determinePinging { $Function:determinePinging }
    function determineNSResolution { $Function:determineNSResolution }
"@)
#class & function definitions complete
#begin main script
$global:currentState = [monitorState]::new()
$global:currentState.operatorUsername = ((whoami) -split "\\")[1]
$global:currentState.state=@{
    time = (Get-Date -format "hh:mmtt")
    state = "First run"
    bounceThreshold = 5
    bounceCounter = 0
}

$timer.Interval = 50
$timer.Add_Tick({
    if (-not $global:currentState.ipList){ #instanciate and add expected ip if ip list is empty (firstrun)
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

###Display window
$form0.ShowDialog()