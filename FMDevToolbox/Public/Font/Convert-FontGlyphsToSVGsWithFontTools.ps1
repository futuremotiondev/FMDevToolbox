using namespace System.IO
using namespace System.Collections.Generic
function Convert-FontGlyphsToSVGsWithFontTools {
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
        [Int32] $MaxThreads = 16
    )

    begin {
        $CMDFonts2SVG = Get-CommandFonts2SVG -ErrorAction SilentlyContinue
        $CMDSVGO = Get-CommandFonts2SVG -ErrorAction SilentlyContinue
        if(-not$CMDFonts2SVG){
            Write-Error "Python FontTools fonts2svg.exe cannot be found. Install the FontTools VENV in $env:FM_PY_VENV\FontTools"
            return
        }
        else {
            & "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1"
        }
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
                        New-LogSpectre -Message "[#93989f]Adding found font ([/][#ffffff]$FoundFont[/][#93989f]) to list of fonts to process.[/]" -Level SUCCESS
                        $null = $FontList.Add($FoundFont)
                    }
                }
                else {
                    Write-SpectreHost "[#93989f]No font files exist in currently processed directory:[/] [#ffffff]($CurrentPath)[/]"
                }
            } elseif(Test-Path -LiteralPath $CurrentPath -PathType Leaf) {
                if($CurrentPath -match "\.(ttf|otf)$") {
                    New-LogSpectre -Message "[#93989f]Adding found font ([/][#ffffff]$CurrentPath[/][#93989f]) to list of fonts to process.[/]" -Level SUCCESS
                    $null = $FontList.Add($CurrentPath)
                }
            }
        }
    }

    end {

        $FontList | ForEach-Object {
            $CurrentFont = $_
            $OutputSubdirectory = $Using:OutputSubdirectoryName
            $CurrentFontDirectory = [System.IO.Path]::GetDirectoryName($CurrentFont)
            $CurrentFontFilename = [System.IO.Path]::GetFileName($CurrentFont)
            $CurrentFontFilenameBase = [System.IO.Path]::GetFileNameWithoutExtension($CurrentFont)

            $DestPath = [System.IO.Path]::Combine($CurrentFontDirectory, "$CurrentFontFilenameBase $OutputSubdirectory")
            $DestPath = Get-UniqueNameIfDuplicate -LiteralPath $DestPath
            New-Item -Path $DestPath -ItemType Directory -Force

            $Prams = $CurrentFont, "-o", $DestPath
            & $CMDFonts2SVG $Prams

        }
    }
}