function Convert-FontWOFFCompress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        $Files,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateSet('WOFF','WOFF2','BOTH', IgnoreCase = $true)]
        [String]
        $Flavor,

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

            $CurrentFile = $_.Replace('`[', '[')
            $CurrentFile = $CurrentFile.Replace('`]', ']')

            $Flav = $Using:Flavor
            $FlavorString = ($Flav -ne 'BOTH') ? "-f$($Flav.ToLower())" : ''

            $CMD = Get-Command "$env:FM_PY_VENV\FontTools\Scripts\ftcli.exe"
            $Params = "converter", "ft2wf", $FlavorString, "--no-overwrite", $CurrentFile

            & $CMD $Params

        } -ThrottleLimit $MaxThreads
    }
}