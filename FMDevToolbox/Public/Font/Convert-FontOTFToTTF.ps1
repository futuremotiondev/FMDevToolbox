using namespace System.Collections.Generic

function Convert-FontOTFToTTF {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            Position=0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript({
            if($_ -match '[\?\*]'){
                throw "Wildcard characters *, ? are not acceptable with -LiteralPath"
            }
            if(-not [System.IO.Path]::IsPathRooted($_)){
                throw "Relative paths are not allowed."
            }
            if((Get-Item -LiteralPath $_).PSIsContainer){
                throw "-LiteralPath for this function only accepts files."
            }
            $true
        })]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,

        [ValidateRange(0.1,3.0)]
        [Decimal] $ErrorThreshold,

        [Int32] $MaxThreads = 8
    )

    begin {

        $FontToolsVenvPath = [System.IO.Path]::Combine($env:FM_PY_VENV, "FontTools")
        if(-not(Test-Path -LiteralPath $FontToolsVenvPath)){
            throw "FontTools VENV is missing or not installed. ($FontToolsVenvPath)"
        }
        $ftActivate = [System.IO.Path]::Combine($FontToolsVenvPath, "Scripts", "Activate.ps1")
        if(-not(Test-Path -LiteralPath $ftActivate)){
            throw "FontTools VENV activation script is missing. ($ftActivate)"
        }
        & $ftActivate
        try { $cmdFtcli = Get-Command ftcli.exe -CommandType Application }
        catch {
            throw "ftcli.exe cannot be located in your FontTools VENV Install it and try again."
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