function Confirm-PathIsAFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [string] $Path,
        [Switch] $AllowRelativePaths,
        [Switch] $AllowFilenameOnly,
        [ValidateSet('Bool', 'Object')]
        [String] $OutputFormat = 'Bool'
    )

    process {
        $PathType = Resolve-PathType -Path $Path
        $isValidFile = $false
        switch ($PathType) {
            "RootedFile" {
                $isValidFile = $true
            }
            "SingleFile" {
                if ($AllowFilenameOnly) {
                    $isValidFile = $true
                }
            }
            "RelativeFile" {
                if ($AllowRelativePaths) {
                    $isValidFile = $true
                }
            }
        }
        if($OutputFormat -eq 'Bool'){
            return $isValidFile
        }
        else{
            if ($isValidFile) {
                $ReturnPath = $Path
                $ReturnPathType = $PathType
            }
            else {
                $ReturnPath = $null
                $ReturnPathType = $null
            }
            return [PSCustomObject]@{
                Path     = $ReturnPath
                IsValid  = $isValidFile
                PathType = $ReturnPathType
            }
        }
    }
}