$targetMachine = Read-Host "Enter Hostname"
$userName = Read-Host "Enter user's name"

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


function determinePinging([str]$targetIP) {
    $global:pinging
    if (((ping -n 1 $targetIP)[2] | Select-String -Pattern "TTL").length) {
        foreach ($knownIP in $trackedIPs){
            if ($knownIP.Address -eq $targetIP){
                $knownIP.LastPinged = (Get-Date -displayhint Time)
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
    $global:currentResolution
    $addresses = @()
    $lookupResults = (nslookup $targetMachine)
    foreach ($line in $lookupResults[4..($lookupResults.length)]){
        $addresses += ($line)

    }
}