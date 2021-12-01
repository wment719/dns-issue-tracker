Add-Type -assembly System.Windows.Forms
$IPPattern = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"


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
        $global:currentState.targetUsername = $usernameTBox.text; $global:currentState.targetMachine = $hostnameTBox.Text; $global:currentState.expectedIP = $ipTBox.Text
        $form0.Text=$usernameTBox.Text+" at "+$hostnameTBox.Text+"  expected IP: "+$ipTBox.Text
        $timer.Enabled = $True
        $goButton.Text = "update"
    }
})
$form0.Controls.Add($goButton)

$msgBox = New-Object System.Windows.Forms.Label
$msgBox.Text = ""; $msgBox.AutoSize = $false
$msgBox.Location = New-Object System.Drawing.Point(5, 85)
$msgBox.Size = New-Object System.Drawing.Size(375,300)
$msgBox.TextAlign ="TopCenter"
$form0.Controls.Add($msgBox)


###Set up timer

$timer = New-Object System.Windows.Forms.Timer

$timer.Enabled = $False