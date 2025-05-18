using namespace System.Collections.Generic

function Convert-FontTTFToOTF {
    [CmdletBinding()]
    param (
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
            $true
        })]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,
        [Int32] $MaxThreads = 8
    )
    begin {
        try { & "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1" }
        catch { throw "FontTools virtual environment could not be activated." }
        try { $ftcliCmd = Get-Command "$env:FM_PY_VENV\FontTools\Scripts\ftcli.exe" }
        catch { throw "Can't find ftcli.exe. Aborting." }
        $fontList = [List[String]]@()
    }
    process {
        $resolvedPaths = Get-Item -LiteralPath $LiteralPath -Force
        $resolvedPaths | % {
            if(Test-Path -LiteralPath $_.FullName -PathType Leaf){
                if($_.Extension -eq '.ttf'){
                    $null = $fontList.Add($_.FullName)
                }
            }
        }
    }

    end {
        $DialogSplat = @{
            MainInstruction = "Please specify the conversion tolerance (0.0-3.0)"
            MainContent     = "Low tolerance adds more points but keeps shapes. High tolerance adds few points but may change shape."
            WindowTitle     = "ftCLI TTF2OTF"
            InputText       = 1
        }
        do {
            $Result = Invoke-OokiiInputDialog @DialogSplat
            if($Result.Result -eq 'Cancel'){ exit }
            [float] $conversionTolerance = $Result.Input
            [Bool] $toleranceIsValid = ($conversionTolerance -ge 0.0 -and $conversionTolerance -le 3.0)
        } while (-not$ToleranceIsValid)

        $fontList | % -Parallel {
            $ftcliCmd = $Using:ftcliCmd
            $tolerance = $Using:conversionTolerance
            $ftcliParams = 'converter', 'ttf2otf', '-t', $tolerance, '--no-overwrite', $_
            & $ftcliCmd $ftcliParams
        } -ThrottleLimit $MaxThreads

        & deactivate
    }
}