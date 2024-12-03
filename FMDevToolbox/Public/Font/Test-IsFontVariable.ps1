<#
.SYNOPSIS
    Checks if a font is variable.

.DESCRIPTION
    The Test-IsFontVariable function checks if a font is variable by using a Python script.
    The function supports both wildcard and literal paths.

.PARAMETER Path
    Specifies the paths to process. This parameter accepts pipeline input and can be a string, or an object with a Path, FullName, or PSPath property.

.PARAMETER LiteralPath
    Specifies the literal paths to process. This parameter accepts pipeline input and can be a string, or an object with a PSPath property. Wildcard characters are not acceptable with this parameter.

.EXAMPLE
    Test-IsFontVariable -Path "C:\Fonts\*.ttf"

    This example checks if any TrueType font files in the "C:\Fonts" directory are variable.

.EXAMPLE
    Test-IsFontVariable -LiteralPath "C:\Fonts\MyFont.ttf"

    This example checks if the "MyFont.ttf" file in the "C:\Fonts" directory is a variable font.

.EXAMPLE
    Get-ChildItem -Path "C:\Fonts" -Filter "*.ttf" | Test-IsFontVariable

    This example checks if any TrueType font files in the "C:\Fonts" directory are variable, using pipeline input.

.EXAMPLE
    Test-IsFontVariable -Path "C:\Fonts\MyFolder\*.ttf"

    This example checks if any TrueType font files in the "MyFolder" subdirectory of the "C:\Fonts" directory are variable.

.AUTHOR
    Futuremotion
    https://www.github.com/fmotion1
#>
function Test-IsFontVariable {
    [cmdletbinding(DefaultParameterSetName = 'Path')]
    param(
        [parameter(Mandatory,Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Font
    )

    begin {
        $FinalFile = Get-UniqueNameIfDuplicate -LiteralPath $DestFile

        $FontIsVariableScript = "$env:FM_PY_FONT_SCRIPTS\fontbro\FontOpsIsVariable.py"

        try {
            & "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1"
        }
        catch {
            throw "Can't activate FontTools environment. Please create a VENV called 'FontTools' in the FM_PY_VENV folder."
        }

        if(-not(Test-Path $FontIsVariableScript)){
            throw "Can't find FontOpsIsVariable.py in FM_PY_FONT_SCRIPTS\Fontbro. Aborting."
        }

        $FontList = [System.Collections.Generic.List[String]]@()
    }


    process {

        foreach ($F in $Font) {

            if (Test-Path -Path $F) {
                if($F -match "^.+\.(otf|ttf|woff|woff2)$"){
                    $FontList.Add($F)
                }
                else {
                    Write-Warning "Passed file is not a font. ($F)"
                }
            } else {
                Write-Warning "Passed file does not exist on disk. ($F)"
            }
        }

        foreach ($Fnt in $FontList) {
            $FontIsVariable = & python $FontIsVariableScript $Fnt
            $Result = [System.Convert]::ToBoolean($FontIsVariable)
            $Result
        }
    }

    end {
        & deactivate
    }
}

# Test-IsFontVariable -Font "D:\Fonts\Test\Inter.ttf"