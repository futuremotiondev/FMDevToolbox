function Resolve-PathType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[^*?]+$')]
        [String] $Path,
        [ValidateSet("Result","Object")]
        [String] $ReturnType = "Result"
    )

    process {
        # Determine path characteristics
        $isRooted = [System.IO.Path]::IsPathRooted($Path)
        $hasExtension = [System.IO.Path]::HasExtension($Path)
        $hasSeparators = $Path.Contains('/') -or $Path.Contains('\')

        # Determine the path type
        $pathType = switch ($true) {
            { $isRooted -and $hasExtension }      { "RootedFile"; break }
            { $isRooted }                         { "RootedDirectory"; break }
            { $hasExtension -and $hasSeparators } { "RelativeFile"; break }
            { $hasSeparators }                    { "RelativeDirectory"; break }
            { $hasExtension }                     { "SingleFile"; break }
            default {
                Write-Error "Can't determine path type of $Path"
                "Unknown"
            }
        }

        Write-Verbose "Path: $Path, Type: $pathType"

        if($ReturnType -eq 'Result'){
            return $pathType
        }
        else {
            [PSCustomObject]@{
                Path = $Path
                PathType = $pathType
            }
        }
    }
}

