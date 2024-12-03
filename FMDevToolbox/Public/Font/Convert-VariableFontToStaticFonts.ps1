function Convert-VariableFontToStaticFonts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,
                ValueFromPipeline,
                ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String[]] $Fonts,

        [Int32] $MaxThreads = 12
    )

    begin {

        try {
            & "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1"
        }
        catch {
            throw "FontTools virtual environment could not be activated."
        }
        try {
            Test-Path -Path "$env:FM_PY_FONT_SCRIPTS\FontOpsConvertVariableToStatic.py" -PathType Leaf | Out-Null
        }
        catch {
            throw "Can't find FontOpsConvertVariableToStatic.py. Aborting."
        }

        $VFScript = "$env:FM_PY_FONT_SCRIPTS\FontOpsConvertVariableToStatic.py"
        $VFFontList = [System.Collections.Generic.List[String]]@()
    }

    process {
        foreach ($Font in $Fonts) {
            if($Font -match "^.+\.(ttf)$"){
                $VFFontList.Add($Font)
            }
        }
    }

    end {

        $VFFontList | ForEach-Object -Parallel {

            $CurrentTTF = $_
            $VFScript = $Using:VFScript
            & python $VFScript $CurrentTTF

        } -ThrottleLimit $MaxThreads

    }
}