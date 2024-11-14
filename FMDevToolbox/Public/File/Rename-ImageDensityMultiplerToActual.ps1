<#
.SYNOPSIS
    Renames image files by converting density multiplier to actual size in the filename.

.DESCRIPTION
    This function processes image files specified by their literal paths. It identifies filenames containing a density multiplier pattern and renames them by replacing the multiplier with the actual size. The function can also add underscores, suffixes, or zero padding to the new filenames.

.PARAMETER LiteralPath
    Specifies the path(s) to the image file(s) to be renamed. Wildcard characters are not allowed, and paths must be absolute.

.PARAMETER AddUnderscore
    Adds an underscore before the calculated size in the new filename.

.PARAMETER Suffix
    Appends a custom suffix to the new filename.

.PARAMETER AddSuffixToAllFiles
    Applies the suffix to all passed files without a density multiplier pattern, but only if one of the files passed matches a density multiplier pattern.

.PARAMETER ZeroPadding
    Specifies the number of digits for zero-padding the calculated size.

.EXAMPLE
    Rename-ImageDensityMultiplerToActual -LiteralPath "C:\Images\photo 24@2x.png" -Suffix "px"

    This command renames "photo 24@2x.png" to "photo 48px.png", adding a "px" suffix.

.EXAMPLE
    Rename-ImageDensityMultiplerToActual -LiteralPath "D:\Pictures\Icon Add 128@3x.png" -ZeroPadding 4 -Suffix "px"

    This command renames "Icon Add 128@3x.png" to "Icon Add 0384px.png", applying zero-padding and adding a suffix.

.OUTPUTS
    None. The function renames files on disk and does not produce any output.

.NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 2023-11-01
#>

function Rename-ImageDensityMultiplerToActual {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript({$_ -notmatch '[\?\*]'},
            ErrorMessage = "Wildcard characters *, ? are not acceptable with -LiteralPath")]
        [ValidateScript({[System.IO.Path]::IsPathRooted($_)},
            ErrorMessage = "Relative paths are not allowed in -LiteralPath.")]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,
        [ValidateNotNullOrEmpty()]
        [switch] $AddUnderscore,
        [string] $Suffix,
        [Switch] $AddSuffixToAllFiles,
        [ValidateRange(2,6)]
        [int] $ZeroPadding
    )

    begin {
        $FileList = [System.Collections.Generic.List[String]]@()
        $RegexPatternMultipler = [regex]'[\s]+([\d]{1,4})@([\d]{1,4})x$'
        $RegexPatternDigitsEnd = [regex]'[\s]+([\d]{1,4})$'
    }

    process {

        $MultiplierMatchFound = $false
        foreach ($File in $LiteralPath) {
            if (-not (Test-Path -LiteralPath $File)) {
                Write-Error "File not found: $File"
                continue
            }
            $FNoExtension = [System.IO.Path]::GetFileNameWithoutExtension($File)
            if ($RegexPatternMultipler.IsMatch($FNoExtension)) {
                $MultiplierMatchFound = $true
            }
            $FileList.Add($File)
        }

        foreach ($File in $FileList) {

            $FNoExtension = [System.IO.Path]::GetFileNameWithoutExtension($File)
            $Directory    = [System.IO.Path]::GetDirectoryName($File)
            $Extension    = [System.IO.Path]::GetExtension($File)

            $NewFilename = $FNoExtension

            if ($RegexPatternMultipler.IsMatch($FNoExtension)) {

                $Match      = $RegexPatternMultipler.Match($FNoExtension)
                $BaseSize   = [int]$Match.Groups[1].Value
                $Multiplier = [int]$Match.Groups[2].Value
                $NewSize    = $BaseSize * $Multiplier

                if ($ZeroPadding) { $NewSize = $NewSize.ToString("D$ZeroPadding") }
                $NewFilename = $FNoExtension -replace $RegexPatternMultipler, ''
                if ($AddUnderscore) { $NewFilename += "_$NewSize" }
                else { $NewFilename += " $NewSize" }

                if ($Suffix) { $NewFilename += $Suffix }

            } elseif ($AddSuffixToAllFiles -and $RegexPatternDigitsEnd.IsMatch($FNoExtension)) {
                if($MultiplierMatchFound){
                    $Match  = $RegexPatternDigitsEnd.Match($FNoExtension)
                    $Digits = [int]$Match.Groups[1].Value
                    if ($ZeroPadding) { $Digits = $Digits.ToString("D$ZeroPadding") }
                    $NewFilename = $FNoExtension -replace $RegexPatternDigitsEnd, ''
                    if ($AddUnderscore) { $NewFilename += "_$Digits" }
                    else { $NewFilename += " $Digits" }
                    if ($Suffix) { $NewFilename += $Suffix }
                }
            } else {
                continue
            }

            $NewFullPath = [System.IO.Path]::Combine($Directory, "$NewFilename$Extension")
            if($NewFullPath -ne $File){
                $IDX = 2
                while (Test-Path -LiteralPath $NewFullPath) {
                    $NewFullPath = [System.IO.Path]::Combine($Directory, "$NewFilename" + "_{0:D2}" -f $IDX + "$Extension")
                    $IDX++
                }
                try { [System.IO.File]::Move($File, $NewFullPath) | Out-Null }
                catch { Write-Error "Failed to rename $File to $NewFullPath. Details: $_" }
            }
        }
    }
}