#Import-Module -Force $PSScriptRoot\uielements.ps1
Import-Module -Force "C:\Users\wmiller\OneDrive - Ent Credit Union\utilities\uielements.ps1"

Add-Type -assembly System.Windows.Forms

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

function determineNSResolution($hostnameToResolve, $trackedIPList) {
    write-host $hostnameToResolve.length
    write-host $hostnameToResolve.tostring()
    $addresses = @()
    $lookupResults = (Resolve-DnsName $hostnameToResolve[0].tostring())
    foreach ($record in $lookupResults){
        if($record.Type -eq 'A'){
            $addresses += $record.IPAddress
        }
    }
    foreach ($justSeenIP in $addresses){
        $unique = 1
        foreach ($knownIP in $trackedIPList){
            if ($knownIP.Address -eq $justSeenIP){
                $knownIP.LastResolved = (Get-Date -DisplayHint Time).tostring()
                $unique = 0
            }
            if ($unique){
                $trackedIPList += @{Address = $justSeenIP; LastResolved = (Get-Date -DisplayHint Time).tostring(); LastPinged = "Never" }
            }
        }
    }
    return @($addresses, $trackedIPList)
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

function mainCycle ($hostnameToResolve, $trackedIPList) {
    return determineNSResolution($hostnameToResolve, $trackedIPList) 
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

$tickSB = {
    param($passedHostname, $passedIPList)
    mainCycle $passedHostname $passedIPList
}

$timer.Add_Tick({
    if (-not (Get-job)) {
        $global:nsresjob = Start-Job -InitializationScript $addFunctions -ScriptBlock $tickSB -ArgumentList $targetMachine, $trackedIPs
        write-host $targetMachine.gettype()
        write-host $targetMachine.length

    }
    elseif ((Get-Job) -and ((Get-Job)[0].state -like "Completed")){
        Receive-Job -job $global:nsresjob -OutVariable result
        $result.gettype()
        if($result){
            write-host $result[0] $result[1] "wrote"
            foreach($item in $result){
                write-host $item
            $msgBox.Text = $result[0]
            }
        }
        # Receive-Job -Job $global:nsresjob -OutVariable jobtext
       # $msgbox.Text = $jobtext[0]
       # write-host "cycle"
       # write-host $jobtext.gettype().tostring()
        Remove-Job -job $global:nsresjob
       # $global:result = $jobtext
    }
})
$timer.Interval = 1000

###Display window
$timer.enabled = $false
$msgBox.Text = ""


$usernameTBox.Text = "wm"
$hostnameTBox.Text = "lap402216"
$ipTBox.Text = "1.3.3.7"

$form0.ShowDialog()