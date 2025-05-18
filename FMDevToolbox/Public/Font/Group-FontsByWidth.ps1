using namespace System.Collections.Generic

function Group-FontsByWidth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0,
                ParameterSetName="Fonts",
                ValueFromPipeline,
                ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]] $InputFonts,

        [Parameter(Mandatory, Position=0,
                ParameterSetName="Folders",
                ValueFromPipeline,
                ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]] $InputFolders,

        [Int32] $MaxThreads = 24
    )

    begin {
        # Regex patterns
        $fontList = [HashSet[String]]@()
    }

    process {

        switch ($PSCmdlet.ParameterSetName) {
            'Fonts'  {
                $resolvedFonts = Get-Item -LiteralPath $InputFonts -Force
                $resolvedFonts | % {
                    if(Test-Path -LiteralPath $_.FullName -PathType Leaf){
                        if($_.Extension -in @('.otf','.ttf','.woff','.woff2')){
                            $null = $fontList.Add($_.FullName)
                        }
                    }
                }
            }
            'Folders' {
                $resolvedFolders = Get-Item -LiteralPath $InputFolders -Force
                foreach ($dir in $resolvedFolders) {
                    if(Test-Path -LiteralPath $dir.FullName -PathType Container){
                        $containedFiles = Get-ChildItem -LiteralPath $dir.FullName -File -Force
                        $containedFiles | % {
                            if($_.Extension -in @('.otf','.ttf','.woff','.woff2')){
                                $null = $fontList.Add($_.FullName)
                            }
                        }
                    }
                }
            }
        }
        if($fontList.Count -eq 0){
            Write-Warning "Nothing to process."
            return
        }
    }

    end {

        $regexPatternA = "(Extra|Ultra|Semi|Ext|Ex|X|XX|XXX|XXXX)( |\-|)(Condensed|Cond|Cnd|Con|Cn|Compressed|Comp|Cmp|Cm|Compact|Narrow|Nar|Wide|Wd|Extended|Extend|Xtnd|Extd|Ext(?!ra)|Expanded|Expand|Xpand|Xpnd|Exp|Slim)"
        $regexPatternB = "(?<=[a-z])(Condensed|Compressed|Compact|Narrow|Wide|Extended|Expanded|Slim|Cond|Cnd|Con|Cn|Comp|Cmp|Extend|Extd|Ext(?!ra))"
        $regexPatternC = "(Condensed|Cond|Cnd|Cn|Compressed|Comp|Cmp|Cm|Compact|Narrow|Wide|Wd|Extended|Extend|Xtnd|Extd|Ext(?!ra)|Expanded|Expand|Xpand|Xpnd|Exp|Slim)"

        $fontList | % -Parallel {

            $CurrentFontPath      = $_
            $CurrentFontFilename  = [System.IO.Path]::GetFileNameWithoutExtension($CurrentFontPath)
            $CurrentFontDirectory = [System.IO.Path]::GetDirectoryName($CurrentFontPath)
            $regexPatternA        = $Using:regexPatternA
            $regexPatternB        = $Using:regexPatternB
            $regexPatternC        = $Using:regexPatternC
            $WidthFolderName      = $null

            $ConvertToPascalCase = {
                param(
                    [Parameter(Mandatory,Position=0)]
                    [string]$text
                )
                $text = $text -replace '(Extra|Ultra)(Condensed|Compressed|Compact|Narrow|Wide|Extended|Expanded|Slim)', '$1 $2'
                $text = $text -replace '(Semi)(Condensed|Compressed|Compact|Narrow|Wide|Extended|Expanded|Slim)', '$1-$2'
                return $text -replace '(^|-| )([a-z])', { $_.Groups[2].Value.ToUpper() }
            }

            if ($CurrentFontFilename -match $regexPatternA)      { $WidthFolderName = & $ConvertToPascalCase $matches[0] }
            elseif ($CurrentFontFilename -cmatch $regexPatternB) { $WidthFolderName = & $ConvertToPascalCase $matches[0] }
            elseif ($CurrentFontFilename -match $regexPatternC)  { $WidthFolderName = & $ConvertToPascalCase $matches[0] }
            if (-not $WidthFolderName) { $WidthFolderName = "Core" }

            $FinalWidthFolderPath = Join-Path $CurrentFontDirectory $WidthFolderName

            if (-not (Test-Path $FinalWidthFolderPath -PathType Container)) {
                New-Item -ItemType Directory -Path $FinalWidthFolderPath -ErrorAction SilentlyContinue | Out-Null
            }

            $FinalFontPath = Join-Path $FinalWidthFolderPath ([System.IO.Path]::GetFileName($CurrentFontPath))

            [IO.File]::Move($CurrentFontPath, $FinalFontPath)

        } -ThrottleLimit $MaxThreads
    }
}
