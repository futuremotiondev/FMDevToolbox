using namespace System.Management.Automation
using namespace System.Security.Principal
function Invoke-SelfElevate {
    <#
    .SYNOPSIS
    Restarts the current PowerShell script with elevated privileges.
    Enhancement of a script created by mklement0 on StackOverflow.
    UNIX / LINUX Support was removed - This script is for Windows only.
    https://stackoverflow.com/questions/69774566/how-can-i-elevate-powershell-while-keeping-the-current-working-directory-and-mai

    .DESCRIPTION
    The `Invoke-SelfElevate` function checks if the current session is running with administrative
    privileges. If not, it restarts the script with elevated permissions. It supports options to run
    without exiting the current session and to hide the execution window using `hideexec.exe`.

    If using -HideExec, you must have code.kliu.org's hideexec.exe somewhere in PATH.
    It can be downloaded here: https://code.kliu.org/

    .PARAMETER NoExit
    Prevents the current PowerShell session from closing after executing the script with elevated
    privileges.

    .PARAMETER HideExec
    Uses `hideexec.exe` to run the script in a hidden window when elevating privileges.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to restart the script with elevated privileges.
    Invoke-SelfElevate

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to restart the script with elevated privileges without closing the current session.
    Invoke-SelfElevate -NoExit

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to restart the script with elevated privileges and hide the execution window.
    Invoke-SelfElevate -HideExec

    .OUTPUTS
    None. The function does not produce any output but restarts the script with elevated privileges.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 12-18-2024
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSPossibleIncorrectUsageOfRedirectionOperator', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    [CmdletBinding()]
    param(
        [switch] $NoExit,
        [switch] $HideExec
    )

    if($NoExit -and $HideExec){
        throw "-NoExit and -HideExec cannot be used together. This would create an orphan process that cannot be closed."
    }

    # Check if already running as administrator
    if (Test-IsElevated) {
        Write-Verbose "Already elevated."
        return
    }

    # Determine script path
    $scriptPath = $PSCmdlet.GetVariableValue('PSCommandPath')
    if (-not $scriptPath) {
        throw "Unable to determine the script path (`$PSCmdlet.GetVariableValue('PSCommandPath'))."
    }

    # Prepare hideexec command if needed
    if ($HideExec) {
        Write-Verbose "-HideExec was passed. The script will try to elevate completely hidden with hideexec.exe."
        $cmd = Get-Command hideexec.exe -CommandType Application -ErrorAction SilentlyContinue
        if (-not $cmd) {
            throw "-HideExec was passed, but hideexec.exe cannot be located."
        }
        Write-Verbose "$($cmd.Name) was found at $($cmd.Source)."
        if ($cmd.Source -like "* *") {
            Write-Verbose "$($cmd.Name) has spaces in its path. Adding quotes to the path: `"$($cmd.Source)`"."
            $hideCmdPath = "`"$($cmd.Source)`""
        }
        else {
            $hideCmdPath = $cmd.Source
        }
    }

    Write-Verbose "Re-invoking script ($scriptPath) in a new window with elevation."

    # Gather necessary information
    $boundParams = $PSCmdlet.GetVariableValue('PSBoundParameters')
    $scriptArgs  = $PSCmdlet.GetVariableValue('args')
    $psExe       = (Get-Process -Id $PID).Path -replace '_ise(?=\.exe$)'
    $psExePath   = [System.IO.Path]::GetFileName($psExe)
    $noExitStr   = if ($NoExit) { '-noexit ' } else { '' }
    $fsProvPath  = (Get-Location -PSProvider FileSystem).ProviderPath
    $argsCount   = ($boundParams.Count + $scriptArgs.Count)

    Write-Verbose "Bound Parameters (Arguments) found: $boundParams"
    Write-Verbose "Script Parameters (Arguments) found: $scriptArgs"
    Write-Verbose "Total number of arguments: $argsCount"
    Write-Verbose "Powershell path currently running: $psExe"
    Write-Verbose "Current location (ProviderPath): $fsProvPath"

    # Convert switch parameters to Boolean
    Write-Verbose "Replacing switch parameters to boolean values to avoid bug."
    foreach ($key in @($boundParams.Keys)) {
        if (($Val = $boundParams[$key]) -is [switch]) {
            Write-Verbose "Switch $Val with key $Key is being re-added as a boolean."
            $null = $boundParams.Remove($key)
            $null = $boundParams.Add($key, $Val.IsPresent)
        }
    }

    if (0 -ne $argsCount) {

        $serializedArgs = [PSSerializer]::Serialize(($boundParams, (@(), $scriptArgs)[$null -ne $scriptArgs]), 1)
        $cmd = "param(`$bound, `$positional) Set-Location `"$fsProvPath`"; & `"$scriptPath`" @bound @positional"
        $encCmd  = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
        $encArgs = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($serializedArgs))

        Write-Verbose "Serialized arguments: $serializedArgs"
        Write-Verbose "Constructed command to be encoded: $cmd"
        Write-Verbose "Encoded command: $encCmd"
        Write-Verbose "Encoded arguments: $encArgs"

        if($HideExec){
            $hideCmdTemplate = "$hideCmdPath $psExePath $NoExitStr-encodedCommand $encCmd -encodedArguments $encArgs"
            Write-Verbose "Running Hidden. Command line: 'cmd.exe /c $hideCmdTemplate'"
            Start-Process -Verb RunAs cmd.exe -ArgumentList "/c $hideCmdTemplate"
        }
        else{
            $cmdTemplate = "$noExitStr-encodedCommand $encCmd -encodedArguments $encArgs"
            Write-Verbose "Running '$cmdTemplate' (-Verb RunAs)"
            Start-Process -Verb RunAs $psExe ( $cmdTemplate )
        }
    } else {
        if($HideExec){
            $hideCmdTemplate = "$hideCmdPath $psExePath $NoExitStr-c Set-Location `"$fsProvPath`"; & `"$scriptPath`""
            Write-Verbose "Running Hidden. Command line: 'cmd.exe /c $hideCmdTemplate'"
            Start-Process -Verb RunAs cmd.exe -ArgumentList "/c $hideCmdTemplate"
        }
        else{
            $cmdTemplate = "$noExitStr-c Set-Location `"$fsProvPath`"; & `"$scriptPath`""
            Write-Verbose "Running '$cmdTemplate' (-Verb RunAs)"
            Start-Process -Verb RunAs $psExe ( $cmdTemplate )
        }
    }
    if ($LASTEXITCODE -ne $null) {
        Write-Verbose "LASTEXITCODE is $LASTEXITCODE"
        exit $LASTEXITCODE
    } else {
        exit 0
    }
}
