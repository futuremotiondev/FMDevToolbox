using namespace System.IO
using namespace System.Collections.Generic
function Convert-SVGCropWithInkscape {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "Path",
            HelpMessage="Path to one or more locations."
        )]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [String[]] $Path,
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "LiteralPath",
            HelpMessage="Literal path to one or more locations."
        )]
        [ValidateScript({$_ -notmatch '[\?\*]'},
            ErrorMessage = "Wildcard characters *, ? are not acceptable with -LiteralPath")]
        [ValidateScript({[System.IO.Path]::IsPathRooted($_)},
            ErrorMessage = "Relative paths are not allowed in -LiteralPath.")]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,
        [Switch] $PlaceInSubfolder,
        [Switch] $Overwrite,
        [String] $OutputSubdirectoryName = "Cropped SVGs",
        [Switch] $RunSVGOAfterConversion
    )

    begin {
        if($PlaceInSubfolder -and $Overwrite){
            Write-Error "-PlaceInSubfolder and -Overwrite switches cannot be used together."
            return
        }
        $CMDInkscape = Get-CommandInkscape -ErrorAction Stop
        $SVGList = [System.Collections.Generic.HashSet[string]]::new()
    }

    process {
        $ResolvedDirectories = if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $Path | Get-Item -Force
        } else {
            $LiteralPath | Get-Item -Force
        }
        $ResolvedDirectories | % {
            $CurrentPath = $_.FullName
            if (Test-Path -LiteralPath $CurrentPath -PathType Container) {
                $ChildSVGs = Get-ChildItem -LiteralPath $CurrentPath -Force -File -Recurse -Filter *.svg
                if($ChildSVGs){
                    foreach ($SVG in $ChildSVGs) {
                        $null = $SVGList.Add($SVG.FullName)
                    }
                }
            } elseif(Test-Path -LiteralPath $CurrentPath -PathType Leaf) {
                if($CurrentPath -match "\.(svg)$") {
                    $null = $SVGList.Add($CurrentPath)
                }
            }
        }
    }

    end {

        $ProcessedSVGFiles = [System.Collections.Generic.List[String]]@()
        $ProcessedSVGFolders = [System.Collections.Generic.List[String]]@()
        $InkActions = [System.Collections.Generic.List[String]]@()

        $SVGList | ForEach-Object {
            $CurrentSVG = $_
            $CurrentSVGDirectory = [System.IO.Path]::GetDirectoryName($CurrentSVG)
            $CurrentSVGFilename = [System.IO.Path]::GetFileName($CurrentSVG)
            $CurrentSVGFilenameBase = [System.IO.Path]::GetFileNameWithoutExtension($CurrentSVG)
            $CurrentSVGFullPathNoExtension = $CurrentSVG.Substring(0, $CurrentSVG.LastIndexOf('.'))

            if($PlaceInSubfolder){
                $DestPath = [System.IO.Path]::Combine($CurrentSVGDirectory, "$CurrentSVGFilenameBase $OutputSubdirectoryName")
                $DestPath = Get-UniqueNameIfDuplicate -LiteralPath $DestPath
                New-Item -Path $DestPath -ItemType Directory -Force | Out-Null
                $InkDestFilename = [System.IO.Path]::Combine($DestPath, $CurrentSVGFilename)
                if($DestPath -notin $ProcessedSVGFolders){
                    $null = $ProcessedSVGFolders.Add($DestPath)
                }
            }
            elseif(-not$Overwrite){
                $InkDestFilename = "$CurrentSVGFullPathNoExtension Cropped.svg"
                $null = $ProcessedSVGFiles.Add($InkDestFilename)
            }
            else{
                $InkDestFilename = $_
                $null = $ProcessedSVGFiles.Add($InkDestFilename)
            }
            $InkActions.Add("file-open:$_; export-area-drawing; export-filename:$InkDestFilename; export-do`r`n")
        }

        $InkActions.Add("`r`nquit")
        $InkParams = "--shell"
        $InkActions | & $CMDInkscape $InkParams | Out-Null

        if($RunSVGOAfterConversion){
            $CMDSVGO = Get-CommandSVGO -ErrorAction Stop
            if($PlaceInSubfolder){
                foreach ($Dir in $ProcessedSVGFolders) {
                    $SVGOParams = "-rf", $Dir
                    & $CMDSVGO $SVGOParams | Out-Null
                }
            }
            else{
                foreach ($SVG in $ProcessedSVGFiles) {
                    $SVGOParams = $SVG, "-o", $SVG
                    & $CMDSVGO $SVGOParams | Out-Null
                }
            }
        }
    }
}