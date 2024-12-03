<#
.SYNOPSIS
Hints TrueType fonts using ttfautohint.

.DESCRIPTION
The Update-TTFAutohintFont function hints TrueType fonts using the ttfautohint utility. It provides various options to control the hinting process.

.PARAMETER InputFonts
Specifies the path(s) to the input TrueType font file(s). This parameter is mandatory and accepts input from the pipeline.

.PARAMETER PlaceInSubfolder
If specified, the output font files will be placed in a subfolder named "Hinted" or "Dehinted" based on the operation performed.

.PARAMETER HintRangeMinimum
Specifies the minimum PPEM (pixels per EM) value for hint sets. Default is 8.

.PARAMETER HintRangeMaximum
Specifies the maximum PPEM value for hint sets. Default is 50.

.PARAMETER HintingLimit
Specifies the PPEM value above which hinting is switched off. Default is 200. A value of 0 means no limit.

.PARAMETER NoHintingLimit
If specified, hinting will not be limited by the PPEM value.

.PARAMETER XHeightIncreaseLimit
Specifies the maximum PPEM value for increasing the x-height. Default is 14. A value of 0 switches off this feature.

.PARAMETER NoXHeightIncrease
If specified, x-height increase will be disabled.

.PARAMETER XHeightSnappingExceptions
Specifies a list of comma-separated PPEM values or value ranges at which no x-height snapping shall be applied. If this parameter is not passed, and the XHeightSnappingDisable parameter is not passed, the default behavior is followed (No snapping exceptions at all).

.PARAMETER XHeightSnappingDisable
If specified, x-height snapping will be disabled.

.PARAMETER FallbackStemWidth
Specifies the fallback stem width. Default is 50 font units at 2048 UPEM.

.PARAMETER SetWindowsCompatibility
If specified, ttfautohint will add two artificial blue zones positioned at the usWinAscent and usWinDescent values from the font's OS/2 table.

.PARAMETER SetAdjustSubglyphs
If specified, subglyph adjustments will be handled in exotic fonts.

.PARAMETER SetHintComposites
If specified, composite glyphs will be hinted as a whole, ignoring the hints of their components.

.PARAMETER SetFontIsSymbolFont
If specified, ttfautohint will process the font even if it can't find a single standard character for any of the supported scripts.

.PARAMETER DehintFont
If specified, all hints will be removed from the font. All other parameters are ignored if this switch is used.

.PARAMETER RespectLicense
If specified, license restrictions will be respected, and detailed ttfautohint information will not be added.

.PARAMETER AddAutohintInfo
Specifies whether to include ttfautohint details in the resulting font. Valid values are "None", "Version", and "Detailed". Default is "Version". If "None" is specified, no information will be added to the output font. If "Version" is specified, the ttfautohint version will be added to the font's version string. If "Detailed" is specified, the full parameters passed to ttfautohint will be added to the version string.

.PARAMETER AddTTFAInfoTable
If specified, an SFNT table called TTFA will be added to the output font, containing a dump of all parameters. Rarely used, mainly for debugging.

.PARAMETER FamilySuffixToAppend
Specifies a string that gets appended to the family name in entries with IDs 1, 4, 6, 16, and 21 in the font's name table.

.PARAMETER StemWidthModeGrayscale
Specifies the stem width and positioning mode for grayscale rendering. Valid values are "Natural", "Quantized", and "Strong". Default is "Quantized".

.PARAMETER StemWidthModeGDIClearType
Specifies the stem width and positioning mode for GDI ClearType rendering. Valid values are "Natural", "Quantized", and "Strong". Default is "Strong".

.PARAMETER StemWidthModeDWClearType
Specifies the stem width and positioning mode for DirectWrite ClearType rendering. Valid values are "Natural", "Quantized", and "Strong". Default is "Quantized".

.EXAMPLE
Update-TTFAutohintFont -InputFonts "C:\Fonts\MyFont.ttf" -PlaceInSubfolder

This example optimizes the "MyFont.ttf" font using the default settings and places the output font in a "Hinted" subfolder.

.EXAMPLE
Get-ChildItem "C:\Fonts" -Filter *.ttf | Update-TTFAutohintFont -NoHintingLimit -XHeightSnappingDisable

This example optimizes all TrueType fonts in the "C:\Fonts" directory, disabling the hinting limit and x-height snapping.

