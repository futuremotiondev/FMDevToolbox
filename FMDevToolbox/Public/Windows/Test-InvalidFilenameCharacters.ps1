<#
.SYNOPSIS
    Checks for illegal characters in a file path or file name.

.DESCRIPTION
    The Test-InvalidFilenameCharacters function determines if a given path contains
    any illegal characters that are not allowed in Windows file paths or file names.
    It returns a boolean value indicating the presence of such characters.

.PARAMETER Path
    The file path to check for illegal characters. This parameter is mandatory and accepts input from the pipeline.

.OUTPUTS
    System.Boolean
    Returns $true if the path or file name contains illegal characters; otherwise, returns $false.

.EXAMPLE
    'C:\Invalid|Path\example.txt' | Test-InvalidFilenameCharacters

    Description:
    This example checks the path 'C:\Invalid|Path\example.txt' for illegal characters.
    It will return $true because the pipe character '|' is not allowed in paths.

.EXAMPLE
    Test-InvalidFilenameCharacters -Path 'D:\ValidPath\validfile.txt'

    Description:
    This example checks the path 'D:\ValidPath\validfile.txt' for illegal characters.
    It will return $false as there are no illegal characters in this path.

.EXAMPLE
    $paths = @('E:\Another|Invalid:Path\file.doc', 'F:\CorrectPath\correctfile.doc')
    $paths | Test-InvalidFilenameCharacters

    Description:
    This example checks multiple paths stored in the $paths variable for illegal characters.
    It will return $true for 'E:\Another|Invalid:Path\file.doc' due to illegal characters,
    and $false for 'F:\CorrectPath\correctfile.doc'.

.NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 11-06-2024
#>
function Test-InvalidFilenameCharacters {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [string] $Path
    )

    begin {
        $IllegalPathChars = [System.IO.Path]::GetInvalidPathChars()
        $IllegalFileNameChars = [System.IO.Path]::GetInvalidFileNameChars()
    }

    process {
        if($Path.IndexOfAny($IllegalPathChars) -ne -1){
            return $true
        }
        $FileName = [System.IO.Path]::GetFileName($Path)
        if($FileName.IndexOfAny($IllegalFileNameChars) -ne -1){
            return $true
        }
        $false
    }
}
