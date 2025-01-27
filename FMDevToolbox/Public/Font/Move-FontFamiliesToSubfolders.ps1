<#
.SYNOPSIS
Moves font files to subfolders based on their font family names.

.DESCRIPTION
The Move-FontFamiliesToSubfolders function is used to organize font files by moving
them to subfolders based on their font family names. It takes a list of font file
paths as input and moves each file to a subfolder named after its font family. The
function also converts the font family name and file name to title case if they are
in all uppercase. This function relies on external Python scripts for some
operations.

.PARAMETER Font
Specifies the font files to be processed. Accepts an array of strings representing
file paths.

.PARAMETER MaxThreads
Specifies the maximum number of threads to use for processing the font files. Default
value is 16.

.EXAMPLE
Move-FontFamiliesToSubfolders -Font "C:\Fonts\Arial.ttf", "C:\Fonts\Times New Roman.ttf"

This example moves two font files, Arial.ttf and Times New Roman.ttf, to subfolders
named "Arial" and "Times New Roman" respectively, within the original "C:\Fonts"
directory.

.INPUTS
System.String

.OUTPUTS
None (void)
#>
function Move-FontFamiliesToSubfolders {

    [cmdletbinding(DefaultParameterSetName = 'Path')]
    param(
        [parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String[]] $Fonts
    )

    begin {

        $FontList = [System.Collections.Generic.List[String]]@()

        try {
            $Activate = Resolve-Path "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1"
            & $Activate
        }
        catch {
            throw "Can't activate FontTools environment. Please create a VENV called 'FontTools' in the FM_PY_VENV folder."
        }

        $GetFamilyNameScript = Resolve-Path -Path "$env:FM_PY_FONT_SCRIPTS\FontOpsGetFamilyNameNew.py"

        if(-not(Test-Path -Path $GetFamilyNameScript)){
            throw "Can't find FontOpsGetFamilyName.py. Place it in the FM_PY_FONT_SCRIPTS\fontbro folder."
        }
    }


    process {
        foreach ($Font in $Fonts) {
            if (Test-Path -Path $Font) {
                # Match by extension
                if($Font -match "^.+\.(otf|ttf|woff|woff2)$"){
                    $FontList.Add($Font)
                }
                else {
                    Write-Warning "Passed file is not a font. ($Font)"
                }
            } else {
                Write-Warning "Passed file does not exist on disk. ($Font)"
            }
        }

    }

    end {

        $FontList | ForEach-Object -Parallel {

            $ConvertToTitleCaseIfUpperCase = {
                param (
                    [Parameter(Mandatory, Position=0)]
                    [String] $String
                )
                if ($String -ceq $String.ToUpper()) {
                    Format-String $String -Format TitleCase
                }
                else { $String }
            }

            $CurrentFont = $_
            $FontBaseDirectory = [System.IO.Directory]::GetParent($CurrentFont).FullName


            $FontFamilyNameScript = "$env:FM_PY_FONT_SCRIPTS\FontOpsGetFamilyNameNew.py"
            $FontFamilyName = & python $FontFamilyNameScript $CurrentFont
            $FontFamilyName = Remove-InvalidFilenameCharacters $FontFamilyName
            $FontFamilyName = & $ConvertToTitleCaseIfUpperCase $FontFamilyName

            $FontBaseFilename = [System.IO.Path]::GetFileNameWithoutExtension($CurrentFont)
            $FontBaseFilename = & $ConvertToTitleCaseIfUpperCase $FontBaseFilename

            $FontExtension = [System.IO.Path]::GetExtension($CurrentFont).ToLower()
            $FinalFileName = '{0}{1}' -f $FontBaseFilename, $FontExtension

            $FinalFile = [System.IO.Path]::Combine($FontBaseDirectory, $FontFamilyName, $FinalFileName)
            $FinalFile = Get-UniqueNameIfDuplicate -LiteralPath $FinalFile

            $FinalDirectory = [System.IO.Directory]::GetParent($FinalFile)
            if (-not($FinalDirectory | Test-Path)) {
                New-Item $FinalDirectory -ItemType Directory -Force | Out-Null
            }

            try {
                [IO.File]::Move($CurrentFont, $FinalFile)
            } catch {
                Write-Error "Failed to move file: $_"
            }

        } -ThrottleLimit 5

        Request-ExplorerRefreshV3 | Out-Null

        & deactivate

    }
}

