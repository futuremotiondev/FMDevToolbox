function Convert-FontWOFFCompressGoogle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        $Files,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName)]
        [Int32]
        $MaxThreads = 16
    )

    begin {
        & "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1"
        $List = @()
    }

    process {
        foreach ($P in $Files) {
            if     ($P -is [String]) { $List += $P }
            elseif ($P.Path)         { $List += $P.Path }
            elseif ($P.FullName)     { $List += $P.FullName }
            elseif ($P.PSPath)       { $List += $P.PSPath }
            else                     { Write-Warning "$P is an unsupported type." }
        }
    }

    end {

        $List | ForEach-Object -Parallel {

            $CurrentFile = $_
            $CurrentFile = $CurrentFile.Replace('`[', '[')
            $CurrentFile = $CurrentFile.Replace('`]', ']')

            $CMD = Get-Command woff2_compress.exe
            & $CMD $CurrentFile

        } -ThrottleLimit $MaxThreads
    }
}