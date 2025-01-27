using module "..\..\Private\Completions\FMCompleters.psm1"
function Confirm-ModuleIsAvailable {
    <#
    .SYNOPSIS
    Checks if a specified PowerShell module is available for import.

    .DESCRIPTION
    The `Confirm-ModuleIsAvailable` function checks the availability of a specified module
    by searching through the modules listed in the PSModulePath. It returns a boolean value
    indicating whether the module is available.

    .PARAMETER Name
    Specifies the name of the module to check for availability.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 01-11-2025
    #>

    param(
        [Parameter(Mandatory,Position=0,HelpMessage = "Module name to check availability of.")]
        [ValidateNotNullOrEmpty()]
        [AvailableModulesCompleter()]
        [String] $Name
    )
    $module = Get-Module -ListAvailable -Name $Name
    return $null -ne $module
}
