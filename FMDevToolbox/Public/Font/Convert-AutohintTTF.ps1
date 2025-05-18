using namespace System.Collections.Generic

function Convert-AutohintTTF {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({
            if($_ -match '[\?\*]'){
                throw "Wildcard characters *, ? are not acceptable with -LiteralPath"
            }
            if(-not [System.IO.Path]::IsPathRooted($_)){
                throw "Relative paths are not allowed in -LiteralPath."
            }
            if((Get-Item -LiteralPath $_).PSIsContainer){
                throw "-LiteralPath for this function only accepts files."
            }
            if((Get-Item -LiteralPath $_).Extension -ne '.ttf'){
                throw "This function only accepts .ttf files. You passed in '$_'."
            }
            $true
        })]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,

        # N: Stem width Natural
        # Q: Stem width Quantized
        # S: Stem width Strong
        [ValidateSet('n','q','s')]
        [string] $StemWidthGrayscale,
        [ValidateSet('n','q','s')]
        [string] $StemWidthGDICleartype,
        [ValidateSet('n','q','s')]
        [string] $StemWidthDWCleartype,

        # Switch off hinting above this PPEM value
        # Default: 200, A value of 0 means no limit.
        [Int32] $HintingSizeLimit = 200,

        # Hint glyph composites also
        [Switch] $AlsoHintComposites,

        # Adds a custom suffix to the font family name.
        [String] $AddSuffixToFamilyName,








        [Int32] $MaxThreads = 8
    )

    begin {

        $cmdTtfAutohint = Get-Command ttfautohint.exe -CommandType Application -EA 0
        if(-not($cmdTtfAutohint)){
            throw "Can't find ttfautohint.exe in PATH."
        }


        $fontList = [HashSet[String]]@()
    }

    process {
        $resolvedPaths = Get-Item -LiteralPath $LiteralPath -Force
        $resolvedPaths | % {
            if(Test-Path -LiteralPath $_.FullName -PathType Leaf){
                if($_.Extension -eq '.otf'){
                    $null = $fontList.Add($_.FullName)
                }
            }
        }
    }

    end {

        if(-not$ErrorThreshold){
            $DialogSplat = @{
                MainInstruction = "Please specify the Approximation Error Threshold measured in UPEM. [0.1<=x<=3.0]"
                MainContent     = "A value between 0.1 and 3.0."
                WindowTitle     = "ftCLI OTF2TTF"
                InputText       = 1.5
            }
            do {
                $Result = Invoke-OokiiInputDialog @DialogSplat
                if($Result.Result -eq 'Cancel'){ exit }
                [decimal] $ErrorThreshold = $Result.Input
                [Bool] $toleranceIsValid = ($ErrorThreshold -ge 0.1 -and $ErrorThreshold -le 3.0)
            } while (-not$ToleranceIsValid)
        }

        $fontList | % -Parallel {
            $curFont = $_
            $cmdFtcli = $Using:cmdFtcli
            $ErrorThreshold = $Using:ErrorThreshold
            $FtcliParams = "converter", "otf2ttf", "--max-err", $ErrorThreshold, "--no-overwrite", $curFont
            & $cmdFtcli $FtcliParams
        } -ThrottleLimit $MaxThreads

        & deactivate
    }
}