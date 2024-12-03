function Group-FontsByWidth {
    [CmdletBinding()]
    param(
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

        [Int32] $MaxThreads = 16
    )

    begin {
        # Regex patterns
        $regexPatternA = "(Extra|Ultra|Semi|Ext|Ex|X|XX|XXX|XXXX)( |\-|)(Condensed|Cond|Cnd|Con|Cn|Compressed|Comp|Cmp|Cm|Compact|Narrow|Nar|Wide|Wd|Extended|Extend|Xtnd|Extd|Ext(?!ra)|Expanded|Expand|Xpand|Xpnd|Exp|Slim)"
        $regexPatternB = "(?<=[a-z])(Condensed|Compressed|Compact|Narrow|Wide|Extended|Expanded|Slim|Cond|Cnd|Con|Cn|Comp|Cmp|Extend|Extd|Ext(?!ra))"
        $regexPatternC = "(Condensed|Cond|Cnd|Cn|Compressed|Comp|Cmp|Cm|Compact|Narrow|Wide|Wd|Extended|Extend|Xtnd|Extd|Ext(?!ra)|Expanded|Expand|Xpand|Xpnd|Exp|Slim)"
        $FontList = [System.Collections.Generic.List[String]]@()
        $FolderList = [System.Collections.Generic.List[String]]@()

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

                $CurrentFolder    = $_
                $FontList = $Using:FontList

                [Array] $Fonts = Get-ChildItem $CurrentFolder -File -Recurse -Depth 10 | ForEach-Object {$_.FullName}
                if($Fonts.Count -eq 0) { continue }
                foreach ($Font in $Fonts) { $FontList.Add($Font) }

            } -ThrottleLimit $MaxThreads

            if($FontList.Count -eq 0) { return }
        }


        $FontList | ForEach-Object -Parallel {

            $ConvertToPascalCase = {
                param([string]$text)
                $text = $text -replace '(Extra|Ultra)(Condensed|Compressed|Compact|Narrow|Wide|Extended|Expanded|Slim)', '$1 $2'
                $text = $text -replace '(Semi)(Condensed|Compressed|Compact|Narrow|Wide|Extended|Expanded|Slim)', '$1-$2'
                return $text -replace '(^|-| )([a-z])', { $_.Groups[2].Value.ToUpper() }
            }

            $CurrentFont            = $_
            $CurrentFontFilename    = [System.IO.Path]::GetFileNameWithoutExtension($CurrentFont)
            $WidthFolderName        = $null
            $regexPatternA          = $Using:regexPatternA
            $regexPatternB          = $Using:regexPatternB
            $regexPatternC          = $Using:regexPatternC

            if ($CurrentFontFilename -match $regexPatternA)      { $WidthFolderName = & $ConvertToPascalCase -text $matches[0] }
            elseif ($CurrentFontFilename -cmatch $regexPatternB) { $WidthFolderName = & $ConvertToPascalCase -text $matches[0] }
            elseif ($CurrentFontFilename -match $regexPatternC)  { $WidthFolderName = & $ConvertToPascalCase -text $matches[0] }
            if (-not $WidthFolderName) { $WidthFolderName = "Core" }

            $CurrentFontDirectory = [System.IO.Path]::GetDirectoryName($CurrentFont)
            $FinalWidthFolderPath = Join-Path $CurrentFontDirectory $WidthFolderName

            if (-not (Test-Path $FinalWidthFolderPath -PathType Container)) {
                New-Item -ItemType Directory -Path $FinalWidthFolderPath -ErrorAction SilentlyContinue | Out-Null
            }

            $FinalFontPath = Join-Path $FinalWidthFolderPath ([System.IO.Path]::GetFileName($CurrentFont))
            [IO.File]::Move($CurrentFont, $FinalFontPath)
            # Move-Item -Path $CurrentFont -Destination $FinalFontPath

        } -ThrottleLimit $MaxThreads
    }
}
