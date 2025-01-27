function Show-CountdownTimer {
    <#
    .SYNOPSIS
    Displays a countdown timer in the console with various time units and formats.

    .DESCRIPTION
    The `Show-CountdownTimer` function provides a flexible countdown timer that can display time in different units such as milliseconds, seconds, or minutes. It supports custom format strings and optional spinner animation during the countdown.

    .PARAMETER Seconds
    Specifies the number of seconds for the countdown.

    .PARAMETER Milliseconds
    Specifies the number of milliseconds for the countdown.

    .PARAMETER Minutes
    Specifies the number of minutes for the countdown.

    .PARAMETER CountdownUnit
    Specifies the unit of time to display. Options include 'Milliseconds', 'Seconds', 'SecondsDecimal', 'SecondsAndMilliseconds', 'MinutesDecimal', 'MinutesAndSeconds', 'MinutesAndSecondsAndMilliseconds'.

    .PARAMETER FormatString
    Custom format string for displaying the countdown. Use [%TIME%] as a placeholder for the remaining time.

    .PARAMETER FormatSeparator
    Character used to separate time components in the output (e.g., ':').

    .PARAMETER ShowSpinner
    Switch to display a spinner animation during the countdown.

    .PARAMETER EndingMessage
    Message to display when the countdown ends.

    .PARAMETER NoNewLine
    Switch to prevent adding a newline after the countdown ends.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to start a countdown for 10 seconds.
    Show-CountdownTimer -Seconds 10

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to start a countdown for 5000 milliseconds with a custom format.
    Show-CountdownTimer -Milliseconds 5000 -FormatString "Time left: [%TIME%] ms"

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to start a countdown for 1 minute and 30 seconds with a spinner.
    Show-CountdownTimer -Minutes 1 -Seconds 30 -ShowSpinner

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to start a countdown using minutes with a custom separator and ending message.
    Show-CountdownTimer -Minutes 2 -CountdownUnit 'MinutesAndSeconds' -FormatSeparator '.' -EndingMessage "Countdown Complete!"

    .EXAMPLE
    # **Example 5**
    # This example demonstrates how to start a countdown with decimal seconds and without a newline at the end.
    Show-CountdownTimer -Seconds 5 -CountdownUnit 'SecondsDecimal' -NoNewLine

    .EXAMPLE
    # **Example 6**
    # This example demonstrates how to start a countdown for 90 seconds using the default settings.
    Show-CountdownTimer -Seconds 90

    .OUTPUTS
    None. The function writes directly to the console.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 01-18-2025
    #>
    param (
        [Parameter(Position=0)]
        [ValidateRange(1, [Int32]::MaxValue)]
        [Int32]$Seconds = 0,
        [ValidateRange(1, [Int32]::MaxValue)]
        [Int32]$Milliseconds = 0,
        [ValidateRange(1, [Int32]::MaxValue)]
        [Int32]$Minutes = 0,
        [ValidateSet('Milliseconds', 'Seconds', 'SecondsDecimal', 'SecondsAndMilliseconds',
                     'MinutesDecimal', 'MinutesAndSeconds', 'MinutesAndSecondsAndMilliseconds',
                     IgnoreCase = $true)]
        [String] $CountdownUnit = 'Seconds',
        [String] $FormatString = "Starting in [%TIME%]s...",
        [String] $FormatSeparator = ':',
        [Switch] $ShowSpinner,
        [String] $EndingMessage,
        [Switch] $NoNewLine
    )

    if (($Seconds + $Milliseconds + $Minutes) -eq 0) {
        throw "You must pass in a value to either -Seconds, -Milliseconds, or -Minutes"
    }

    $spinner = @('|', '/', '-', '\')
    $spinnerPos = 0
    $origpos = $host.UI.RawUI.CursorPosition
    [Console]::CursorVisible = $false
    $totalMilliseconds = ($Minutes * 60000) + ($Seconds * 1000) + $Milliseconds
    $runTime = $totalMilliseconds

    try {
        while ($runTime -gt 0) {
            $FormatStringNow = switch ($CountdownUnit) {
                'Milliseconds' { $FormatString -replace '\[%TIME%\]', "$runTime" }
                'SecondsDecimal' {
                    $sec = "{0:N2}" -f ($runTime / 1000)
                    $FormatString -replace '\[%TIME%\]', $sec
                }
                'SecondsAndMilliseconds' {
                    $sec = [math]::Floor($runTime / 1000) -as [System.Int32]
                    $mil = $runTime % 1000
                    $FormatString -replace '\[%TIME%\]', ("{0:D2}$FormatSeparator{1:D3}" -f $sec, $mil)
                }
                'MinutesDecimal' {
                    $min = "{0:N2}" -f ($runTime / 60000)
                    $FormatString -replace '\[%TIME%\]', $min
                }
                'MinutesAndSeconds' {
                    $min = [math]::Floor($runTime / 60000)
                    $sec = [math]::Floor(($runTime % 60000) / 1000)
                    $FormatString -replace '\[%TIME%\]', ("{0:D2}$FormatSeparator{1:D2}" -f $min, $sec)
                }
                'MinutesAndSecondsAndMilliseconds' {
                    $min = [math]::Floor($runTime / 60000)
                    $sec = [math]::Floor(($runTime % 60000) / 1000)
                    $mil = $runTime % 1000
                    $FormatString -replace '\[%TIME%\]', ("{0:D2}$FormatSeparator{1:D2}$FormatSeparator{2:D3}" -f $min, $sec, $mil)
                }
                default {
                    $remainingSeconds = [math]::Round($runTime / 1000)
                    $FormatString -replace '\[%TIME%\]', "$remainingSeconds"
                }
            }

            if ($ShowSpinner) {
                Write-Host (" {0} " -f $spinner[$spinnerPos % 4]) -NoNewline
            }
            Write-Host $FormatStringNow -NoNewline

            $host.UI.RawUI.CursorPosition = $origpos
            $spinnerPos++

            $decrement = if ($CountdownUnit -match 'Milliseconds|SecondsDecimal') { 10 } else { 1000 }
            $runTime -= $decrement
            Start-Sleep -Milliseconds $decrement
        }
    } finally {
        $consoleW = $Host.UI.RawUI.WindowSize.Width - 1
        #Write-Host $("".PadLeft($consoleW))
        Write-SpectreHost $("[#FFFFFF]$EndingMessage[/]".PadRight($consoleW))
        if(-not$NoNewLine){
            Write-Host "`n"
        }
        [Console]::CursorVisible = $true
    }
}

