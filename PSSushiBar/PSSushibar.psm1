# private function
function Test-Environment {
    # this module supports only desktop edition
    Set-StrictMode -Version 2.0
    try {
        if ($PSVersionTable.PSEdition -eq "Desktop") {
            return $true
        }
        return $false
    }
    catch {
        # PS5.1 earlier(=Desktop Edition)
        return $true
    }
}
if (-not (Test-Environment)) {
    Write-Warning "[PSSushiBar]This environment is not supported."
    return
}
$Script:Timer = New-Object System.Timers.Timer
$Script:EventID = "_SushiBarTimer"
$Script:PrevTitle = ""
$Script:SushiCount = 0
$Script:CurrentSushiPosition = 0
$Script:SushiArray = (
    "🍣              ",
    "  🍣            ",
    "    🍣          ",
    "      🍣        ",
    "        🍣      ",
    "          🍣    ",
    "            🍣  ",
    "              🍣"
)
<#
.Synopsis
    Get sushi count.
#>
function Global:Get-SushiCount {
    [CmdletBinding()]
    param()
    # Since this function is used in the elapsed event, the scope is global.
    $result = 0
    switch ($Host.Name) {
        "Windows PowerShell ISE Host" {
            # Can't get window size on PowerShell ISE
            $result = [Math]::Ceiling($Host.UI.RawUI.BufferSize.Width / 8)
        }
        Default {
            $result = [Math]::Ceiling($Host.UI.RawUI.WindowSize.Width / 8)
        }
    }
    if ($result -gt 63) {
        $result = 63 # titlebar's max length is 1023
    }
    return $result
}

<#
.Synopsis
    Starting Sushibar flowing.
.EXAMPLE
    Start-SushiBar
.EXAMPLE
    Start-SushiBar -Interval 500
#>
function Start-SushiBar {
    [CmdletBinding()]
    param(
        [int]$Interval = 200 # msec
    )
    Set-StrictMode -Version 2.0
    if ($Script:Timer.Enabled) {
        Write-Warning "Sushi is already flowing!"
        return
    }

    # timer settings
    $Script:PrevTitle = $Host.ui.RawUI.WindowTitle
    $Script:Timer.Interval = if($Interval -lt 200){ 200 }else{ $Interval }

    # timer elapsed action
    $Script:SushiCount = Get-SushiCount
    $Script:CurrentSushiPosition = 8
    $action = {
        if ($Script:CurrentSushiPosition -le 0) {
            $Script:CurrentSushiPosition = 8
            $Script:SushiCount = Get-SushiCount
        }
        $Host.UI.RawUI.WindowTitle = $Event.MessageData[$Script:CurrentSushiPosition - 1] * $Script:SushiCount
        $Script:CurrentSushiPosition -= 1
    }

    # register event and start timer
    $params = @{
        InputObject = $Script:Timer
        SourceIdentifier = $Script:EventID
        EventName = "Elapsed"
        Action = $action
        MessageData = $Script:SushiArray
    }
    $event = Register-ObjectEvent @params
    Write-Verbose ("Register Elapsed Event (Id : {0}, Name : {1})" -f $event.Id, $event.Name)
    $Script:Timer.start()
}

<#
.Synopsis
    Stop Sushibar flowing.
.EXAMPLE
    Start-SushiBar
#>
function Stop-SushiBar {
    [CmdletBinding()]
    param()
    if (-not $Script:Timer.Enabled) {
        Write-Warning "Sushi is not flowing."
        return
    }

    # stop timer and unregister event
    $Script:Timer.Stop()
    Unregister-Event $Script:EventID
    $Host.UI.RawUI.WindowTitle = $Script:PrevTitle
    $Script:PrevTitle = ""
}