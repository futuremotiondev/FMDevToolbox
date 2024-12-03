function Convert-FontTTFToOTF {

    [CmdletBinding()]
    param (

        [Parameter(Mandatory,Position=0,
                ValueFromPipeline,
                ValueFromPipelineByPropertyName,
                ParameterSetName = "Fonts")]
        [ValidateNotNullOrEmpty()]
        [String[]] $Fonts,

        [ValidateSet('FontForge','FTCLI', IgnoreCase = $true)]
        [String] $Method = 'FontForge',

        [Int32] $MaxThreads = 16

    )

    begin {

        if($Method -eq 'FontForge'){
            try {
                $FFPYthon = Get-Command "$env:FM_BIN\FontForge\bin\ffpython.exe" -CommandType Application
            }
            catch {
                throw "Can't find ffpython.exe in BIN. Aborting."
            }
            try {
                Test-Path -Path "$env:FM_PY_FONT_SCRIPTS\fontforge_convert_ttf_to_otf.py" -PathType Leaf
            }
            catch {
                throw "Can't find fontforge_convert_ttf_to_otf.py. Aborting."
            }

            $FFTTF2OTFScript = "$env:FM_PY_FONT_SCRIPTS\fontforge_convert_ttf_to_otf.py"

            if(-not(Test-Path -LiteralPath $FFTTF2OTFScript)){
                throw "FontForge Conversion script cannot be found. ($FFTTF2OTFScript)"
            }
        }
        else{
            try {
                & "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1"
            }
            catch {
                throw "FontTools virtual environment could not be activated."
            }

            try {
                $FTCLICmd = Get-Command "$env:FM_PY_VENV\FontTools\Scripts\ftcli.exe"
            }
            catch {
                throw "Can't find ftcli.exe. Aborting."
            }
        }

        $TTFList = [System.Collections.Generic.List[String]]@()
    }

    process {
        foreach ($Font in $Fonts) {
            if($Font -match "^.+\.(ttf)$"){
                $TTFList.Add($Font)
            }
        }
    }

    end {

        if($Method -eq 'FontForge'){

            $TTFList | ForEach-Object -Parallel {

                $CurrentTTF         = $_
                $FFPYthon           = $Using:FFPYthon
                $FFTTF2OTFScript    = $Using:FFTTF2OTFScript

                & $FFPYthon $FFTTF2OTFScript $CurrentTTF

            } -ThrottleLimit $MaxThreads
        }

        if($Method -eq 'FTCLI'){

            $DialogSplat = @{
                MainInstruction = "Please specify the conversion tolerance (0.0-3.0)"
                MainContent     = "Low tolerance adds more points but keeps shapes. High tolerance adds few points but may change shape."
                WindowTitle     = "ftCLI TTF2OTF"
                InputText       = 1
            }
            do {
                $Result = Invoke-OokiiInputDialog @DialogSplat
                if($Result.Result -eq 'Cancel'){ exit }
                [float] $ConversionTolerance = $Result.Input
                [Bool] $ToleranceIsValid = ($ConversionTolerance -ge 0.0 -and $ConversionTolerance -le 3.0)
            } while (-not$ToleranceIsValid)

            $TTFList | ForEach-Object -Parallel {

                $FTCLICmd = $Using:FTCLICmd
                $Tolerance = $Using:ConversionTolerance
                $Params = 'converter', 'ttf2otf', '-t', $Tolerance, '--no-overwrite', $_
                & $FTCLICmd $Params

            } -ThrottleLimit $MaxThreads

            & deactivate
        }
    }
}