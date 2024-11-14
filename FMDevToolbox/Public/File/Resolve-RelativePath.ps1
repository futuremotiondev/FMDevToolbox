function Resolve-RelativePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position=0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[^*?]+$')] # Disallows '*' and '?' wildcard characters
        [String] $Path,
        [String] $RootPath = $PWD,
        [ValidateSet("ResolvedOnly", "Object")]
        [String] $OutputFormat = "ResolvedOnly",
        [Switch] $ResolveSymlinks
    )
    process {
        try {

            $Path = [System.IO.Path]::TrimEndingDirectorySeparator($Path)

            if(-not[System.IO.Path]::IsPathRooted($RootPath)){
                Write-Error "Supplied root path is not absolute."
                return
            }

            if (-not [System.IO.Path]::IsPathRooted($Path)) {
                Write-Verbose "Combining RootPath '$RootPath' with Path '$Path'."
                $FullPath = Join-Path -Path $RootPath -ChildPath $Path
                $ResolvedPath = [System.IO.Path]::GetFullPath($FullPath)
                $OriginalPath = $Path

            } else {
                Write-Verbose "The provided path '$Path' is not a relative path."
                $ResolvedPath = $Path
                $OriginalPath = $Path
            }

            if ($ResolveSymlinks -and (Test-Path -Path $ResolvedPath)) {
                $Target = (Get-Item -Path $ResolvedPath).Target
                if ($Target) {
                    $ResolvedPath = $Target
                }
            }

            if ($OutputFormat -eq 'ResolvedOnly') {
                return $ResolvedPath
            }
            else {
                return [PSCustomObject][ordered]@{
                    OriginalPath   = $OriginalPath
                    ResolvedPath   = $ResolvedPath
                    RootPath       = $RootPath
                }
            }
        } catch {
            Write-Error "Failed to resolve path: $($_.Exception.Message)"
        }
    }
}