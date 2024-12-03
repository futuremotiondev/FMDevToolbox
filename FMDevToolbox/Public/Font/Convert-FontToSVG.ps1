function Convert-FontToSVG {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [String[]] $Fonts,
        [Int32] $MaxThreads = 16
    )

    begin {

        & "$env:FM_PY_VENV\Fonttools\Scripts\Activate.ps1"

        try {
            $FFCMD = Get-Command ffpython.exe -CommandType Application
        }
        catch {
            throw "Can't find ffpython.exe. Aborting."
        }

        $TTFToSVGScript = "$env:FM_PY_FONT_SCRIPTS\fontforge_convert_ttf_to_svg.py"

        if(-not(Test-Path -Path $TTFToSVGScript)){
            throw "Can't find fontforge_convert_ttf_to_svg.py. Aborting."
        }

        $FontList = [System.Collections.Generic.List[string]]@()
    }


    process {
        foreach ($Font in $Fonts) {
            if (Test-Path -Path $Font) {
                # Match by extension
                if($Font -match "^.+\.(ttf|otf)$"){
                    $FontList.Add($Font)
                }
                else {
                    Write-Error "Passed file is not a font. ($Font)"
                }

            } else {
                Write-Warning "Passed file does not exist on disk. ($Font)"
            }
        }
    }

    end {

        $FontList | ForEach-Object -Parallel {

            $TTFToSVGScript = $Using:TTFToSVGScript
            & $FFCMD $TTFToSVGScript $_

        } -ThrottleLimit $MaxThreads
    }
}