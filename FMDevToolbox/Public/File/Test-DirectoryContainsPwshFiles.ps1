<#
.SYNOPSIS
    Checks if a directory contains PowerShell script files.

.DESCRIPTION
    The Test-DirectoryContainsPwshFiles function checks a specified directory for the presence of PowerShell script files.
    It can filter the search based on file extensions: .ps1, .psm1, or .psd1. By default, it searches for all these types.

.PARAMETER Directory
    The path to the directory that will be checked for PowerShell script files.

.PARAMETER Filter
    Specifies the type of PowerShell files to search for. Valid options are 'All', 'ps1', 'psm1', and 'psd1'.
    The default is 'All'.

.OUTPUTS
    System.Boolean
    Returns $true if the directory contains any PowerShell script files matching the filter; otherwise, $false.

.EXAMPLE
    Test-DirectoryContainsPwshFiles -Directory "C:\Scripts" -Filter "ps1"

    Description:
    Checks if the directory "C:\Scripts" contains any .ps1 PowerShell script files.

.EXAMPLE
    Test-DirectoryContainsPwshFiles -Directory "D:\Modules" -Filter "psm1"

    Description:
    Determines if there are any .psm1 module files in the "D:\Modules" directory.

.EXAMPLE
    Test-DirectoryContainsPwshFiles -Directory "E:\Projects"

    Description:
    Searches the "E:\Projects" directory for any PowerShell script files (.ps1, .psm1, .psd1).

.NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 11-08-2024
#>
Function Test-DirectoryContainsPwshFiles {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position=0)]
        [string] $Directory,

        [ValidateSet('All', 'ps1', 'psm1', 'psd1')]
        [string] $Filter = 'All'
    )

    $Extensions = @()
    Switch ($Filter) {
        'All'  { $Extensions = @('*.ps1', '*.psm1', '*.psd1') }
        'ps1'  { $Extensions = @('*.ps1') }
        'psm1' { $Extensions = @('*.psm1') }
        'psd1' { $Extensions = @('*.psd1') }
    }

    If (-Not (Test-Path -Path $Directory -PathType Container)) {
        Write-Warning "The directory '$Directory' does not exist."
        return $false
    }

    $PowerShellFiles = Get-ChildItem -Path $Directory -Include $Extensions -File -Recurse

    If ($PowerShellFiles.Count -gt 0) {
        return $true
    }
    else {
        return $false
    }
}

