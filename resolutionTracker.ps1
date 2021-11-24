$targetMachine = Read-Host "Enter Hostname"
$userName = Read-Host "Enter user's name"
$me=(whoami)[7..(whoami).length] -join ''

$IPPattern = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"

$validIP = 0
do {
    $rightIP= Read-Host "Enter expected IP"
    if ($rightIP -match $IPPattern) {
        break
    }
    else {
        echo "Invalid IP."
    }
}
while (1)
Clear-Host

$firstRun = 1 
$trackedIPs = @()


function determinePinging($targetIP) {
    $global:pinging
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


function determineNSResolution {
    $addresses = @()
    $lookupResults = (Resolve-DnsName $targetMachine)
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
    $Global:currentResolution = $addresses
}

function checkReverse {
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

$status = @("firstrun", (Get-Date -DisplayHint Time).tostring())

function statusUpdate($newStatus){
    if ($newStatus -ne $Global:status){
        $host.ui.rawui.windowtitle = $targetMachine+" "+$userName+" "+$newStatus
        if($Global:status -ne 'firstrun'){
            msg me $userName+" at "+$targetMachine+"
            old status [since "+$Global:status[1]+"] "+$Global:status[0]+"
            new status [since "+(Get-Date -DisplayHint Time).tostring()+"] "+$newStatus
        }
        $Global:status = ($newStatus, (Get-Date -DisplayHint Time).tostring())
    }
}

do {
    if( -not $firstRun){
        write-host "not first run"
    }

    determineNSResolution
    write-host $currentResolution
    $a=determinePinging($currentResolution[0])
    Write-Host $a
    sleep 1

}
while (1)