.LINK
https://freetype.org/ttfautohint/doc/ttfautohint.html
#>
function Update-TTFAutohintFont {

    [CmdletBinding()]

    param (

        [parameter(Mandatory,ValueFromPipeline)]
        [String[]] $InputFonts,

        [Switch] $PlaceInSubfolder,
        [String] $HintRangeMinimum = 8,
        [String] $HintRangeMaximum = 50,
        [String] $HintingLimit = 200,
        [Switch] $NoHintingLimit,
        [String] $XHeightIncreaseLimit = 14,
        [Switch] $NoXHeightIncrease,

        [ValidateScript({
            if ($_ -match '^(\s*\d+(-\d*)?\s*,)*\s*\d+(-\d*)?\s*$') {
                $true
            } else {
                throw "$_ is not a valid X-Height snapping exceptions string."
            }

        })]
        [String] $XHeightSnappingExceptions = "",
        [Switch] $XHeightSnappingDisable,
        [String] $FallbackStemWidth = 50,
        [Switch] $SetWindowsCompatibility,
        [Switch] $SetAdjustSubglyphs,
        [Switch] $SetHintComposites,
        [Switch] $SetFontIsSymbolFont,
        [Switch] $DehintFont,
        [Switch] $RespectLicense,

        [ValidateSet('None','Version', 'Detailed', IgnoreCase = $true)]
        [String] $AddAutohintInfo = 'Version',

        [Switch] $AddTTFAInfoTable,
        [String] $FamilySuffixToAppend = $null,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Natural','Quantized','Strong', IgnoreCase = $true)]
        [String] $StemWidthModeGrayscale = "Quantized",

        [Parameter(Mandatory=$false)]
        [ValidateSet('Natural','Quantized','Strong', IgnoreCase = $true)]
        [String] $StemWidthModeGDIClearType = "Strong",

        [Parameter(Mandatory=$false)]
        [ValidateSet('Natural','Quantized','Strong', IgnoreCase = $true)]
        [String] $StemWidthModeDWClearType = "Quantized"

    )

    begin {
        try {
            $TTFAutohintCmd = Get-Command ttfautohint.exe -CommandType Application
        } catch {
            throw "Can't find ttfautohint.exe in PATH. Make sure you have the ttfautohint application available in your path environment variable."
        }
    }


    process {

        if($XHeightSnappingDisable -and (-not([String]::IsNullOrEmpty($XHeightSnappingExceptions)))){
            throw "-XHeightSnappingDisable and -XHeightSnappingExceptions cannot be used at the same time."
            return
        }

        foreach ($CurrentFont in $InputFonts) {
            # Validation if needed
            if(-not($CurrentFont -match '^.+\.(ttf)$')){
                Write-Warning "Passed font is not a TTF."
                continue
            }

            $CurrentFontFolder = [System.IO.Directory]::GetParent($CurrentFont)
            $CurrentFontBase = [System.IO.Path]::GetFileNameWithoutExtension($CurrentFont)
            $CurrentFontExtension = [System.IO.Path]::GetExtension($CurrentFont)

            if($PlaceInSubfolder) {
                if($DehintFont) { $SubfolderName = "Dehinted" }
                else { $SubfolderName = "Hinted" }
                $DestinationFolder = Join-Path $CurrentFontFolder -ChildPath $SubfolderName
                New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null
            }
            else {
                $DestinationFolder = $CurrentFontFolder
            }

            if($DehintFont) {
                $DestinationFilename = "$CurrentFontBase-Dehinted$CurrentFontExtension"
                $DestinationOutput = Join-Path $DestinationFolder -ChildPath $DestinationFilename
                $FinalOutput = Get-UniqueNameIfDuplicate -LiteralPath $DestinationOutput
                $TTFAutohintPrams = '-d', $CurrentFont, $FinalOutput
                & $TTFAutohintCmd $TTFAutohintPrams
                continue
            }

            [Array] $TTFAutohintPrams = '-l', $HintRangeMinimum, '-r', $HintRangeMaximum
            if(!$RespectLicense) { $TTFAutohintPrams += '-i' }
            if($NoHintingLimit) { $HintingLimit = "0" }
            $TTFAutohintPrams += '-G', $HintingLimit

            if($NoXHeightIncrease) { $XHeightIncreaseLimit = "0" }
            $TTFAutohintPrams += '-x', $XHeightIncreaseLimit

            if($XHeightSnappingDisable) { $TTFAutohintPrams += '-X', "-" }
            elseif(-not([String]::IsNullOrEmpty($XHeightSnappingExceptions))) {
                $TTFAutohintPrams += '-X', $XHeightSnappingExceptions
            }

            $TTFAutohintPrams += '-H', $FallbackStemWidth
            if($SetWindowsCompatibility) { $TTFAutohintPrams += '-W' }
            if($SetAdjustSubglyphs) { $TTFAutohintPrams += '-p' }
            if($SetHintComposites) { $TTFAutohintPrams += '-c' }
            if($SetFontIsSymbolFont) { $TTFAutohintPrams += '-s' }
            if($AddAutohintInfo -eq 'None') { $TTFAutohintPrams += '-n' }
            elseif($AddAutohintInfo -eq 'Detailed') { $TTFAutohintPrams += '-I' }

            if($AddTTFAInfoTable) { $TTFAutohintPrams += '-t' }
            if(-not([String]::IsNullOrEmpty($FamilySuffixToAppend))){
                $TTFAutohintPrams += '-F', $FamilySuffixToAppend
            }

            $GetStemWidthChar = {
                param(
                    [Parameter(Mandatory = $true)]
                    [ValidateSet('Natural', 'Quantized', 'Strong')]
                    [string]$Mode
                )
                switch ($Mode) {
                    'Natural' { 'n'; break} ; 'Quantized' { 'q'; break } ; 'Strong' { 's'; break } ;
                    default { throw "Invalid value passed to -Mode." }
                }
            }

            $StemWidthChar1 = & $GetStemWidthChar -Mode $StemWidthModeGrayscale
            $StemWidthChar2 = & $GetStemWidthChar -Mode $StemWidthModeGDIClearType
            $StemWidthChar3 = & $GetStemWidthChar -Mode $StemWidthModeDWClearType
            $StemWidthModeString = "{0}{1}{2}" -f $StemWidthChar1, $StemWidthChar2, $StemWidthChar3
            $TTFAutohintPrams += '-a', $StemWidthModeString

            $DestinationFilename = "$CurrentFontBase-Hinted$CurrentFontExtension"
            $DestinationOutput = Join-Path $DestinationFolder -ChildPath $DestinationFilename
            $FinalOutput = Get-UniqueNameIfDuplicate -LiteralPath $DestinationOutput

            $TTFAutohintPrams += $CurrentFont, $FinalOutput
            & $TTFAutohintCmd $TTFAutohintPrams

        }
    }
}