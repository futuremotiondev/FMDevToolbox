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
        [String] $OutputSubfolderName = "Cropped SVGs",
        [Switch] $Overwrite,
        [Switch] $Recurse,
        [Int32] $Depth,

        [Switch] $RunSVGOAfterConversion
    )

    begin {
        if($PlaceInSubfolder -and $Overwrite){
            Write-Error "-PlaceInSubfolder and -Overwrite switches cannot be used together." -ErrorAction continue
            return
        }
        $CMDInkscape = Get-Command inkscape.exe -CommandType Application -ErrorAction SilentlyContinue
        if(-not($CMDInkscape)){
            $CMDInkscape = Get-Command inkscape.com -CommandType Application -ErrorAction SilentlyContinue
            if(-not($CMDInkscape)){
                throw "Inkscape.exe or inkscape.com cannot be located in PATH. Make sure to add 'YourInkscapeInstall\inkscape\bin' to PATH."
            }
        }

        $SVGList = [System.Collections.Generic.HashSet[String]]::new()
        $SVGFolderList = [System.Collections.Generic.HashSet[String]]::new()
    }

    process {

        $ResolvedDirectories = if ($PSBoundParameters['Path']) {
            $Path | Get-Item -Force
        } elseif($PSBoundParameters['LiteralPath']) {
            $LiteralPath | Get-Item -Force
        }

        $ResolvedDirectories | % {
            $CurrentPath = $_
            if (Test-Path -LiteralPath $CurrentPath.FullName -PathType Container) {
                $ChildSVGs = Get-ChildItem -LiteralPath $CurrentPath.FullName -Force -File -Recurse -Filter *.svg
                if($ChildSVGs){
                    $null = $SVGFolderList.Add($SVG)
                }
            } elseif(Test-Path -LiteralPath $CurrentPath.FullName -PathType Leaf) {
                if($CurrentPath.Extension -eq '.svg') {
                    $null = $SVGList.Add($CurrentPath)
                }
            }
        }
    }

    end {

        $SVGFilesToProcess   = [System.Collections.Generic.HashSet[String]]@()
        $SVGFoldersToProcess = [System.Collections.Generic.HashSet[String]]@()
        $InkActions          = [System.Collections.Generic.HashSet[String]]@()


        foreach ($Folder in $SVGFolderList) {

            $CurrentFolderFullName = $Folder.FullName

            if($PlaceInSubfolder){
                $DestFolder = Join-Path $CurrentFolderFullName -ChildPath $OutputSubfolderName
                if(-not$Overwrite){
                    $DestFolder = Get-UniqueNameIfDuplicate -LiteralPath $DestFolder
                }
                if(-not(Test-Path -LiteralPath $DestFolder -PathType Container)){
                    $DestFolderObj = New-Item -Path $DestFolder -ItemType Directory -Force -ErrorAction Ignore | Out-Null
                    if(-not($DestFolderObj)){
                        Write-Error "Could not create the destination folder. ($DestFolderObj)"
                        continue
                    }
                }

                if(-not$Recurse){
                    $copyContainingSvgs = @{
                        LiteralPath = $CurrentFolderFullName
                        Destination = $DestFolder
                        PassThru  = $true
                        Filter   = "*.svg"
                        Force  = $true
                        ErrorAction = 'Ignore'
                    }
                    $DestFolderCopiedSuccess = Copy-Item @copyContainingSvgs
                    if(-not($DestFolderCopiedSuccess)){
                        Write-Error "Could not copy the SVGs in $CurrentFolderFullName to the destination folder ($DestFolder)."
                        continue
                    }
                    else {
                        $null = $SVGFoldersToProcess.Add($DestFolder)
                    }
                }
                else {
                    $copyContainingSvgs = @{
                        LiteralPath = $CurrentFolderFullName
                        Destination = $DestFolder
                        PassThru    = $true
                        Recurse     = $true
                        Container   = $true
                        Force       = $true
                        Filter      = "*.svg"
                        ErrorAction = 'Ignore'
                    }
                    $DestFolderCopiedSuccess = Copy-Item @copyContainingSvgs

                    if(-not($DestFolderCopiedSuccess)){
                        Write-Error "Could not copy the SVGs (Recursively) in $CurrentFolderFullName to the destination folder ($DestFolder)."
                        continue
                    }
                    else {
                        $DestFoldersRecursiveTargets = Get-ChildItem -LiteralPath $DestFolder -Force -Directory -Recurse -ErrorAction Continue
                        if(-not($DestFoldersRecursiveTargets)){
                            Write-Error "Could not retrieve any directories in $DestFolder the newly created subdirectory ($OutputSubfolderName)."
                            continue
                        }
                        $DestFoldersRecursiveTargets | % {
                            $null = $SVGFoldersToProcess.Add($_)
                        }
                    }
                }
            }
            else {
                $DestFolder = $CurrentFolderFullName
                if(-not$Recurse) {
                    $null = $SVGFoldersToProcess.Add($DestFolder)
                }
                else{
                    $ChildSVGFolders = Get-ChildItem -LiteralPath $DestFolder -Recurse -Force -Directry -ErrorAction Continue
                    $ChildSVGFolders
                }
            }
        }

        $SVGFolderList | % {


        }

        $SVGList | ForEach-Object {

            $CurrentSVGObject   = $_
            $SVGDirectoryPath   = [System.IO.Directory]::GetParent($CurrentSVG).FullName
            $SVGDirectoryName   = [System.IO.Path]::GetDirectoryName($CurrentSVG)
            $SVGFilename        = [System.IO.Path]::GetFileName($CurrentSVG)
            $SVGFilenameBase    = [System.IO.Path]::GetFileNameWithoutExtension($CurrentSVG)
            $SVGFullPathNoExt   = $CurrentSVG.Substring(0, $CurrentSVG.LastIndexOf('.'))

            if($PlaceInSubfolder){
                $DestPathFolder = [System.IO.Path]::Combine($SVGDirectoryPath, $OutputSubfolderName)
                $DestPathFolder = Get-UniqueNameIfDuplicate -LiteralPath $DestPathFolder
                if(-not(Test-Path -LiteralPath $DestPathFolder -PathType Container)){
                    New-Item -Path $DestPathFolder -ItemType Directory -Force -ErrorAction Ignore | Out-Null
                }
                Copy-Item -LiteralPath $CurrentSVG -Destination $DestPathFolder -Force
                $null = $SVGFoldersToProcess.Add($DestPathFolder)
            }

            elseif(-not$Overwrite){


                $Fdir = [System.IO.Path]::Combine($SVGFullPathNoExt, $OutputSubfolderName)
                $FinalFile = [System.IO.Path]::Combine($Fdir, $OutputSubfolderName)
                $DestPathFile = [System.IO.Path]::Combine($DestPathFolder, $InkscapeOutputFile)
                if(-not($DestPathFolder)){
                    Join-Path -Path $DestPathFolder
                    $SVGFilenameBase
                }
                $null = $SVGFilesToProcess.Add($InkscapeOutputFile)
            }
            else{
                $InkscapeOutputFile = $_
                $null = $SVGFilesToProcess.Add($InkscapeOutputFile)
            }
            $InkActions.Add("file-open:$_; export-area-drawing; export-filename:$InkscapeOutputFile; export-do`r`n")
        }

        $InkActions.Add("`r`nquit")
        $InkParams = "--shell"
        $InkActions | & $CMDInkscape $InkParams | Out-Null

        if($RunSVGOAfterConversion){
            $CMDSVGO = Get-CommandSVGO -ErrorAction Stop
            if($PlaceInSubfolder){
                foreach ($Dir in $SVGFoldersToProcess) {
                    $SVGOParams = "-rf", $Dir
                    & $CMDSVGO $SVGOParams | Out-Null
                }
            }
            else{
                foreach ($SVG in $SVGFilesToProcess) {
                    $SVGOParams = $SVG, "-o", $SVG
                    & $CMDSVGO $SVGOParams | Out-Null
                }
            }
        }
    }
}