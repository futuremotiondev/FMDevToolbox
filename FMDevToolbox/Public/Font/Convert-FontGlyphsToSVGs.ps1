using namespace System.IO
using namespace System.Collections.Generic
function Convert-FontGlyphsToSVGs {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "Path",
            HelpMessage="Path to one or more locations."
        )]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [String[]] $Path,

        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "LiteralPath",
            HelpMessage="Literal path to one or more locations."
        )]
        [ValidateScript({$_ -notmatch '[\?\*]'},
            ErrorMessage = "Wildcard characters *, ? are not acceptable with -LiteralPath")]
        [ValidateScript({[System.IO.Path]::IsPathRooted($_)},
            ErrorMessage = "Relative paths are not allowed in -LiteralPath.")]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,
        [String] $OutputSubdirectoryName = "Extracted SVGs",
        [Switch] $RunSVGOAfterConversion,
        [Switch] $CropSVGsAfterConversion,
        [Int32] $MaxThreads = 16
    )

    begin {

        if(-not(Test-Path -LiteralPath "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1")){
            Write-Error "FontTools VENV is missing. Install it and try again."
            return
        }
        & "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1"
        $CMDFonts2SVG = Get-Command fonts2svg.exe -CommandType Application -ErrorAction Stop


        $FontList = [System.Collections.Generic.HashSet[string]]::new()
    }

    process {

        $ResolvedDirectories = if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $Path | Get-Item -Force
        } else {
            $LiteralPath | Get-Item -Force
        }
        $ResolvedDirectories | % {
            $CurrentPath = $_.FullName
            if (Test-Path -LiteralPath $CurrentPath -PathType Container) {
                $ChildFonts = Get-ChildItem -LiteralPath $CurrentPath -Force -File -Recurse -Depth 30 | Where-Object { $_.FullName -match "^.+\.(ttf|otf)$" }
                if($ChildFonts){
                    foreach ($Font in $ChildFonts) {
                        $FoundFont = $Font.FullName
                        $null = $FontList.Add($FoundFont)
                    }
                }
            } elseif(Test-Path -LiteralPath $CurrentPath -PathType Leaf) {
                if($CurrentPath -match "\.(ttf|otf)$") {
                    $null = $FontList.Add($CurrentPath)
                }
            }
        }
    }

    end {

        $DestSVGDirectories = [System.Collections.Generic.List[String]]@()

        $FontList | ForEach-Object {
            $CurrentFont = $_
            $CurrentFontDirectory = [System.IO.Path]::GetDirectoryName($CurrentFont)
            $CurrentFontFilename = [System.IO.Path]::GetFileName($CurrentFont)
            $CurrentFontFilenameBase = [System.IO.Path]::GetFileNameWithoutExtension($CurrentFont)

            $DestPath = [System.IO.Path]::Combine($CurrentFontDirectory, "$CurrentFontFilenameBase $OutputSubdirectoryName")
            $DestPath = Get-UniqueNameIfDuplicate -LiteralPath $DestPath
            New-Item -Path $DestPath -ItemType Directory -Force

            $Prams = $CurrentFont, "-o", $DestPath
            & $CMDFonts2SVG $Prams | Out-Null

            $null = $DestSVGDirectories.Add($DestPath)

        }

        if($RunSVGOAfterConversion){
            $CMDSVGO = Get-CommandSVGO -ErrorAction Stop
            foreach ($OutputDirectory in $DestSVGDirectories) {
                $SVGOParams = "-rf", $OutputDirectory
                & $CMDSVGO $SVGOParams | Out-Null
            }
        }

        if($CropSVGsAfterConversion){
            $CMDInkscape = Get-CommandInkscape -ErrorAction Stop
            $InkActions = [System.Collections.Generic.List[String]]@()
            foreach ($Dir in $DestSVGDirectories) {
                $SVGFiles = Get-ChildItem -LiteralPath $Dir -Recurse -Filter *.svg -Force | % { $_.FullName }
                $SVGFiles | % {
                    $InkActions.Add("file-open:$_; export-area-drawing; export-filename:$_; export-do`r`n")
                }
                $InkActions.Add("`r`nquit")
                $InkParams = "--shell"
                $InkActions | & $CMDInkscape $InkParams | Out-Null
            }
        }
    }
}