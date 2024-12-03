function Convert-FontOTFToTTF {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,
                ValueFromPipeline,
                ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String[]] $Fonts,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('Source','Subfolder','Custom', IgnoreCase = $true)]
        [String] $Output = 'Source',

        [Parameter(ValueFromPipelineByPropertyName)]
        [String] $OutputPath,

        [Parameter(ValueFromPipelineByPropertyName)]
        [String] $SubfolderName = "TTF Conversion",

        [Int32] $MaxThreads = 16
    )

    begin {

        if(($Output -eq 'Custom') -and ([String]::IsNullOrEmpty($OutputPath))){
            throw "-Output is custom, but no directory was specified."
        }

        try {
            & "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1"
        }
        catch {
            throw "FontTools virtual environment could not be activated."
        }

        $OTFList = [System.Collections.Generic.List[String]]@()
    }

    process {
        foreach ($Font in $Fonts) {
            if($Font -match "^.+\.(otf)$"){
                $OTFList.Add($Font)
            }
        }
    }

    end {

        $OTFList | ForEach-Object -Parallel {

            $CurrentOTF = $_
            $OTF2TTFCMD = Get-Command otf2ttf.exe -CommandType Application
            $Output = $Using:Output
            $OutputPath = $Using:OutputPath


            if($Output -eq 'Source'){
                & $OTF2TTFCMD $CurrentOTF
            }

            if($Output -eq 'Subfolder'){
                $FontFolder = [System.IO.Directory]::GetParent($CurrentOTF).FullName
                $FinalFolder = Join-Path $FontFolder $SubfolderName
                if(-not(Test-Path -LiteralPath $FinalFolder -PathType Container)){
                    New-Item -Path $FinalFolder -ItemType Directory -Force | Out-Null
                }
                $Params = $CurrentOTF, '-o', $FinalFolder
                & $OTF2TTFCMD $Params
            }

            if($Output -eq 'Custom'){
                if(-not(Test-Path -LiteralPath $OutputPath -PathType Container)){
                    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                }
                $Params = $CurrentOTF, '-o', $OutputPath
                & $OTF2TTFCMD $Params
            }

        } -ThrottleLimit $MaxThreads

        & deactivate
    }
}