using namespace System.IO
using namespace System.Collections.Generic
function Convert-OptimizeSVGsWithSVGO {
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
        [String] $OutputSubdirectoryName = "SVGO Optimized"
    )

    begin {
        if($PlaceInSubfolder -and $Overwrite){
            Write-Error "-PlaceInSubfolder and -Overwrite switches cannot be used together."
            return
        }
        $LatestNode = Get-NVMLatestNodeVersionInstalled
        Switch-NodeVersionsWithNVM -Version $LatestNode | Out-Null

        $CMDSVGO = Get-CommandSVGO -ErrorAction Stop
        $SVGFileList = [System.Collections.Generic.HashSet[string]]::new()
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
                $ChildSVGs = Get-ChildItem -LiteralPath $CurrentPath -Force -File -Recurse -Filter *.svg | % { $_.FullName }
                if($ChildSVGs){
                    foreach ($SVG in $ChildSVGs) {
                        $null = $SVGFileList.Add($SVG)
                    }

                }
            } elseif(Test-Path -LiteralPath $CurrentPath -PathType Leaf) {
                if($CurrentPath -match "\.(svg)$") {
                    $null = $SVGFileList.Add($CurrentPath)
                }
            }
        }
    }

    end {

        $ProcessedSVGFolders = [System.Collections.Generic.List[String]]@()
        $RND = Get-RandomAlphanumericString -Length 18
        $SVGFileList | ForEach-Object {
            $CurrentSVG = $_
            $CurrentSVGFolder = [System.IO.Directory]::GetParent($CurrentSVG).FullName
            if($PlaceInSubfolder){
                $DestPath = [System.IO.Path]::Combine($CurrentSVGFolder, $RND)
                New-Item -Path $DestPath -ItemType Directory -Force | Out-Null
                $CurrentSVG | Copy-Item -Destination $DestPath -Force | Out-Null
                if($DestPath -notin $ProcessedSVGFolders){
                    $null = $ProcessedSVGFolders.Add($DestPath)
                }
            }
            elseif(-not$Overwrite){
                $DestPath = [System.IO.Path]::Combine($CurrentSVGFolder, $RND)
                New-Item -Path $DestPath -ItemType Directory -Force | Out-Null
                $NewFilename = [System.IO.Path]::GetFileNameWithoutExtension($CurrentSVG) + "_svgo.svg"
                $TempDest = [System.IO.Path]::Combine($DestPath, $NewFilename)
                [IO.File]::Copy($CurrentSVG, $TempDest) | Out-Null
                $CurrentSVG | Copy-Item -Destination $DestPath -Force | Out-Null
                if($DestPath -notin $ProcessedSVGFolders){
                    $null = $ProcessedSVGFolders.Add($DestPath)
                }
            }
            elseif($Overwrite){
                if($CurrentSVGFolder -notin $ProcessedSVGFolders){
                    $null = $ProcessedSVGFolders.Add($CurrentSVGFolder)
                }
            }
        }

        $ProcessedSVGFolders | ForEach-Object {
            $Params = "-rf", $_
            & $CMDSVGO $Params | Out-Null
            if($PlaceInSubfolder){
                $DestFolderName = $OutputSubdirectoryName
                $Parent = [System.IO.Directory]::GetParent($_).FullName
                $DestFolder = [System.IO.Path]::Combine($Parent, $DestFolderName)
                $DestFolder = Get-UniqueNameIfDuplicate -LiteralPath $DestFolder
                $NewName = [System.IO.Path]::GetFileNameWithoutExtension($DestFolder)
                $_ | Rename-Item -NewName $NewName -Force | Out-Null
            }
            if((-not$PlaceInSubfolder) -and (-not$Overwrite)){
                $SVGs = Get-ChildItem -LiteralPath $_ -File -Filter *.svg -Force | % {$_.FullName}
                $Dest = [System.IO.Path]::GetDirectoryName($_)
                $SVGs | Move-Item -Destination $Dest -Force | Out-Null
                Remove-Item -LiteralPath $_ -Force -Recurse | Out-Null
            }
        }
    }
}