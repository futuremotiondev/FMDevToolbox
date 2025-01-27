using namespace System.Diagnostics
function Stop-PowershellProcesses {

    <#
    .SYNOPSIS
    Stops running PowerShell processes based on specified criteria.

    .DESCRIPTION
    The `Stop-PowershellProcesses` function allows you to stop PowerShell processes based on the version and hosting environment.
    You can specify whether to terminate processes running in VSCode, VSCode Insiders, or Visual Studio.
    Additionally, you can choose to end all hosted processes or even the current shell.

    .PARAMETER Version
    Specifies the version of PowerShell processes to stop. Valid values are 'All', 'Core', and 'Desktop'. Default is 'All'.

    .PARAMETER EndVSCodeHosted
    If set, the function will terminate PowerShell processes running within VSCode.

    .PARAMETER EndVSCodeInsidersHosted
    If set, the function will terminate PowerShell processes running within VSCode Insiders.

    .PARAMETER EndVisualStudioHosted
    If set, the function will terminate PowerShell processes running within Visual Studio.

    .PARAMETER EndAllHosted
    If set, the function will terminate all PowerShell processes irrespective of host.

    .PARAMETER EndCurrentShell
    If set, the function will terminate the current PowerShell process after ending all others.

    .PARAMETER ShowRunning
    Informational parameter. If set, the function will show details of all running PowerShell processes without terminating them.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to stop all PowerShell Core processes.
    Stop-PowershellProcesses -Version 'Core'

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to stop all PowerShell processes running in VSCode.
    Stop-PowershellProcesses -EndVSCodeHosted

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to display all running PowerShell processes without stopping them.
    Stop-PowershellProcesses -ShowRunning

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to stop all PowerShell processes, including those in VSCode Insiders and Visual Studio.
    Stop-PowershellProcesses -EndVSCodeInsidersHosted -EndVisualStudioHosted

    .EXAMPLE
    # **Example 5**
    # This example demonstrates how to stop all PowerShell Desktop processes and then terminate the current shell.
    Stop-PowershellProcesses -Version 'Desktop' -EndCurrentShell

    .EXAMPLE
    # **Example 6**
    # This example demonstrates how to stop all PowerShell processes regardless of their host.
    Stop-PowershellProcesses -EndAllHosted

    .OUTPUTS
    None. The function stops processes and optionally exits the current shell.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 01-18-2025
    #>

    [CmdletBinding(DefaultParameterSetName="Default")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    param (
        [Parameter(Position=0,HelpMessage="The version of Powershell to stop (All, Core, Desktop).",ParameterSetName="Default")]
        [Parameter(Position=0,HelpMessage="The version of Powershell to stop (All, Core, Desktop).",ParameterSetName="Show")]
        [ValidateSet('All', 'Core', 'Desktop')]
        [Alias("v")]
        [String] $Version = 'All',
        [Parameter( ParameterSetName="Default", HelpMessage = "If set, the function will also terminate powershell processes running within VSCode.")]
        [Switch] $EndVSCodeHosted,
        [Parameter(ParameterSetName="Default", HelpMessage = "If set, the function will also terminate powershell processes running within VSCode Insiders.")]
        [Switch] $EndVSCodeInsidersHosted,
        [Parameter(ParameterSetName="Default", HelpMessage = "If set, the function will also terminate powershell processes running within Visual Studio.")]
        [Switch] $EndVisualStudioHosted,
        [Parameter(ParameterSetName="Default", HelpMessage = "If set, the function will terminate all powershell processes irrespective of host.")]
        [Switch] $EndAllHosted,
        [Parameter(ParameterSetName="Default", HelpMessage = "If set, the function will terminate the current powershell process after ending all others.")]
        [Switch] $EndCurrentShell,
        [Parameter(ParameterSetName="Show", HelpMessage = "Informational Parameter. If set, the function will show details of all running powershell processes.")]
        [Switch] $ShowRunning
    )

    $hostExclusions = @("Code", "Code - Insiders", "ServiceHub.Host.dotnet.x64")
    $pwshToStop = @()
    switch ($Version) {
        'Core'    { $pwshToStop += 'pwsh' }
        'Desktop' { $pwshToStop += 'powershell' }
        'All'     { $pwshToStop += 'pwsh', 'powershell' }
    }

    # Helper function to translate parent ProcessName strings to a more human readable format
    $GetParentName = {
        param ( [Parameter(Position=0)] [String] $String )
        if($String -eq 'Code'){ 'VSCode' }
        elseif($String -eq 'Code - Insiders'){ 'VSCode Insiders' }
        elseif($String -eq 'ServiceHub.Host.dotnet.x64'){ 'Visual Studio' }
        elseif($String -and ([bool]$String)){ $String }
        elseif([String]::IsNullOrWhiteSpace($String)) { 'None' }
        else{ 'Unknown' }
    }

    # Collect the current terminal's PID
    $cPID = [Process]::GetCurrentProcess().Id

    # Show an overview of running Powershell processes if -ShowRunning was passed
    if ($PSBoundParameters.ContainsKey('ShowRunning')) {
        Get-Process -Name $pwshToStop -EA 0 | Select-Object `
                @{Name='PID';     Expression = { $_.Id } },
                @{Name='Process'; Expression = { $_.ProcessName } },
                @{Name='Active';  Expression = { ( $_.Id -eq $cPID ) ? 'Yes' : 'No' } },
                @{Name='Title';   Expression = { $_.MainWindowTitle } },
                @{Name='Parent';  Expression = { & $GetParentName $_.Parent.ProcessName }
            } | Sort-Object -Property Active, 'Parent Host' -Descending | Format-Table -AutoSize
        return
    }

    # Collect Powershell processes to stop
    [process[]] $toStop = Get-Process -Name $pwshToStop -EA 0 | where { $_.Id -ne $cPID }

    # Filter processes to stop
    $toStop = $toStop | % {
        $currentProcess = $_
        $parentProcessName = $currentProcess.Parent.ProcessName
        if($parentProcessName -notin $hostExclusions){
            return $currentProcess
        }
        if( ($EndAllHosted) -or
            ($EndVSCodeHosted -and $parentProcessName -eq "Code") -or
            ($EndVSCodeInsidersHosted -and $parentProcessName -eq "Code - Insiders") -or
            ($EndVisualStudioHosted -and $parentProcessName -eq "ServiceHub.Host.dotnet.x64")){
            return $currentProcess
        }
    }

    # Stop Processes
    if($toStop){
        Write-Verbose "Stopping $($toStop.Count) processes."
        foreach ($pToStop in $toStop) {
            Write-Verbose "Function will stop process $($pToStop.Name) with PID of $($pToStop.Id)"
        }
        if(-not(Test-IsElevated)){
            Write-Verbose "Script is not elevated. Self elevating now."
            Invoke-SelfElevate -HideExec
        }
        else {
            Write-Verbose -Message "Current shell is already elevated. Stopping processes."
            $toStop | Stop-Process -Force -EA 2 | Out-Null
        }
    }
    else {
        if(-not$EndCurrentShell){
            Write-Verbose "No processes to stop that match input criteria."
            return
        }
    }
    if($EndCurrentShell){
        Write-Verbose "-EndCurrentShell was passed. Ending the current shell in 5 seconds."
        Show-CountdownTimer -Seconds 5 -CountdownUnit SecondsAndMilliseconds
        exit 0
    }
}