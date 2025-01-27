using namespace System.Web
function Get-WindowsOpenDirectories {
    <#
    .SYNOPSIS
    Retrieves a list of currently open directories in Windows Explorer.

    .DESCRIPTION
    The Get-WindowsOpenDirectories function uses the Shell.Application COM object to enumerate all
    open windows in Windows Explorer and returns their directory paths. It provides an option to
    filter these directories by a specified string.

    .PARAMETER Filter
    A string used to filter the open directories by partial name match. If not provided, all open directories are returned.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to retrieve all open directories without any filtering.
    Get-WindowsOpenDirectories

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to retrieve open directories with names containing "Documents".
    Get-WindowsOpenDirectories -Filter "Documents"

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to use the function with verbose output enabled to see processing information.
    Get-WindowsOpenDirectories -Verbose

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to store the result of open directories into a variable for further processing.
    $openDirs = Get-WindowsOpenDirectories
    $openDirs | ForEach-Object { Write-Output "Directory: $_" }

    .EXAMPLE
    # **Example 5**
    # This example demonstrates how to filter open directories using a wildcard pattern.
    Get-WindowsOpenDirectories -Filter "*Projects*"

    .OUTPUTS
    System.String[]
    Returns an array of strings representing the paths of open directories.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 01-17-2025
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    param(
        [Parameter(Position=0,HelpMessage="A filter string to match open directories by partial name.")]
        [string] $Filter
    )
    try {
        $oWindows = (New-Object -ComObject 'Shell.Application').Windows()
        if($oWindows.Count -eq 0){
            Write-Verbose "No directories are open."
            return
        }

        Write-Verbose "Found $($oWindows.Count) open directories."
        [string[]] $wList = $oWindows | % {
            $directory = [HttpUtility]::UrlDecode($_.LocationURL.TrimStart('file:///').Replace('/','\'))
            if (-not $Filter -or $directory -like "*$Filter*") {
                $directory
            }
        }
    }
    catch {
       Write-Error "Failed to retrieve open directories. Error details: $_"
    }
    Write-Verbose -Message "Open directories found: `r`n• $($wList -join "`r`n• ")"
    ,$wList
}