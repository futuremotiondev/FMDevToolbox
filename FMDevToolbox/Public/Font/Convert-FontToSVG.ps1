using namespace System.Collections.Generic

function Convert-FontToSVG {
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
        [Switch] $Recurse,
        [Int32] $MaxThreads = 32
    )

    begin {

        try {
            & "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1"
        }
        catch {
            throw "An error occured activating the FontTools venv. Details: $($_.Exception.Message)"
        }

        try {
            $FFCMD = Get-Command ffpython.exe -CommandType Application
        }
        catch {
            throw "Can't find ffpython.exe. Aborting. Details: $($_.Exception.Message)"
        }

        $TTFToSVGScript = "$env:FM_PY_FONT_SCRIPTS\fontforge_convert_ttf_to_svg.py"
        if(-not(Test-Path -Path $TTFToSVGScript)){
            throw "Can't find fontforge_convert_ttf_to_svg.py. Aborting. $($_.Exception.Message)"
        }

        $fontList = [HashSet[string]]@()
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
                    Include     = @("*.ttf")
                }
                if($Recurse){ $gciSplat['Recurse'] = $true }
                $childItems = Get-ChildItem @gciSplat
                if($childItems){
                    foreach ($item in $childItems) {
                        $null = $fontList.Add($item.FullName)
                    }
                }
            } elseif(Test-Path -LiteralPath $currentItem -PathType Leaf) {
                if($currentItemExtension -in @(".ttf")){
                    $null = $fontList.Add($currentItem)
                }
            }
        }

        $FontList | ForEach-Object -Parallel {
            $TTFToSVGScript = $Using:TTFToSVGScript
            $FFCMD = $Using:FFCMD
            $curFont = $_

            Write-Host "Converting $_..."
            & $FFCMD $TTFToSVGScript $curFont
        } -ThrottleLimit $MaxThreads
    }

    end {}
}