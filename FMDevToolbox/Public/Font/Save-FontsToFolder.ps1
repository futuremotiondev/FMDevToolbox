function Save-FontsToFolder {

    [CmdletBinding()]
    param (

        [Parameter(Mandatory, Position=0,
                ParameterSetName="Fonts",
                ValueFromPipeline,
                ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Fonts,

        [Parameter(Mandatory, Position=0,
                ParameterSetName="Folders",
                ValueFromPipeline,
                ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Folders,

        [Int32] $MaxThreads = 16,
        [Switch] $Versioned,
        [Switch] $WFR
    )

    begin {

        $FontList = [System.Collections.Generic.List[String]]@()
        $FolderList = [System.Collections.Generic.List[String]]@()

        if($Versioned){
            try {
                & "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1"
            } catch {
                throw "Can't activate FontTools environment. Aborting."
            }
            $GetFontVersionScript = "$env:FM_PY_FONT_SCRIPTS\get_font_version.py"
            if(-not(Test-Path -Path $GetFontVersionScript)){
                throw "Can't find get_font_version.py. Aborting."
            }
        }
    }

    process {

        switch ($PSCmdlet.ParameterSetName) {
            'Fonts'  {
                foreach ($Font in $Fonts) {
                    $FontList.Add($Font)
                }
            }
            'Folders' {
                foreach ($Folder in $Folders) {

                    $RootHasFiles = Get-ChildItem -LiteralPath $Folder | Where-Object { $_ | Get-ChildItem -File | Select-Object -First 1 }
                    if($RootHasFiles){
                        $FolderList.Add($Folder)
                    }

                    $InnerFolders = Get-ChildItem -LiteralPath $Folder -Directory -Recurse -Depth 10 | Where-Object { $_ | Get-ChildItem -File | Select-Object -First 1 }
                    if($InnerFolders){
                        foreach ($Item in $InnerFolders) {
                            $FolderList.Add($Item)
                        }
                    }
                }
            }
        }
    }

    end {

        if($PSCmdlet.ParameterSetName -eq 'Folders'){
            $FolderList | ForEach-Object -Parallel {

                $CurrentFolder = $_
                $FontList = $Using:FontList

                [Array] $Fonts = Get-ChildItem $CurrentFolder -File -Recurse -Depth 10 | ForEach-Object {$_.FullName}
                if($Fonts.Count -eq 0) { continue }
                foreach ($Font in $Fonts) { $FontList.Add($Font) }

            } -ThrottleLimit $MaxThreads

            if($FontList.Count -eq 0) { return }
        }

        $FontList | ForEach-Object -Parallel {

            $FontFile = $_
            $Versioned            = $Using:Versioned
            $WFR                  = $Using:WFR
            $FileName             = [System.IO.Path]::GetFileName($FontFile)
            $FileDirectory        = [System.IO.Directory]::GetParent($FontFile)
            $FileExtension        = [System.IO.Path]::GetExtension($FontFile).TrimStart('.')
            $ExtVersionedFonts    = "ttf", "otf"
            $FontFileVersion      = ''

            if ($Versioned) {

                if ($ExtVersionedFonts -contains $FileExtension) {
                    $FontFileVersion = & python "$env:FM_PY_FONT_SCRIPTS\get_font_version.py" $FontFile

                    $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
                    $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
                    $FontFileVersion = $FontFileVersion -replace $re

                    if ([string]::IsNullOrWhiteSpace($FontFileVersion)) { $FontFileVersion = '' }
                    elseif ($FontFileVersion -match '^(0.)(.*)$') { $FontFileVersion = '' }
                    elseif ($FontFileVersion -match '^(version\s)(.*)$') { $FontFileVersion = $Matches[2] }
                    elseif ($FontFileVersion -match '^(\d)\.(\d{1,2})$') { $FontFileVersion = $Matches[1] + '.' + $Matches[2] + '0'  }
                    elseif ($FontFileVersion -match '^(\d\.\d{3})(.*)$') { $FontFileVersion = $Matches[1]  }
                    elseif ($FontFileVersion -match '^(0{1,5})(\d*)\.(.*)') { $FontFileVersion = $Matches[2] + '.' + $Matches[3]  }
                }
            }

            $ExtWebFiles = "svg", "eot", "css", "html", "htm", "woff", "woff2"
            $WFRLabel = ($WFR) ? 'WFR' : ''

            $Subfolder = switch ($FileExtension) {
                "otf" { "OT $FontFileVersion $WFRLabel" }
                "ttf" { "TT $FontFileVersion $WFRLabel" }
                "vfc" { 'VFC' }
                "txt" { '00 License' }
                { $ExtWebFiles -contains $_ } { 'WEB' }
                default { '00 Supplimental' }
            }

            $Subfolder = $Subfolder.Trim()
            $DestDir = ([IO.Path]::Combine($FileDirectory, $Subfolder)).Trim()
            if($Subfolder -eq 'WEB'){
                $DestDir = ([IO.Path]::Combine($DestDir, $FileExtension)).ToUpper().Trim()
            }

            if (-not(Test-Path -LiteralPath $DestDir -PathType Container)) {
                [IO.Directory]::CreateDirectory($DestDir) | Out-Null
            }

            [IO.File]::Move($FontFile, [IO.Path]::Combine($DestDir, $FileName))

        } -ThrottleLimit $MaxThreads

    }
}