function Convert-FontGlyphsToSVGsFontForge {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [String[]] $Fonts,

        [Int32] $MaxThreads = 16

    )

    begin {

        try {
            $FFCMD = Get-Command "$env:FONTFORGEBIN\fontforge.exe" -CommandType Application
        }
        catch {
            throw "Can't find fontforge.exe. Aborting."
        }

        $FontList = [System.Collections.Generic.List[String]]@()
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

        $FontList | ForEach-Object {

            $CurrentFont = $_
            $DestPath = "FontForge Export"

            if(-not(Test-Path -LiteralPath $DestPath -PathType Container)){
                New-Item -Path $DestPath -ItemType Directory -Force | Out-Null
            }

            & $FFCMD -lang=ff -c 'Open($1); SelectAll(); UnlinkReference(); Export("FontForge Export/%n-%e.svg");' $CurrentFont

            $FullNoExt = [IO.Path]::GetFileNameWithoutExtension($CurrentFont)
            $DestFolder =  "$FullNoExt FontForge"

            Rename-Item -LiteralPath $DestPath -NewName $DestFolder
        }
    }

    end {}
}