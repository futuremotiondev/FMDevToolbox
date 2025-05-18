using namespace System.Collections.Generic
using namespace System.Collections.Concurrent
using namespace System.IO

function Convert-SVGToICO {
    [CmdletBinding(DefaultParameterSetName = "Path")]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "Path",
            HelpMessage="Path to one or more SVG files."
        )]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [String[]] $Path,

        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "LiteralPath",
            HelpMessage="Literal path to one or more SVG files."
        )]
        [ValidateScript({$_ -notmatch '[\?\*]'},
            ErrorMessage = "Wildcard characters *, ? are not acceptable with -LiteralPath")]
        [ValidateScript({[System.IO.Path]::IsPathRooted($_)},
            ErrorMessage = "Relative paths are not allowed in -LiteralPath.")]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,

        [Parameter(HelpMessage = "If set, ICO files will be placed in a subfolder of the SVGs containing directory.")]
        [Switch] $OutputInSubfolder,

        [Parameter(HelpMessage = "The name of the subfolder to place ICO files if -OutputInSubfolder is set.")]
        [String] $SubfolderName = 'ICO Conversion',

        [String] $ImageMagickInstall = "$env:FM_BIN\imagemagick",

        [Parameter(HelpMessage = "The number of simultaneous threads to use during conversion.")]
        [Int32] $MaxThreads = 20
    )

    begin {

        try {
            $rsvgCmd = Get-Command rsvg-convert.exe -CommandType Application
        }
        catch {
            throw "rsvg-convert.exe cannot be found in PATH. Aborting"
        }
        try {
            $resvgCmd = Get-Command resvg.exe -CommandType Application
        }
        catch {
            throw "resvg.exe cannot be found in PATH. Aborting"
        }
        try {
            $magickCmd = Get-Command "$ImageMagickInstall\magick.exe" -CommandType Application
        }
        catch {
            throw "rsvg-convert.exe cannot be found in PATH. Aborting"
        }
        $svgList = [List[FileInfo]]@()
    }

    process {
        $resolvedPaths = if($PSBoundParameters['Path']) {
            Get-Item -Path $Path -Force
        } elseif($PSBoundParameters['LiteralPath']) {
            Get-Item -LiteralPath $LiteralPath -Force
        }
        $resolvedPaths | % {
            $fileName = $_.FullName
            if (Test-Path -LiteralPath $fileName -PathType Container) {
                $gciSplat = @{
                    LiteralPath = $fileName
                    Force       = $true
                    Recurse     = $true
                    ErrorAction = 'SilentlyContinue'
                    File        = -File
                    Filter      = '*.svg'
                }
                $childItems = Get-ChildItem @gciSplat
                if($childItems){
                    foreach ($item in $childItems) {
                        $null = $svgList.Add($item)
                    }
                }
            } elseif(Test-Path -LiteralPath $fileName -PathType Leaf) {
                if($_.Extension -eq '.svg'){
                    $null = $svgList.Add($_)
                }
            }
        }
    }
    end {

        $tempDirHash = [HashSet[String]]@()

        if($PSBoundParameters['OutputInSubfolder']){
            $tempDirName = $SubfolderName
        } else {
            $tempDirName = ((New-Guid).Guid)
        }

        $svgList | ForEach-Object -Parallel {
            $curSvg          = $_.FullName
            $curSvgBaseName  = $_.BaseName
            $curSvgDir       = $_.Directory
            $tempDirName     = $Using:tempDirName
            $tempDirHash     = $using:tempDirHash
            $rsvgCmd         = $Using:rsvgCmd
            $resvgCmd        = $Using:resvgCmd
            $magickCmd       = $Using:magickCmd

            $tempFolder = Join-Path -Path $curSvgDir -ChildPath $tempDirName
            if(-not($tempFolder | Test-Path -PathType Container)){
                New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null
            }

            $icoSizes = @(16, 20, 24, 32, 48, 64, 96, 128, 256)
            foreach ($size in $icoSizes) {
                $rsvgParams = "-a", "-w", $size, "-h", $size, "-f", "png", $curSvg, "-o", "$tempFolder\$curSvgBaseName-$size.png"
                & $rsvgCmd $rsvgParams | Out-Null

                $MagickParams = "$tempFolder\$curSvgBaseName-$size.png", "-background", "none", "-gravity", "center", "-extent", "${size}x${size}", "png32:${tempFolder}\${curSvgBaseName}-${size}.png"
                & $magickCmd $MagickParams 2>&1 | Out-Null
            }

            & $magickCmd $($icoSizes.ForEach{"$tempFolder\$curSvgBaseName-$_.png"}) "$tempFolder\$curSvgBaseName.ico" 2>&1 | Out-Null
            $null = $tempDirHash.Add($tempFolder)

        } -ThrottleLimit $MaxThreads

        $tempDirHash.GetEnumerator() | % {
            $tempDirFull = $_
            $tempDirParent = [System.IO.Path]::GetDirectoryName($_)
            Get-ChildItem $tempDirFull -File -Filter '*.png' -Recurse -Force | Remove-Item -Force
            if(-not($PSBoundParameters['OutputInSubfolder'])){
                $icoFiles = Get-ChildItem -LiteralPath $tempDirFull -File -Filter "*.ico" -Recurse -Force
                foreach ($icoFile in $icoFiles) {
                    $icoDestPath = [System.IO.Path]::Combine($tempDirParent, $icoFile.Name)
                    $icoDestPath = Get-UniqueNameIfDuplicate -LiteralPath $icoDestPath
                    [IO.File]::Move($icoFile.FullName, $icoDestPath)
                }
                Remove-Item -LiteralPath $tempDirFull -Recurse -Force | Out-Null
            }
        }
    }
}