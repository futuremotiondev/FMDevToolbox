using module "..\..\Private\Completions\FMCompleters.psm1"
function Test-ModuleIsLoaded {
    <#
    .SYNOPSIS
    Checks if a specified module is loaded in the current PowerShell session.

    .DESCRIPTION
    The Test-ModuleIsLoaded function determines whether a given module name is currently loaded in the PowerShell session. It returns a boolean value: True if the module is loaded, and False otherwise.

    .PARAMETER ModuleName
    Specifies the name of the module to check for loading status.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to check if the 'PSReadLine' module is loaded.
    Test-ModuleIsLoaded -ModuleName 'PSReadLine'

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to check if the 'Az' module is loaded using positional parameter.
    Test-ModuleIsLoaded 'Az'

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to verify the loading status of the 'Pester' module.
    if (Test-ModuleIsLoaded -ModuleName 'Pester') {
        Write-Output "Module 'Pester' is loaded."
    } else {
        Write-Output "Module 'Pester' is not loaded."
    }

    .OUTPUTS
    System.Boolean
    Returns True if the module is loaded; otherwise, False.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 12-14-2024
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [AvailableModulesCompleter()]
        [string] $Name
    )
    return [bool](Get-Module -Name $Name -ErrorAction SilentlyContinue)
}
