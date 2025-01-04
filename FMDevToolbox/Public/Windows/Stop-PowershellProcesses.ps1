using namespace System.Management.Automation
using namespace System.Security.Principal
function Stop-PowershellProcesses {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    param (
        [Parameter(Position = 0)]
        [ValidateSet('Both', 'Core', 'Desktop')]
        [String] $Version = 'Both',
        [String[]] $ExcludedHostProcesses = @('Code', 'Code - Insiders'),
        [Switch] $DisableExclusions
    )

    $processNames = @()
    if ($Version -in @('Core', 'Both')) { $processNames += 'pwsh*' }
    if ($Version -in @('Desktop', 'Both')) { $processNames += 'powershell*' }

    $processesToStop = Get-Process -Name hideexec*, singleinstanceaccumulator* -ErrorAction SilentlyContinue

    foreach ($name in $processNames) {
        $processes = Get-Process -Name $name -ErrorAction SilentlyContinue
        if (-not $DisableExclusions) {
            $processes = $processes | Where-Object { $_.Parent.ProcessName -notin $ExcludedHostProcesses }
        }
        $processesToStop += $processes
    }

    Write-Verbose "Stopping $($processesToStop.Count) processes."
    $processesToStop | Stop-Process -Force -ErrorAction Continue
}