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
$Global:Timer = New-Object System.Timers.Timer
$Global:EventLocation = "Sushibar"
$Global:EventID = "_SushiBarTimer"
$Global:PrevTitle = ""
$Global:SushiCount = 0
$Global:CurrentSushiPosition = 0
$Global:SushiArray = (
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
    if ($Global:Timer.Enabled) {
        Write-Warning "Sushi is already flowing!"
        return
    }

    # timer settings
    $Global:PrevTitle = $Host.ui.RawUI.WindowTitle
    $Global:Timer.Interval = if($Interval -lt 200){ 200 }else{ $Interval }

    # timer elapsed action
    $Global:SushiCount = Get-SushiCount
    $Global:CurrentSushiPosition = 8
    $action = {
        if ($Global:CurrentSushiPosition -le 0) {
            $Global:CurrentSushiPosition = 8
            $Global:SushiCount = Get-SushiCount
        }
        $Host.UI.RawUI.WindowTitle = $Global:SushiArray[$Global:CurrentSushiPosition - 1] * $Global:SushiCount
        $Global:CurrentSushiPosition -= 1
    }

    # register event and start timer
    $params = @{
        InputObject = $Global:Timer
        SourceIdentifier = $Global:EventID
        EventName = "Elapsed"
        Action = $action
    }
    Register-ObjectEvent @params | Out-Null
    $Global:Timer.start()
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
    if (-not $Global:Timer.Enabled) {
        Write-Warning "Sushi is not flowing."
        return
    }

    # stop timer and unregister event
    $Global:Timer.Stop()
    Unregister-Event $Global:EventID
    $Host.UI.RawUI.WindowTitle = $Global:PrevTitle
    $Global:PrevTitle = ""
}