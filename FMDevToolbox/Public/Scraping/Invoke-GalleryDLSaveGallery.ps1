function Invoke-GalleryDLSaveGallery {
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory,
            Position=0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "The input URLs to download media from with the Gallery-DL VENV."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("input","i")]
        [String[]] $InputURLs,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            HelpMessage = "A literal path specifying where to save the output files."
        )]
        [ValidateScript({$_ -notmatch '[\?\*]'},
            ErrorMessage = "Wildcard characters *, ? are not acceptable with -OutputFolder")]
        [ValidateScript({[System.IO.Path]::IsPathRooted($_)},
            ErrorMessage = "Relative paths are not allowed in -OutputFolder.")]
        [ValidateNotNullOrEmpty()]
        [Alias("output","o")]
        [String] $OutputFolder,

        [Parameter(HelpMessage = "The path to your GalleryDL VENV. Defaults to `"`$env:FM_PY_VENV\GalleryDL`"")]
        [String] $GalleryDLVenv = "$env:FM_PY_VENV\GalleryDL"
    )

    begin {

        $venvFolder = $GalleryDLVenv
        if(-not(Test-Path $venvFolder -PathType Container)){
            Write-Error "GalleryDL VENV folder doesn't exist."
            return
        }

        if(-not(Test-Path $OutputFolder -PathType Container)){
            New-Item -Path $OutputFolder -ItemType Directory
        }

        $ActivateScript = [System.IO.Path]::Combine($venvFolder, 'Scripts', 'Activate.ps1')
        & $ActivateScript

        $GalleryDL = Get-Command "$ScriptsFolder\gallery-dl.exe"

    }

    process {
        foreach ($URL in $InputURLs) {
            $Params = '-d', $OutputFolder, $URL
            & $GalleryDL $Params
        }
    }

    end {
        & deactivate
    }

}


