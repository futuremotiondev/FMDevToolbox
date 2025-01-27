using module "..\..\Private\Completions\FMCompleters.psm1"

using namespace Spectre.Console
using namespace System.Collections.Generic
using namespace System.Text.RegularExpressions

function New-LogSpectre {
    <#
    .SYNOPSIS
    Logs messages with various levels and formats using Spectre.Console.

    .DESCRIPTION
    The `New-LogSpectre` function logs messages to the console or a file with specified colors and formats. It supports different log levels such as ERROR, WARNING, INFO, SUCCESS, and DEBUG. The function can also include caller information and handle error logging with detailed information about the error context.

    .PARAMETER Message
    Specifies the message to log. Supports string, hashtable, PSCustomObject, and Software types.

    .PARAMETER Level
    Specifies the log level. Valid values are ERROR, WARNING, INFO, SUCCESS, and DEBUG. Default is INFO.

    .PARAMETER IncludeCallerInfo
    Includes caller function information in the log if specified.

    .PARAMETER NoConsole
    Prevents logging to the console if specified.

    .PARAMETER PassThru
    Returns the log message or object instead of writing it to the console.

    .PARAMETER AsObject
    Returns the log details as a PSCustomObject when used with PassThru.

    .PARAMETER OverwriteLogFile
    Overwrites the existing log file if specified.

    .PARAMETER LogFilePath
    Specifies the path to the log file where the message should be written.

    .PARAMETER TimestampColor
    Specifies the color for the timestamp in the log message.

    .PARAMETER DefaultTextColor
    Specifies the default text color for the log message.

    .PARAMETER DebugColor
    Specifies the color for DEBUG level messages.

    .PARAMETER ErrorColor
    Specifies the color for ERROR level messages.

    .PARAMETER InfoColor
    Specifies the color for INFO level messages.

    .PARAMETER SuccessColor
    Specifies the color for SUCCESS level messages.

    .PARAMETER WarningColor
    Specifies the color for WARNING level messages.

    .PARAMETER InternalErrorColor
    Specifies the color for internal error messages.

    .OUTPUTS
    PSCustomObject if AsObject is specified; otherwise, writes formatted log messages to the console or file.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to log an informational message to the console.
    New-LogSpectre -Message "The process completed successfully." -Level "INFO"

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to log a warning message to a file.
    New-LogSpectre -Message "Disk space is running low." -Level "WARNING" -LogFilePath "C:\Logs\system.log"

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to log an error message with caller information.
    try {
        Get-ChildItem -Path "C:\nonexistentpath" -ErrorAction Stop
    } catch {
        New-LogSpectre -Message $_ -Level "ERROR" -IncludeCallerInfo
    }

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to return a log message as an object.
    $logObject = New-LogSpectre -Message "Debugging mode enabled." -Level "DEBUG" -PassThru -AsObject
    Write-Output $logObject

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 11-14-2024
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline,Position=0)] $Message,
        [ValidateSet("ERROR", "WARNING", "INFO", "SUCCESS", "DEBUG", IgnoreCase=$true)]
        [string] $Level = "INFO",
        [switch] $IncludeCallerInfo = $false,
        [switch] $NoConsole,
        [switch] $PassThru,
        [switch] $AsObject,
        [switch] $OverwriteLogFile,
        [string] $LogFilePath,
        [CompletionsSpectreColors()]
        [String] $TimestampColor="#dde1e6",
        [CompletionsSpectreColors()]
        [String] $DefaultTextColor="#a0a4ab",
        [CompletionsSpectreColors()]
        [String] $DebugColor="#dfe4eb",
        [CompletionsSpectreColors()]
        [String] $ErrorColor="#f57a88",
        [CompletionsSpectreColors()]
        [String] $InfoColor="#c8d1df",
        [CompletionsSpectreColors()]
        [String] $SuccessColor="#8cddb9",
        [CompletionsSpectreColors()]
        [String] $WarningColor="#eab077",
        [CompletionsSpectreColors()]
        [String] $InternalErrorColor="#f0a2a2"
    )

    begin {
        $levelColors = @{
            "ERROR"   = $ErrorColor
            "WARNING" = $WarningColor
            "SUCCESS" = $SuccessColor
            "DEBUG"   = $DebugColor
            "INFO"    = $InfoColor
        }
        try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 }
        catch { Write-SpectreHost "[#DCDFE5]Notice:[/] [#ABB1BC]Unable to set console encoding to [#FFFFFF]UTF8[/][/]" }
    }

    process {

        if ($null -eq $Message -and $Level -ne "ERROR") { return }

        $sEscapeL = Get-SpectreEscapedText -Text "["
        $sEscapeR = Get-SpectreEscapedText -Text "]"

        try {
            @('exceptionMessage', 'failedCode', 'scriptLines', 'lineInfo') |
                ForEach-Object { Set-Variable -Name $_ -Value $null }

            if ($Message -is [hashtable]) { $Message = [pscustomobject]$Message }

            # Check for unsupported message types
            $validTypes = [HashSet[string]]::new()
            $validTypes.Add("PSCustomObject") | Out-Null
            $validTypes.Add("Hashtable") | Out-Null
            $validTypes.Add("String") | Out-Null
            $validTypes.Add("Software") | Out-Null

            if ($Message -and -not $validTypes.Contains($Message.GetType().Name)) {
                $UnsupportedMsg = "Must be PSCustomObject, Hashtable, String, or Software"
                New-Log "Unsupported message type: $($Message.GetType().Name). $UnsupportedMsg" -ForegroundColor Red
                return
            }

            # Initialize variables
            $logSentToConsole = $false
            $logMessage = ''
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            $callerInfo = (Get-PSCallStack)[1]
            $originalMessage = $Message
            $levelColor = $levelColors[$Level]

            $headerPrefix = "$sEscapeL[$TimestampColor]$timestamp[/]$sEscapeR $sEscapeL[$levelColor]$Level[/]$sEscapeR"
            $headerPrefixFile = "[$timestamp] [$Level]"

            # Format message if not a string
            if ($Message -isnot [string]) { $Message = ($Message | Format-List | Out-String).Trim() }

            # Include caller info if necessary
            $includeFunctionInfo = $callerInfo.FunctionName -ne '<ScriptBlock>' -and ($IncludeCallerInfo.IsPresent -or $Level -eq "ERROR")
            $functionInfo = if ($includeFunctionInfo) { "$sEscapeL[$TimestampColor]Function:[/] $($callerInfo.FunctionName)$sEscapeR" } else { "" }
            $functionInfoFile = if ($includeFunctionInfo) { "[Function: $($callerInfo.FunctionName)]" } else { "" }

            $messageLines = if ($Message) {
                $Message -split "`n" | ForEach-Object { "$headerPrefix [$DefaultTextColor]$_[/]" }
            } else {
                "$headerPrefix${_}"
            }

            $messageLinesFile = if ($Message) {
                $Message -split "`n" | ForEach-Object { "$headerPrefixFile $_" }
            } else {
                "$headerPrefixFile${_}"
            }

            $logMessage += ($messageLines -join "`n") + $functionInfo
            $logMessageFile += ($messageLinesFile -join "`n") + $functionInfoFile

            # Handle error logging
            if ($Level -eq "ERROR" -and $Error[0]) {
                $errorRecord = $Error[0]
                $invocationInfo = $errorRecord.InvocationInfo

                try {
                    $scriptPath = $errorRecord.InvocationInfo.PSCommandPath ?? $errorRecord.InvocationInfo.ScriptName
                    if ($scriptPath -and (Test-Path -Path $scriptPath)) {
                        $scriptLines = Get-Content -Path $scriptPath -ErrorAction Stop
                    }
                } catch {
                    Write-SpectreHost "$sEscapeL[$TimestampColor]$timestamp[/]$sEscapeR$sEscapeL[$InternalErrorColor]INTERNAL_ERROR[/]$sEscapeR An error occurred in New-Log function."
                    Write-SpectreHost "[$InternalErrorColor]$($_.Exception.Message)[/]"
                }

                $functionName = $callerInfo.Command
                $failedCode = $invocationInfo.Line?.Trim()
                [int]$errorLine = $errorRecord.InvocationInfo.ScriptLineNumber ?? $invocationInfo.ScriptLineNumber

                if ($scriptLines) {
                    [int]$functionStartLine = ($scriptLines | Select-String -Pattern "function\s+$functionName" | Select-Object -First 1).LineNumber
                    $lineNumberInFunction = $errorLine - $functionStartLine
                    $lineInfo = "($lineNumberInFunction,$errorLine) (Function,Script)"
                    if ($callerInfo.FunctionName -eq '<ScriptBlock>') {
                        $lineInfo = "$errorLine (Script)"
                    }
                } else {
                    $lineNumberInFunction = $errorLine - ([int]$callerInfo.ScriptLineNumber - [int]$invocationInfo.OffsetInLine) - 1
                    $lineInfo = "($lineNumberInFunction,$errorLine) (Function,Script)"
                    if ($callerInfo.FunctionName -eq '<ScriptBlock>') {
                        $lineInfo = "$errorLine (Script)"
                    }
                }

                $exceptionMessage = $errorRecord.Exception.Message
                $logMessage += "$sEscapeL[$InternalErrorColor]CodeRow:[/] $lineInfo$sEscapeR"
                $logMessage += "$sEscapeL[$InternalErrorColor]FailedCode:[/] $failedCode$sEscapeR"
                $logMessage += "$sEscapeL[$InternalErrorColor]ExceptionMessage:[/] [$ErrorColor]$exceptionMessage[/]$sEscapeR"
                $logMessageFile += "CodeRow: $lineInfo"
                $logMessageFile += "FailedCode: $failedCode"
                $logMessageFile += "ExceptionMessage: $exceptionMessage"
            }

            function Write-MessageToConsole {
                if ($LogSentToConsole -eq $true) { return }
                if (-not($NoConsole.IsPresent)) { Write-SpectreHost $logMessage }
                return $true
            }

            # Log to console if conditions are met
            if (!($NoConsole.IsPresent) -and !($PassThru.IsPresent) -and !($AsObject.IsPresent) -and !$LogFilePath) {
                $LogSentToConsole = Write-MessageToConsole
            }

            # Handle log file writing
            if ($LogFilePath) {
                $LogSentToConsole = Write-MessageToConsole
                $parentDir = Split-Path -Path $LogFilePath -Parent
                if (-not (Test-Path -Path $parentDir)) {
                    New-Item -Path $parentDir -ItemType Directory -Force
                }
                if ($OverwriteLogFile.IsPresent) {
                    Remove-Item -Path $LogFilePath -Force -ErrorAction SilentlyContinue
                    Set-Content -Value $logMessageFile -Path $LogFilePath -Force -Encoding utf8
                } else {
                    Add-Content -Value $logMessageFile -Path $LogFilePath -Encoding utf8
                }
            }

            $object = [PSCustomObject]@{
                Timestamp      = $timestamp
                Level          = $Level
                Message        = if ($originalMessage -is [string]) { $Message } else { $Message | Out-String }
                Exception      = if (-not [string]::IsNullOrEmpty($exceptionMessage)) { $exceptionMessage } else { $null }
                CallerFunction = if ($callerInfo.FunctionName -eq '<ScriptBlock>') { $null } else { $callerInfo.FunctionName }
                CodeRow        = if (-not [string]::IsNullOrEmpty($lineInfo)) { $lineInfo } else { $null }
                FailedCode     = if (-not [string]::IsNullOrEmpty($FailedCode)) { $FailedCode } else { $null }
            }

            if ($PassThru.IsPresent) {
                $LogSentToConsole = Write-MessageToConsole
                return if ($AsObject.IsPresent) { $object } else { $logMessage }
            } elseif (!$NoConsole.IsPresent -and $AsObject.IsPresent) {
                $object | Out-Host
            }
        }
        catch {
            Write-SpectreHost "$sEscapeL[$TimestampColor]$timestamp[/]$sEscapeR$sEscapeL[$ErrorColor]ERROR[/]$sEscapeR [$DefaultTextColor]An error occurred in New-Log function.[/] [$ErrorColor]$($_.Exception.Message)[/]"
        }
    }
}