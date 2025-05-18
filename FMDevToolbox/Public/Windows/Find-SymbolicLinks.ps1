function Find-SymbolicLinks {
    <#
    .SYNOPSIS
    Finds symbolic links in specified directories.

    .DESCRIPTION
    The Find-SymbolicLinks function searches for symbolic links within the specified paths. It supports both wildcard and literal path inputs, and can optionally recurse into subdirectories to find symbolic links. The function outputs details about each symbolic link found, including its type, name, target, and attributes.

    .PARAMETER Path
    Specifies the path(s) to search for symbolic links. Supports wildcards and accepts pipeline input.

    .PARAMETER LiteralPath
    Specifies the literal path(s) to search for symbolic links. Does not support wildcards but accepts pipeline input by property name.

    .PARAMETER Recurse
    Indicates that the search should include all subdirectories recursively.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to find symbolic links in a directory using a wildcard path.
    Find-SymbolicLinks -Path "C:\Projects\*"

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to find symbolic links in a specific directory using a literal path.
    Find-SymbolicLinks -LiteralPath "C:\Projects\MyProject"

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to find symbolic links recursively in a directory using a wildcard path.
    Find-SymbolicLinks -Path "C:\Projects\*" -Recurse

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to use the pipeline to find symbolic links in multiple directories.
    "C:\Projects", "D:\Data" | Find-SymbolicLinks -Recurse

    .EXAMPLE
    # **Example 5**
    # This example demonstrates how to find symbolic links in a directory with verbose output.
    Find-SymbolicLinks -Path "C:\Projects\*" -Verbose

    .OUTPUTS
    Outputs a custom object containing details about each symbolic link found, such as Type, Name, LinkType, Target, LinkTarget, ResolvedLinkTarget, FullPath, and Attributes.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: [Current Date]
    #>
    [CmdletBinding(DefaultParameterSetName="Path")]
    param(
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "Path",
            HelpMessage="Path to one or more locations."
        )]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [String[]] $Path,

        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "LiteralPath",
            HelpMessage="Literal path to one or more locations."
        )]
        [ValidateScript({$_ -notmatch '[\?\*]'},
            ErrorMessage = "Wildcard characters *, ? are not acceptable with -LiteralPath")]
        [ValidateScript({[System.IO.Path]::IsPathRooted($_)},
            ErrorMessage = "Relative paths are not allowed in -LiteralPath.")]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,

        [Parameter(Mandatory = $false)]
        [switch] $Recurse

    )
    begin {}
    process {
        # Recursive function to scan for symbolic links
        function Scan-ForSymlinks {
            param (
                [Parameter(Mandatory,Position=0)]
                [System.IO.FileSystemInfo] $FileSystemObject,
                [Switch] $Recurse
            )

            # Define a helper function to check if an item is a symbolic link
            $TestReparsePoint = {
                param([Parameter(Mandatory,Position=0)][System.IO.FileSystemInfo] $fso)
                return [bool]($fso.Attributes -band [IO.FileAttributes]::ReparsePoint)
            }

            if($FileSystemObject.PSIsContainer){
                Get-ChildItem -Path $FileSystemObject.FullName -Force -EA 0 | % {
                    $curItem = $_
                    if (& $TestReparsePoint $curItem) {
                        $itemType = ($curItem.PSIsContainer) ? 'Directory' : 'File'
                        [PSCustomObject]@{
                            Type               = $itemType
                            Name               = $curItem.Name
                            LinkType           = $curItem.LinkType
                            Target             = $curItem.Target
                            LinkTarget         = $curItem.LinkTarget
                            ResolvedLinkTarget = $curItem.ResolveLinkTarget($true)
                            FullPath           = $curItem.FullName
                            Attributes         = $curItem.Attributes
                        }
                    }
                    if ($Recurse) {
                        Scan-ForSymlinks -FileSystemObject $curItem -Recurse:$Recurse
                    }
                }
            }
        }

        # Determine which parameter set was used and process accordingly
        $resolvedPaths = if($PSBoundParameters['Path']){
            $Path | Get-Item -Force
        } elseif($PSBoundParameters['LiteralPath']) {
            Get-Item -LiteralPath $LiteralPath -Force
        }

        foreach ($It in $resolvedPaths) {
            Write-Host -f Yellow "`$It:" $It
        }

        $functionsToCopy = @{
            'Scan-ForSymlinks' = ${function:Scan-ForSymlinks}.ToString()
        }
        $resolvedPaths | % -Parallel {

            $functionsToCopy = $using:functionsToCopy
            foreach ($kvp in $functionsToCopy.GetEnumerator()) {
                $sbk = [ScriptBlock]::Create($kvp.Value)
                New-Item -Path Function:$($kvp.Key) -Value $sbk -ErrorAction SilentlyContinue | Out-Null
            }

            Scan-ForSymlinks -FileSystemObject $_ -Recurse:$Using:Recurse

        } -ThrottleLimit 28
    }
}