function Resolve-RelativePath {
    <#
    .SYNOPSIS
    Resolves a relative path to an absolute path based on a specified root path.

    .DESCRIPTION
    The Resolve-RelativePath function takes a relative path and a root path, combines them,
    and resolves the resulting path to an absolute path. It also provides an option to resolve symbolic links.

    .PARAMETER RelativePath
    The relative path that needs to be resolved into an absolute path.

    .PARAMETER RootPath
    The root path from which the relative path should be resolved. Defaults to the current directory if not specified.

    .PARAMETER ResolveSymlinks
    A switch to indicate if symbolic links should be resolved to their target paths.

    .OUTPUTS
    System.String

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to resolve a relative path using the current directory as the root.
    Resolve-RelativePath -RelativePath "..\Documents\file.txt"

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to resolve a relative path with a specified root path.
    Resolve-RelativePath -RelativePath "Projects\project1" -RootPath "C:\Users\Example"

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to resolve a relative path and resolve any symlinks in the path.
    Resolve-RelativePath -RelativePath "Links\shortcut" -RootPath "C:\Users\Example" -ResolveSymlinks

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: [Today's Date]
    #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory, Position=0, ValueFromPipeline)]
            [ValidateNotNullOrEmpty()]
            [Alias("Path")]
            [String] $RelativePath,

            [Parameter(Position=1, ValueFromPipelineByPropertyName)]
            [String] $RootPath = $PWD,

            [Switch] $ResolveSymlinks
        )
        process {
            $relativePath = [System.IO.Path]::TrimEndingDirectorySeparator($relativePath)
            if (-not [System.IO.Path]::IsPathRooted($RootPath)) { return $null }

            # Combine the root path with the relative path
            $combinedPath = Join-Path -Path $RootPath -ChildPath $relativePath

            # Resolve the combined path to an absolute path
            $absolutePath = [System.IO.Path]::GetFullPath($combinedPath)

            if ($ResolveSymlinks -and (Test-Path -Path $absolutePath)) {
                $symlinkTarget = (Get-Item -Path $absolutePath).Target
                if ($symlinkTarget) {
                    $absolutePath = $symlinkTarget
                }
            }
            return $absolutePath
        }
    }
