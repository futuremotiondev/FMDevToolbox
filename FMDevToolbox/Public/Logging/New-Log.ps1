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

    .PARAMETER ForcedLogFile
    Forces overwriting of the log file if specified.

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
    Date: 11-14-2024
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        $Message,
        [Parameter(Position = 1)]
        [ValidateSet("ERROR", "WARNING", "INFO", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO",
        [Parameter(Position = 2)]
        [switch]$IncludeCallerInfo = $false,
        [Parameter(Position = 3)]
        [switch]$NoConsole,
        [Parameter(Position = 4)]
        [switch]$PassThru,
        [Parameter(Position = 5)]
        [switch]$AsObject,
        [Parameter(Position = 6)]
        [switch]$ForcedLogFile,
        [Parameter(Position = 7)]
        [string]$LogFilePath
    )
    begin {
        function Write-MessageToConsole {
            if ($LogSentToConsole -eq $true) {
                return
            }
            if (!($NoConsole.IsPresent)) {
                if ($isPSCore) {
                    Write-Host $logMessage
                }
                else {
                    $logMessage | ForEach-Object { Write-Host $_ -ForegroundColor $levelColors[$Level].PS }
                }
            }
            return $true
        }
        function Set-UTF8Encoding {
            [CmdletBinding()]
            param()
            function Test-IsUTF8 {
                [CmdletBinding()]
                param()
                $isUTF8 = $false
                $encodingChecks = @(
                    {
                        $encoding = if ([Console]::OutputEncoding) {
                            [Console]::OutputEncoding
                        }
                        else {
                            [System.Console]::OutputEncoding
                        }
                        $isUTF8 = $encoding -is [System.Text.UTF8Encoding] -or $encoding.WebName -eq 'utf-8' -or $encoding.CodePage -eq 65001
                        $isUTF8
                    },
                    {
                        $encoding = $OutputEncoding
                        $isUTF8 = $encoding -is [System.Text.UTF8Encoding] -or $encoding.WebName -eq 'utf-8' -or $encoding.CodePage -eq 65001
                        $isUTF8
                    },
                    {
                        $codePage = chcp.com
                        $isUTF8 = $codePage -match '65001' -or '65001' -eq (Get-ItemPropertyValue HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage OEMCP)
                        $isUTF8
                    }
                )
                foreach ($check in $encodingChecks) {
                    try {
                        if (& $check) {
                            return $true
                        }
                    }
                    catch {
                        continue
                    }
                }
                return $false
            }
            if ($null -ne $PSDefaultParameterValues) {
                $encodingKeys = $PSDefaultParameterValues.Keys | Where-Object { $_ -like '*Encoding' }
                if ($encodingKeys.Count -eq 0) {
                    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
                    $PSDefaultParameterValues['Get-Content:Encoding'] = 'utf8'
                    $PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'
                    Write-Verbose 'Set Out-File:Encoding, Get-Content:Encoding, Set-Content:Encoding to "utf8"'
                }
                elseif ($encodingKeys.Count -ge 1) {
                    foreach ($key in $encodingKeys) {
                        $PSDefaultParameterValues[$key] = 'utf8'
                        Write-Verbose "Confirmed: ${key} = 'utf8' is [True]"
                    }
                }
            }
            else {
                $PSDefaultParameterValues = @{}
                $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
                $PSDefaultParameterValues['Get-Content:Encoding'] = 'utf8'
                $PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'
                Write-Verbose '$PSDefaultParameterValues was missing, created it and set Out-File:Encoding, Get-Content:Encoding, Set-Content:Encoding to "utf8"'
            }
            if (Test-IsUTF8 -Verbose:$VerboseParam.IsPresent) {
                Write-Verbose "UTF-8 encoding already set"
                return $true
            }
            $methods = @(
                {
                    [console]::InputEncoding = [console]::OutputEncoding = [System.Text.Encoding]::UTF8
                    $OutputEncoding = [System.Text.Encoding]::UTF8
                },
                {
                    [System.Console]::InputEncoding = [System.Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
                    $OutputEncoding = New-Object System.Text.UTF8Encoding
                },
                {
                    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
                    $OutputEncoding = [System.Text.Encoding]::UTF8
                },
                {
                    [System.Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
                    $OutputEncoding = New-Object System.Text.UTF8Encoding
                },
                {
                    chcp 65001 | Out-Null
                }
            )
            foreach ($method in $methods) {
                try {
                    & $method
                    $methodCode = $($method.ToString().Trim('{}').Split([Environment]::NewLine).Where{ $_.Trim() }.Trim() -join ' ; ')
                    $encodingsCorrect = (
                        [console]::OutputEncoding.CodePage -eq 65001 -and $OutputEncoding.CodePage -eq 65001
                    )
                    if ($methodCode -match 'chcp 65001 | Out-Null') {
                        Write-Verbose "Successfully set UTF-8 encoding using method: $methodCode"
                        $encodingsCorrect = $true
                        break
                    }
                    if ($encodingsCorrect) {
                        Write-Verbose "Successfully set UTF-8 encoding using method: $methodCode"
                        break
                    }
                    else {
                        Write-Verbose "Method: $methodCode, completed but verification failed"
                    }
                }
                catch {
                    continue
                }
            }
            if ($encodingsCorrect) {
                return $true
            }
            else {
                return $false
            }
        }
        $isPSCore = $PSVersionTable.PSVersion.Major -ge 6
        $levelColors = @{
            "ERROR"   = @{ANSI = "31"; PS = "Red" }
            "WARNING" = @{ANSI = "33"; PS = "Yellow" }
            "SUCCESS" = @{ANSI = "32"; PS = "Green" }
            "DEBUG"   = @{ANSI = "34"; PS = "Blue" }
            "INFO"    = @{ANSI = "37"; PS = "White" }
        }
        $reset = if ($isPSCore) {
            "`e[0m"
        }
        else {
            ""
        }
        $blue = if ($isPSCore) {
            "`e[34m"
        }
        else {
            ""
        }
        if (!(Set-UTF8Encoding)) {
            Write-Host "Failed to set UTF-8 encoding using any available method."
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
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            $callerInfo = (Get-PSCallStack)[1]
            $originalMessage = $Message
            $levelColor = if ($isPSCore) {
                $levelColors[$Level].ANSI
            }
            else {
                $levelColors[$Level].PS
            }
            $headerPrefix = if ($isPSCore) {
                "$reset[$blue$timestamp$reset][`e[$($levelColor)m$Level$reset]"
            }
            else {
                "[$timestamp][$Level]"
            }
            if ($Message -isnot [string]) {
                $Message = ($Message | Format-List | Out-String).Trim()
            }
            if ($callerInfo.FunctionName -ne '<ScriptBlock>' -and ($IncludeCallerInfo.IsPresent -or $Level -eq "ERROR")) {
                $functionInfo, $messageLines = if ($isPSCore) {
                    if (!($Message)) {
                        "[${blue}Function${reset}: $($callerInfo.FunctionName)]"; "$headerPrefix${_}"
                    }
                    else {
                        " [${blue}Function${reset}: $($callerInfo.FunctionName)]"; $Message -split "`n" | ForEach-Object { "$headerPrefix $_" }
                    }
                }
                else {
                    if (!($Message)) {
                        "[Function: $($callerInfo.FunctionName)]"; "$headerPrefix${_}"
                    }
                    else {
                        " [Function: $($callerInfo.FunctionName)]"; $Message -split "`n" | ForEach-Object { "$headerPrefix $_" }
                    }
                }
                $logMessage += ($messageLines -join "`n") + $functionInfo
            }
            else {
                $messageLines = if (!($Message)) {
                    "$headerPrefix${_}"
                }
                else {
                    $Message -split "`n" | ForEach-Object { "$headerPrefix $_" }
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
                    if ($isPSCore) {
                        Write-Host "$reset[$blue$timestamp$reset][$($reset)e[31mERROR$reset] An error occurred in New-Log function. $($reset)e[31m$($_.Exception.Message)$reset"
                    }
                    else {
                        Write-Host "[$timestamp][ERROR] An error occurred in New-Log function. $($_.Exception.Message)" -ForegroundColor Red
                    }
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
                if ($isPSCore) {
                    $logMessage += "[${blue}CodeRow${reset}: $lineInfo]"
                    $logMessage += "[${blue}FailedCode${reset}: $failedCode]"
                    $logMessage += "[${blue}ExceptionMessage${reset}: ${reset}`e[$($levelColors[$Level].ANSI)m$exceptionMessage$reset]"
                }
                else {
                    $logMessage += "[CodeRow: $lineInfo]"
                    $logMessage += "[FailedCode: $failedCode]"
                    $logMessage += "[ExceptionMessage: $exceptionMessage]"
                }
            }
            if (!($NoConsole.IsPresent) -and !($PassThru.IsPresent) -and !($AsObject.IsPresent) -and !($LogFilePath)) {
                $LogSentToConsole = Write-MessageToConsole
            }
            if ($LogFilePath) {
                $LogSentToConsole = Write-MessageToConsole
                $logMessage = [regex]::Replace($logMessage, $([regex]::Escape("`e") + '\[[0-9;]*[mGKHF]'), '')
                if (!(Test-Path -Path (Split-Path -Path $LogFilePath -Parent))) {
                    New-Item -Path (Split-Path -Path $LogFilePath -Parent) -ItemType Directory -Force -ErrorAction Stop | Out-Null
                }
                if ($ForcedLogFile.IsPresent) {
                    Remove-Item -Path $LogFilePath -Force -ErrorAction SilentlyContinue | Out-Null
                    Set-Content -Value $logMessage -Path $LogFilePath -Force -Encoding utf8
                }
                else {
                    $logMessage | Out-File -FilePath $LogFilePath -Append -Encoding utf8
                }
            }
            $object = [PSCustomObject]@{
                Timestamp      = $timestamp
                Level          = $Level
                Message        = if (!([string]::IsNullOrEmpty($originalMessage)) -and $originalMessage.GetType().Name -eq 'String' ) {
                    $message
                }
                else {
                    [pscustomobject](($Message | Format-List | Out-String).Trim()) -split "`n"
                }
                Exception      = if ($exceptionMessage -and !([string]::IsNullOrEmpty($exceptionMessage)) ) {
                    $exceptionMessage
                }
                else {
                    $null
                }
                CallerFunction = if (!([string]::IsNullOrEmpty($callerInfo)) -and $callerInfo.FunctionName -eq '<ScriptBlock>') {
                    $null
                }
                else {
                    $callerInfo.FunctionName
                }
                CodeRow        = if ($lineInfo -and !([string]::IsNullOrEmpty($lineInfo)) ) {
                    $lineInfo
                }
                else {
                    $null
                }
                FailedCode     = if ($FailedCode -and !([string]::IsNullOrEmpty($FailedCode)) ) {
                    $FailedCode
                }
                else {
                    $null
                }
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
            if ($isPSCore) {
                Write-Host "$reset[$blue$timestamp$reset][`e[31mERROR$reset] An error occurred in New-Log function. `e[31m$($_.Exception.Message)$reset"
            }
            else {
                Write-Host "[$timestamp][ERROR] An error occurred in New-Log function. $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}