using namespace System.IO
using namespace System.Collections.Generic
function Convert-FontGlyphsToSVGs {
    [CmdletBinding(DefaultParameterSetName="Path")]
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
        [ValidateSet('FontTools','FontForge')]
        [String] $Method = 'FontTools',
        [Switch] $CropSVGAfterConversion,
        [Switch] $RunSVGOAfterConversion,
        [Switch] $Recurse,
        [String] $FontToolsVenvPath,
        [String] $FontForgeBin
    )

    begin {
        if($Method -eq 'FontTools'){
            if(-not $FontToolsVenvPath){
                $FontToolsVenvPath = [System.IO.Path]::Combine($env:FM_PY_VENV, "FontTools")
            }
            if(-not(Test-Path -LiteralPath $FontToolsVenvPath)){
                throw "FontTools VENV is missing or not installed. ($FontToolsVenvPath)"
            }
            $ftActivate = [System.IO.Path]::Combine($FontToolsVenvPath, "Scripts", "Activate.ps1")
            if(-not(Test-Path -LiteralPath $ftActivate)){
                throw "FontTools VENV activation script is missing. ($ftActivate)"
            }
            & $ftActivate
            try {
                $cmdfonts2svg = Get-Command fonts2svg.exe -CommandType Application
            }
            catch {
                throw "fonts2svg.exe cannot be located. Your FontTools VENV might not be set up properly."
            }
        }
        else {
            $cmdFontForge = Get-Command fontforge.exe -CommandType Application -EA 0
            if((-not $cmdFontForge) -and (-not $FontForgeBin)){
                $FontForgeBin = [System.IO.Path]::Combine($env:FM_BIN, 'fontforge', 'bin')
                if(-not(Test-Path -LiteralPath $FontForgeBin)){
                    throw "FontForge could not be located. Install FontForge and try again."
                }
                else {
                    $cmdFontForge = Get-Command "$FontForgeBin\fontforge.exe" -CommandType Application
                    if(-not$cmdFontForge){
                        throw "FontForge could not be located. Install FontForge and try again."
                    }
                }
            }
        }

        $fontList = [HashSet[string]]::new()
        $svgOutputDirs = [HashSet[string]]::new()
    }

    process {

        $resolvedPaths = if($PSBoundParameters['Path']) {
            $Path | Get-Item -Force
        } elseif($PSBoundParameters['LiteralPath']) {
            Get-Item -LiteralPath $LiteralPath -Force
        }

        foreach ($fPath in $resolvedPaths) {
            $currentItem = $fPath.FullName
            $currentItemExtension = $fPath.Extension
            if (Test-Path -LiteralPath $currentItem -PathType Container) {
                $gciSplat = @{
                    LiteralPath = $currentItem
                    Force       = $true
                    ErrorAction = 'SilentlyContinue'
                    File        = $true
                    Include     = @("*.ttf", "*.otf", "*.woff", "*.woff2")
                }
                if($Recurse){ $gciSplat['Recurse'] = $true }
                $childItems = Get-ChildItem @gciSplat
                if($childItems){
                    foreach ($item in $childItems) {
                        $null = $fontList.Add($item.FullName)
                    }
                }
            } elseif(Test-Path -LiteralPath $currentItem -PathType Leaf) {
                if($currentItemExtension -in @(".ttf", ".otf", ".woff", ".woff2")){
                    $null = $fontList.Add($currentItem)
                }
            }
        }

        $fontList | ForEach-Object {

            $currentFont          = $_
            $currentFontDirectory = [System.IO.Path]::GetDirectoryName($currentFont)
            $currentFontBase      = ((Get-Item -LiteralPath $currentFont).BaseName).Replace(' ','').Trim()
            $subdirectorySuffix   = "$Method SVG"
            $outputSubdirectory   = "${currentFontBase} ${subdirectorySuffix}"
            $DestPath             = [System.IO.Path]::Combine($currentFontDirectory, $outputSubdirectory).Trim()
            $DestPath             = Get-UniqueNameIfDuplicate -LiteralPath $DestPath

            New-Item -Path $DestPath -ItemType Directory -Force | Out-Null

            if($Method -eq 'FontTools'){
                try {
                    $Params = $currentFont, "-o", $DestPath
                    & $cmdfonts2svg $Params | Out-Null
                }
                catch {
                    throw "There was an error exporting SVGs with FontTools (fonts2svg.exe). Details: $($_.Exception.Message)"
                }
            }
            else {
                try {
                    $ffDestPath = $DestPath.Replace('\','/')
                    & $cmdFontForge -lang=ff -c "Open(`$1); SelectAll(); UnlinkReference(); Export(`"$ffDestPath/%n-%e.svg`");" $currentFont
                }
                catch {
                    throw "There was an error exporting SVGs with FontForge. Details: $($_.Exception.Message)"
                }
            }
            $null = $svgOutputDirs.Add($DestPath)
        }

        # Deactivate the FontTools VENV after all processing completes
        if($Method -eq 'FontTools'){
            deactivate
        }

        if($CropSVGAfterConversion){
            try {
                $cropWithInkscapeSplat = @{
                    LiteralPath = $svgOutputDirs
                    Overwrite   = $true
                    ErrorAction = 'Continue'
                }
                if($Recurse){ $cropWithInkscapeSplat['Recurse'] = $true }
                Convert-SVGCropWithInkscape @cropWithInkscapeSplat
            }
            catch {
                Write-Error "An error occurred while cropping SVGs. $($_.Exception.Message)"
            }
        }

        if($RunSVGOAfterConversion){
            try {
                $CMDSVGO = Get-Command svgo.cmd -CommandType Application -ErrorAction Stop
            }
            catch {
                Write-Error "Couldn't get SVGO in PATH. Aborting SVGO processing."
                return
            }

            foreach ($OutputDirectory in $svgOutputDirs) {
                if($Recurse){
                    $SVGOParams = "-f", $OutputDirectory
                }
                else {
                    $SVGOParams = "-rf", $OutputDirectory
                }
                & $CMDSVGO $SVGOParams | Out-Null
            }
        }
    }

    end {}
}