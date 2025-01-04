function Get-ConsoleWidth {
    <#
    .SYNOPSIS
    Retrieves the current console width.

    .DESCRIPTION
    The Get-ConsoleWidth function determines the width of the console window. It can retrieve this information from either the host's UI or the Spectre.Console library, depending on the provided switch parameter.

    .PARAMETER UseSpectreAnsiConsole
    If specified, attempts to use the Spectre.Console library to determine the console width.

    .OUTPUTS
    System.Int32
    The width of the console in characters.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to get the console width using the default method.
    Get-ConsoleWidth

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to get the console width using the Spectre.Console library.
    Get-ConsoleWidth -UseSpectreAnsiConsole

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to handle a scenario where the Spectre.Console library is not installed.
    try {
        Get-ConsoleWidth -UseSpectreAnsiConsole
    } catch {
        Write-Host "Failed to retrieve console width using Spectre.Console."
    }

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 2023-10-17
    #>
    [CmdletBinding()]
    param ( [Switch] $UseSpectreAnsiConsole )

    function Get-ConsoleWidthFromHost {
        try {
            return $Host.UI.RawUI.WindowSize.Width
        } catch {
            Write-Warning "`r`n Unable to retrieve console width from `$Host.UI.RawUI.WindowSize.Width.`r`n"
            $_ | Format-SpectreException -ExceptionFormat ShortenEverything
            return 0
        }
    }
    function Get-ConsoleWidthFromSpectre {
        if (-not (Get-Module -Name PwshSpectreConsole)) {
            Write-Verbose "PwshSpectreConsole not found. Attempting to import the module into the current session."
            try {
                Import-Module -Name PwshSpectreConsole -Force -ErrorAction Stop
            } catch {
                throw "`r`nImport of PwshSpectreConsole failed. Install it at https://www.powershellgallery.com/packages/PwshSpectreConsole.`r`n Details: $_"
                return 0
            }
        }
        try {
            return ([Spectre.Console.AnsiConsole]::Profile).Width
        } catch {
            Write-Warning "`r`nFailed to get width from Spectre Console.`r`n"
            $_ | Format-SpectreException -ExceptionFormat ShortenEverything
            return 0
        }
    }

    # Determine console width based on the switch parameter
    $ConsoleWidth = if ($UseSpectreAnsiConsole) {
        $Width = Get-ConsoleWidthFromSpectre
        if ($Width -lt 1) {
            Write-Verbose "Spectre width retrieval failed. Falling back to `$Host.UI.RawUI.WindowSize.Width."
            Get-ConsoleWidthFromHost
        } else {
            $Width
        }
    } else {
        Get-ConsoleWidthFromHost
    }

    # Warn if unable to determine console width
    if ($ConsoleWidth -lt 1) {
        Write-Verbose "Unable to determine console width. This may occur in non-interactive hosts."
    }

    Write-Output $ConsoleWidth
}