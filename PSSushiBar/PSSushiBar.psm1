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
    $MaxCount = 63 # Windows titlebar's max length is 1023
    $result = 0
    switch ($Host.Name) {
        "Windows PowerShell ISE Host" {
            # Can't get window size on PowerShell ISE, so use Buffersize.
            $result = [Math]::Ceiling($Host.UI.RawUI.BufferSize.Width / 8)
        }
        "Visual Studio Code Host" {
            # Can't get status bar size on vscode-powershell
            # set fixed value tentatively.
            $result = 8
        }
        Default {
            # Default (ConsoleHost)
            $result = [Math]::Ceiling($Host.UI.RawUI.WindowSize.Width / 8)
        }
    }
    if ($result -gt $MaxCount) {
        $result = $MaxCount 
    }
    return $result
}

# private function
function GetTitle {
    switch ($Host.Name) {
        "Visual Studio Code Host" {
            # $psEditor don't support GetStatusBarMessage
            return ""
        }
        Default {
            return $Host.UI.RawUI.WindowTitle
        }
    }
}

# private function
function SetTitle([string]$Title) {
    switch ($Host.Name) {
        "Visual Studio Code Host" {
            if ($null -ne $psEditor) {
                $psEditor.Window.SetStatusBarMessage($Title)
            }
        }
        Default {
            $Host.UI.RawUI.WindowTitle = $Title
        }
    }
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
    $Script:PrevTitle = GetTitle
    $Script:Timer.Interval = if ($Interval -lt 200) {
        200
    }
    else {
        $Interval
    }

    # timer elapsed action
    $Script:SushiCount = Get-SushiCount
    $Script:CurrentSushiPosition = 8
    $action = {
        if ($Script:CurrentSushiPosition -le 0) {
            $Script:CurrentSushiPosition = 8
            $Script:SushiCount = Get-SushiCount
        }
        & $Event.MessageData.SetTitle -Title ($Event.MessageData.SushiArray[$Script:CurrentSushiPosition - 1] * $Script:SushiCount)
        $Script:CurrentSushiPosition -= 1
    }

    # register event and start timer
    $params = @{
        InputObject = $Script:Timer
        SourceIdentifier = $Script:EventID
        EventName = "Elapsed"
        Action = $action
        MessageData = @{
            SetTitle = Get-Command SetTitle
            SushiArray = $Script:SushiArray;
        }
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
    SetTitle -Title $Script:PrevTitle
    $Script:PrevTitle = ""
}