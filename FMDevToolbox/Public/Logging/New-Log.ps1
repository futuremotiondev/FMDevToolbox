function New-Log {
    <#
    .SYNOPSIS
    Logs messages with ANSI color support and optional caller information.

    .DESCRIPTION
    The New-Log function logs messages to the console or a specified log file with ANSI color support. It supports different log levels, including ERROR, WARNING, INFO, SUCCESS, and DEBUG. The function can include caller information in the log message and handle errors gracefully.

    .PARAMETER Message
    The message to be logged. Can be a string, hashtable, or PSCustomObject.

    .PARAMETER Level
    Specifies the log level. Valid values are "ERROR", "WARNING", "INFO", "SUCCESS", and "DEBUG". Defaults to "INFO".

    .PARAMETER IncludeCallerInfo
    Includes the caller's function name in the log message if specified.

    .PARAMETER NoConsole
    Prevents the message from being logged to the console if specified.

    .PARAMETER PassThru
    Returns the log message as a string or object instead of logging it to the console.

    .PARAMETER AsObject
    Returns the log message as a PSCustomObject.

    .PARAMETER LogFilePath
    Specifies the path to the log file where the message should be logged.

    .OUTPUTS
    String or PSCustomObject depending on the parameters used.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to log an informational message to the console.
    New-Log -Message "The process completed successfully." -Level "INFO"

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to log a warning message with caller information included.
    New-Log -Message "This is a warning message." -Level "WARNING" -IncludeCallerInfo

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to log an error message to a specified log file.
    New-Log -Message "A critical error occurred." -Level "ERROR" -LogFilePath "C:\Logs\error.log"

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to return the log message as a PSCustomObject.
    $logObject = New-Log -Message "Debugging information." -Level "DEBUG" -AsObject -PassThru
    Write-Output $logObject

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 02-26-2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        $Message,
        [Parameter(Position = 1)]
        [ValidateSet("ERROR", "WARNING", "INFO", "SUCCESS", "DEBUG")]
        [string] $Level = "INFO",
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $IncludeCallerInfo = $false,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $NoConsole,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $PassThru,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $AsObject,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $LogFilePath,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $LogToFile,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet( 'yyyy-MM-dd hh:mm:ss tt', 'yyyy-MM-dd HH:mm:ss tt',
                      'yyyy-MM-dd | hh:mm:ss.fff', 'yyyy-MM-dd', 'HH:mm:ss',
                      'HH:mm:ss fff', 'HH:mm:ss.fff', 'HH:mm:ss tt', 'yyyy-MM-dd fff'
        )]
        [String] $TimestampFormat = 'yyyy-MM-dd hh:mm:ss tt'
    )
    begin {

        $UTF8_ENC = [System.Text.UTF8Encoding]::new($true)

        function Write-MessageToConsole {
            if ($LogSentToConsole -eq $true) { return }
            if (-not ($NoConsole.IsPresent)) {
                Write-Host $logMessage
            }
            return $true
        }

        function Set-UTF8Encoding {
            [CmdletBinding()]
            param()
            $encodingMethods = @(
                { [console]::InputEncoding = [console]::OutputEncoding = [System.Text.Encoding]::UTF8 },
                { chcp 65001 | Out-Null }
            )
            foreach ($method in $encodingMethods) {
                try {
                    & $method
                    if ([console]::OutputEncoding.CodePage -eq 65001) {
                        return $true
                    }
                } catch {
                    continue
                }
            }
            return $false
        }

        $levelColors = @{
            "ERROR"   = @{ ANSI = (Get-ANSIColorSequenceFrom1Hex -HexColor "#F7627D" -Unescaped).TrimEnd('m') }
            "WARNING" = @{ ANSI = (Get-ANSIColorSequenceFrom1Hex -HexColor "#EAA18F" -Unescaped).TrimEnd('m') }
            "SUCCESS" = @{ ANSI = (Get-ANSIColorSequenceFrom1Hex -HexColor "#52EFC2" -Unescaped).TrimEnd('m') }
            "DEBUG"   = @{ ANSI = (Get-ANSIColorSequenceFrom1Hex -HexColor "#7C808D" -Unescaped).TrimEnd('m') }
            "INFO"    = @{ ANSI = (Get-ANSIColorSequenceFrom1Hex -HexColor "#D8DFE6" -Unescaped).TrimEnd('m') }
        }

        $reset = "`e[0m"
        $tsBracketColor = Get-ANSIColorSequenceFrom1Hex -HexColor "#959CA3"
        $tsColor = Get-ANSIColorSequenceFrom2Hex -Foreground "#727B80" -Background "#141619"
        if (!(Set-UTF8Encoding)) {
            Write-Warning "Failed to set UTF-8 encoding using any available method."
        }
    }
    Process {
        if ($null -eq $Message -and $Level -ne "ERROR") {
            return
        }
        try {
            @('exceptionMessage', 'failedCode', 'scriptLines', 'lineInfo') | ForEach-Object { Set-Variable -Name $_ -Value $null }
            if ($Message -and $Message.GetType().Name -eq 'Hashtable') {
                $Message = New-Object -TypeName PSObject -Property $Message
            }
            if ($Message -and $Message.GetType().Name -notin @("PSCustomObject", "Hashtable", "String", "Software")) {
                Write-Host "Unsupported message type: $($Message.GetType().Name). Must be PSCustomObject, Hashtable or string" -ForegroundColor Red
                return
            }
            $logSentToConsole = $false
            $logMessage = ''

            $timestamp = Get-Date -Format $TimestampFormat

            $callerInfo = (Get-PSCallStack)[1]
            $originalMessage = $Message
            $levelColor = $levelColors[$Level].ANSI
            $headerPrefix = "$reset$tsBracketColor[$reset$tsColor$timestamp$reset$tsBracketColor]$reset [`e[$($levelColor)m$Level$reset]"


            if ($Message -isnot [string]) {
                $Message = ($Message | Format-List | Out-String).Trim()
            }


            if ($callerInfo.FunctionName -ne '<ScriptBlock>' -and ($IncludeCallerInfo.IsPresent -or $Level -eq "ERROR")) {
                $functionInfo = if(!$Message){
                    "[${blue}Function${reset}: $($callerInfo.FunctionName)]"
                }
                else {
                    " [${blue}Function${reset}: $($callerInfo.FunctionName)]"
                }

                $messageLines = if(!$Message){
                    "$headerPrefix${_}"
                }
                else {
                    $Message -split "`n" | % { "$headerPrefix $_" }
                }

                if(!$IncludeCallerInfo){
                    $logMessage += ($messageLines -join "`n")
                }
                else {
                    Write-Host -f Green "`$IncludeCallerInfo:" $IncludeCallerInfo
                    $logMessage += ($messageLines -join "`n") + $functionInfo
                }

            }
            else {
                $messageLines = if (!($Message)) {
                    "$headerPrefix${_}"
                }
                else {
                    $Message -split "`n" | % { "$headerPrefix $_" }
                }
                $logMessage += $messageLines -join "`n"
            }

            if ($Level -eq "ERROR" -and $Error[0]) {
                $errorRecord = $Error[0]
                $invocationInfo = $errorRecord.InvocationInfo
                try {
                    if ($ErrorRecord.InvocationInfo.PSCommandPath -and (Test-Path -Path $errorRecord.InvocationInfo.PSCommandPath)) {
                        $scriptLines = Get-Content -Path "$($errorRecord.InvocationInfo.PSCommandPath)" -ErrorAction Stop
                    }
                    elseif ($ErrorRecord.InvocationInfo.ScriptName -and (Test-Path -Path $errorRecord.InvocationInfo.ScriptName)) {
                        $scriptLines = Get-Content -Path "$($errorRecord.InvocationInfo.ScriptName)" -ErrorAction Stop
                    }
                }
                catch {
                    Write-Host "$reset$tsBracketColor[$reset$tsColor$timestamp$reset$tsBracketColor]$reset [$($reset)e[31mERROR$reset] An error occurred in New-Log function. $($reset)e[31m$($_.Exception.Message)$reset"
                }
                $functionName = $callerInfo.Command
                $failedCode = if ($invocationInfo.Line) {
                    $invocationInfo.Line.Trim()
                }
                else {
                    $null
                }
                [int]$errorLine = $errorRecord.InvocationInfo.ScriptLineNumber
                if ([string]::IsNullOrEmpty($errorLine)) {
                    [int]$errorLine = $invocationInfo.ScriptLineNumber
                }
                if (!([string]::IsNullOrEmpty($scriptLines))) {
                    [int]$functionStartLine = ($scriptLines | Select-String -Pattern "function\s+$functionName" | Select-Object -First 1).LineNumber
                    $lineNumberInFunction = $errorLine - $functionStartLine
                    $lineInfo = "($lineNumberInFunction,$errorLine) (Function,Script)"
                    if ($callerInfo.FunctionName -eq '<ScriptBlock>') {
                        $lineInfo = "$errorLine (Script)"
                    }
                }
                else {
                    $lineNumberInFunction = $errorLine - ([int]$callerInfo.ScriptLineNumber - [int]$invocationInfo.OffsetInLine) - 1
                    $lineInfo = "($lineNumberInFunction,$errorLine) (Function,Script)"
                    if ($callerInfo.FunctionName -eq '<ScriptBlock>') {
                        $lineInfo = "$errorLine (Script)"
                    }
                }
                $exceptionMessage = $($errorRecord.Exception.Message)
                $logMessage += "[${blue}CodeRow${reset}: $lineInfo]"
                $logMessage += "[${blue}FailedCode${reset}: $failedCode]"
                $logMessage += "[${blue}ExceptionMessage${reset}: ${reset}`e[$($levelColors[$Level].ANSI)m$exceptionMessage$reset]"

            }
            if (!($NoConsole.IsPresent) -and !($PassThru.IsPresent) -and !($AsObject.IsPresent) -and !($LogFilePath)) {
                $LogSentToConsole = Write-MessageToConsole
            }
            if ($LogFilePath) {
                $LogSentToConsole = Write-MessageToConsole
                if($LogToFile){
                    $logMessage = [regex]::Replace($logMessage, $([regex]::Escape("`e") + '\[[0-9;]*[mGKHF]'), '')
                    if (!(Test-Path -Path (Split-Path -Path $LogFilePath -Parent))) {
                        New-Item -Path (Split-Path -Path $LogFilePath -Parent) -ItemType Directory -Force -ErrorAction Stop | Out-Null
                    }
                    else {
                        [System.IO.File]::AppendAllText($LogFilePath, $logMessage, $UTF8_ENC)
                    }
                }
            }

            $object = [PSCustomObject]@{
                Timestamp = $timestamp
                Level = $Level
                Message = if (!([string]::IsNullOrEmpty($originalMessage)) -and $originalMessage.GetType().Name -eq 'String' ) { $message }
                else { [pscustomobject](($Message | Format-List | Out-String).Trim()) -split "`n" }
                Exception = if ($exceptionMessage -and !([string]::IsNullOrEmpty($exceptionMessage)) ) { $exceptionMessage }
                else { $null }
                CallerFunction = if (!([string]::IsNullOrEmpty($callerInfo)) -and $callerInfo.FunctionName -eq '<ScriptBlock>') { $null }
                else { $callerInfo.FunctionName }
                CodeRow = if ($lineInfo -and !([string]::IsNullOrEmpty($lineInfo)) ) { $lineInfo }
                else { $null }
                FailedCode = if ($FailedCode -and !([string]::IsNullOrEmpty($FailedCode)) ) { $FailedCode }
                else { $null }
            }
            if ($PassThru.IsPresent -and $AsObject.IsPresent) {
                $LogSentToConsole = Write-MessageToConsole
                return $object
            }
            elseif ($PassThru.IsPresent -and !($AsObject.IsPresent)) {
                $LogSentToConsole = Write-MessageToConsole
                return $logMessage
            }
            elseif (!($NoConsole.IsPresent) -and $AsObject.IsPresent) {
                $object | Out-Host
            }
        }
        catch {
            Write-Host "$reset$tsBracketColor[$reset$tsColor$timestamp$reset$tsBracketColor]$reset [`e[31mERROR$reset] An error occurred in New-Log function. `e[31m$($_.Exception.Message)$reset"
        }
    }
}

