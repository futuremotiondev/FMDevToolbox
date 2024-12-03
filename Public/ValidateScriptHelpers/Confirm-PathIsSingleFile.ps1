function Confirm-PathIsSingleFile {
    [OutputType([bool])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [string] $Path
    )

    process {
        $PathIsRooted = [System.IO.Path]::IsPathRooted($Path)
        $PathHasExtension = [System.IO.Path]::HasExtension($Path)
        $PathHasSeparators = $Path.Contains('/') -or $Path.Contains('\')
        if ($PathIsRooted -or -not $PathHasExtension -or $PathHasSeparators) {
            return $false
        }
        return $true
    }
}