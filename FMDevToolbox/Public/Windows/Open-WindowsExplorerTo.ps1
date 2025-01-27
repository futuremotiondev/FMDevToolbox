function Open-WindowsExplorerTo {
    <#
    .SYNOPSIS
    Opens Windows Explorer to specified directories.

    .DESCRIPTION
    The Open-WindowsExplorerTo function opens Windows Explorer windows to the specified paths.
    It supports both wildcard and literal paths, as well as reading paths from a file.
    You can also specify the window style for the opened Explorer windows and simulate the operation without actually opening them.

    .PARAMETER Path
    Specifies the path(s) to open in Windows Explorer. Supports wildcards.

    .PARAMETER LiteralPath
    Specifies the path(s) to open in Windows Explorer without wildcards.

    .PARAMETER File
    Specifies a file containing paths to open in Windows Explorer. Each line should contain one path.

    .PARAMETER WindowStyle
    Specifies the window style for the opened Explorer windows. Valid values are 'Normal', 'Minimized', 'Maximized', and 'Hidden'.

    .PARAMETER Simulate
    Simulates the operation without opening any Windows Explorer windows.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to open Windows Explorer to a specific directory using a wildcard.
    Open-WindowsExplorerTo -Path "C:\Users\*\Documents"

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to open Windows Explorer to a specific directory using a literal path.
    Open-WindowsExplorerTo -LiteralPath "C:\Users\Username\Documents"

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to open Windows Explorer to directories listed in a file.
    Open-WindowsExplorerTo -File "C:\pathlist.txt"

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to open Windows Explorer with a maximized window style.
    Open-WindowsExplorerTo -Path "C:\Program Files" -WindowStyle Maximized

    .EXAMPLE
    # **Example 5**
    # This example demonstrates how to simulate opening Windows Explorer to all subdirectories in C:\Windows via the pipeline.
    "C:\Windows\*" | Open-WindowsExplorerTo -Simulate

    .EXAMPLE
    # **Example 6**
    # This example demonstrates how to open multiple directories through the pipeline using both wildcard and literal paths.
    "C:\Users\*\Downloads", "C:\Temp" | Open-WindowsExplorerTo -WindowStyle Normal

    .OUTPUTS
    None. Opens Windows Explorer windows or simulates the operation.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 01-17-2025
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    [cmdletbinding(DefaultParameterSetName = 'Path')]
    param(
        [parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Path'
        )]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]] $Path,

        [parameter(
            Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'LiteralPath'
        )]
        [ValidateScript({
            if ($_ -notmatch '[\?\*]') { $true }
            else { throw 'Wildcards are not acceptable with -LiteralPath' }
        })]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')]
        [string[]] $LiteralPath,

        [parameter(Mandatory,ParameterSetName='File')]
        [ValidateNotNullOrEmpty()]
        [Alias('f')]
        [String] $File,

        [Parameter(ParameterSetName="Path")]
        [Parameter(ParameterSetName="LiteralPath")]
        [Parameter(ParameterSetName="File")]
        [Alias('w')]
        [ValidateSet('Normal','Minimized','Maximized','Hidden')]
        [String] $WindowStyle = 'Minimized',

        [Parameter(ParameterSetName="Path")]
        [Parameter(ParameterSetName="LiteralPath")]
        [Parameter(ParameterSetName="File")]
        [Alias('s')]
        [Switch] $Simulate
    )

    begin {
        $openPathList = [System.Collections.Generic.List[String]]@()
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Path' {
                if(-not$Path){
                    throw "Passed -Path is null or empty."
                }
                $Path | Get-Item -Force | % {
                    if($_.PSIsContainer -eq $false) { return }
                    $null = $openPathList.Add($_.FullName)
                }
            }
            'LiteralPath' {
                if(-not$LiteralPath){
                    throw "Passed -LiteralPath is null or empty."
                }
                Get-Item -LiteralPath $LiteralPath -Force | % {
                    if($_.PSIsContainer -eq $false) { return }
                    $null = $openPathList.Add($_.FullName)
                }
            }
            'File' {
                $resolvedFile = (Get-Item -LiteralPath $File -Force).FullName
                if (-not (Test-Path -LiteralPath $resolvedFile -PathType Leaf)) {
                    throw "-File passed doesn't exist ($resolvedFile)."
                }
                $fileContent = (Get-Content -LiteralPath $resolvedFile -Raw).Trim()
                if ([string]::IsNullOrWhiteSpace($fileContent)) {
                    Write-Verbose "No windows to open. The passed -File has no paths."
                    return
                }
                $fileContent -split "`r`n" | Where-Object {
                    (-not[string]::IsNullOrWhiteSpace($_)) -and
                    (Test-Path -LiteralPath $_ -PathType Container)
                } | % { $openPathList.Add($_) }
            }
        }
        $openPathList | % {
            if(-not$Simulate){
                Write-Verbose "Opening '$_' with -WindowStyle $WindowStyle"
                Start-Process $_ -WindowStyle $WindowStyle | Out-Null
            }
            else {
                Write-Host "Simulate: Open path '$_' with -WindowStyle $WindowStyle"
            }
        }
    }
}