function Convert-FontWOFFDecompress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias("Files","PSPath","Fonts")]
        [String[]] $LiteralPath,

        [ValidateSet('Google','FontTools', IgnoreCase = $true)]
        [String] $Method = 'FontTools',

        [Int32] $MaxThreads = 16
    )

    begin {

        if($Method -eq 'FontTools'){
            try {
                & "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1"
            }
            catch {
                throw "FontTools virtual environment could not be activated."
            }
        }
        else {
            try {
                Get-Command woff2_decompress.exe -CommandType Application
            } catch {
                throw "Can't find woff2_decompress.exe (Google WOFF Decompress Tool)"
            }
        }

        $FontList = [System.Collections.Generic.List[String]]@()
    }

    process {
        foreach ($Font in $LiteralPath) {
            if($Font -match "^.+\.(woff|woff2)$"){
                $FontList.Add($Font)
            }
        }
    }

    end {

        if($Method -eq 'FontTools'){
            $FontList | ForEach-Object -Parallel {
                $CMD = Get-Command "$env:FM_PY_VENV\FontTools\Scripts\ftcli.exe" -CommandType Application
                $Params = "converter", "wf2ft", "--no-overwrite", $_
                & $CMD $Params | Out-Null
            } -ThrottleLimit $MaxThreads

            & deactivate
        }
        else {
            $FontList | ForEach-Object {
                $FontInput = $_
                $CMD = Get-Command woff2_decompress.exe -CommandType Application
                $FontFilename = [System.IO.Path]::GetFileName($FontInput)
                $FontSourceDir = [System.IO.Directory]::GetParent($FontInput).FullName
                $TempDir = [System.IO.Directory]::CreateTempSubdirectory('WOFFDecompress')
                $FontDestTemp = [System.IO.Path]::Combine($TempDir, $FontFilename)
                [System.IO.File]::Copy($FontInput, $FontDestTemp) | Out-Null
                & $CMD $FontDestTemp | Out-Null
                $Decompressed = Get-ChildItem -LiteralPath $TempDir | where {$_.Extension -in '.ttf', '.otf'} | % {$_.FullName}
                foreach ($Font in $Decompressed) {
                    $DestFile = [System.IO.Path]::Combine($FontSourceDir, [System.IO.Path]::GetFileName($Font))
                    $FinalFile = Get-UniqueNameIfDuplicate -LiteralPath $DestFile
                    [System.IO.File]::Move($Font, $FinalFile) | Out-Null
                }
                Remove-Item -LiteralPath $TempDir -Force -Recurse
            }
        }
    }
}