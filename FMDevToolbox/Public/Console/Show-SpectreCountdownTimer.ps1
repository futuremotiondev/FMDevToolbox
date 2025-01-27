using module "..\..\Private\Completions\FMCompleters.psm1"

using namespace Spectre.Console
function Show-SpectreCountdownTimer {
    param (
        [Int32] $Milliseconds = 0,
        [decimal] $Seconds = 0,
        [decimal] $Minutes = 0,
        [ValidateSet('Milliseconds', 'Seconds', 'Minutes', 'SecondsDecimal', 'SecondsAndMilliseconds',
                     'MinutesDecimal', 'MinutesAndSeconds', 'MinutesAndSecondsAndMilliseconds')]
        [String] $CountdownUnit = 'Seconds',
        [Switch] $ClearHost,
        [String] $FormatString = "Waiting for {0}...",
        [CompletionsSpectreColors()]
        [String] $SpinnerColor = "#6d9bff",
        [ValidateSet([ValidateSpectreSpinners], ErrorMessage = "Value '{0}' is invalid. Try one of: {1}")]
        [Spinner] $SpinnerStyle = [Spinner+Known]::Dots2,
        [String] $FormatSeparator = ':',
        [Switch] $AutoSuffixValues,
        [String] $MessageAfterTimeout,
        [Switch] $PauseAfterTimeout,
        [String] $PauseMessage = "[#FFFFFF]Press any key to continue.[/]"
    )

    # Pre-calculate total milliseconds
    $TotalMilliseconds = [math]::Round($Seconds * 1000) + [math]::Round($Minutes * 60000) + $Milliseconds
    if ($TotalMilliseconds -le 0) {
        Write-Error "Total runtime with passed values is less than or equal to 0ms. Specify a longer duration."
        return
    }

    # Determine decrement value based on CountdownUnit
    [Int32] $Decrement = if ($CountdownUnit -in 'Seconds', 'MinutesAndSeconds') { 1000 } else { 50 }
    $ANSIStatus = [Spectre.Console.AnsiConsole]::Status()
    $ANSIStatus.Spinner = $SpinnerStyle
    $ANSIStatus.SpinnerStyle = [Spectre.Console.Style]::Parse($SpinnerColor)

    $GetFormatString = {
        param (
            [Parameter(Mandatory)]
            [Int32] $Remaining
        )
        switch ($CountdownUnit) {
            'Milliseconds' {
                if($AutoSuffixValues){ $TotalMilliseconds = "${RunTime}ms" }
                return $FormatString -f $TotalMilliseconds
            }
            'SecondsDecimal' {
                $Sub = "{0:F2}"
                if($AutoSuffixValues){ $Sub += "s" }
                return (($FormatString -f $Sub) -f $($TotalMilliseconds / 1000))
            }
            'SecondsAndMilliseconds' {
                $sec = [math]::Floor($TotalMilliseconds / 1000) -as [System.Int32]
                $ms = $TotalMilliseconds % 1000 -as [System.Int32]
                if($sec -gt 0){ $AutoSuffix = 's' }
                else { $AutoSuffix = 'ms' }
                if($AutoSuffixValues){
                    return (($FormatString -f "{0:D2}$FormatSeparator{1:D3}$AutoSuffix") -f $sec, $ms)
                }
                return (($FormatString -f "{0:D2}$FormatSeparator{1:D3}") -f $sec, $ms)
            }
            'MinutesDecimal' {
                if($AutoSuffixValues){
                    return (($FormatString -f "{0:F2}m") -f $($TotalMilliseconds / 60000))
                }
                return (($FormatString -f "{0:F2}") -f $($TotalMilliseconds / 60000))
            }
            'Minutes' {
                [Int32] $min = [math]::Ceiling($TotalMilliseconds / 60000)
                if($AutoSuffixValues){ return $FormatString -f "${min}m" }
                return $FormatString -f $min
            }
            'MinutesAndSeconds' {
                [Int32] $min = [math]::Floor($TotalMilliseconds / 60000)
                [Int32] $sec = [math]::Floor(($TotalMilliseconds % 60000) / 1000)
                if($min -gt 0){ $AutoSuffix = 'm' }
                else{ $AutoSuffix = 's' }
                if($AutoSuffixValues){
                    return ($FormatString -f "{0:D2}$FormatSeparator{1:D2}$AutoSuffix") -f $min, $sec
                }
                return ($FormatString -f "{0:D2}$FormatSeparator{1:D2}") -f $min, $sec
            }
            'MinutesAndSecondsAndMilliseconds' {
                [Int32] $min = [math]::Floor($TotalMilliseconds / 60000)
                [Int32] $sec = [math]::Floor(($TotalMilliseconds % 60000) / 1000)
                [Int32] $mil = $TotalMilliseconds % 1000
                $AutoSuffix = "m"
                if($min -eq 0){
                    if($sec -eq 0){ $AutoSuffix = "ms" }
                    else{ $AutoSuffix = "s" }
                }
                if($AutoSuffixValues){
                    return ($FormatString -f "{0:D2}$FormatSeparator{1:D2}$FormatSeparator{2:D3}$AutoSuffix") -f $min, $sec, $mil
                }
                return ($FormatString -f "{0:D2}$FormatSeparator{1:D2}$FormatSeparator{2:D3}") -f $min, $sec, $mil
            }
            'Seconds' {
                $sec = [math]::Floor($TotalMilliseconds / 1000) -as [System.Int32]
                if($AutoSuffixValues){
                    return ($FormatString -f "${sec}s")
                }
                return ($FormatString -f "$sec")
            }
            default {
                Write-Error "Unknown Countdown Unit"
                return
            }
        }
    }

    try {
        if($ClearHost){ Clear-Host }
        $InitialValue = & $GetFormatString -Remaining $TotalMilliseconds
        $ANSIStatus.Start($InitialValue, {
            param ( [Spectre.Console.StatusContext] $Context )
            while ($TotalMilliseconds -gt 0) {
                $TotalMilliseconds = $TotalMilliseconds - $Decrement
                Start-Sleep -Milliseconds $Decrement
                $FString = & $GetFormatString -Remaining $TotalMilliseconds
                $Context.Status = $FString
                $Context.Refresh()
            }
        })
    } finally {
        if(-not([String]::IsNullOrWhiteSpace($MessageAfterTimeout))){
            Write-SpectreHost $MessageAfterTimeout
        }
        if($PauseAfterTimeout){
            Write-SpectreHost $PauseMessage
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
    }
}