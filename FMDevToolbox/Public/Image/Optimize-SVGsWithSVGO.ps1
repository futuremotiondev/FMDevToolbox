using namespace System.IO
using namespace System.Collections.Generic

function Optimize-SVGsWithSVGO {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage="Literal path to one or more locations."
        )]
        [ValidateScript({$_ -notmatch '[\?\*]'},
            ErrorMessage = "Wildcard characters *, ? are not acceptable with -LiteralPath")]
        [ValidateScript({[System.IO.Path]::IsPathRooted($_)},
            ErrorMessage = "Relative paths are not allowed in -LiteralPath.")]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $PlaceInSubfolder,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({
            $invalidFileNameChars = [System.IO.Path]::GetInvalidFileNameChars()
            $invalidPathChars = [System.IO.Path]::GetInvalidPathChars()
            if ($_.IndexOfAny($invalidFileNameChars) -ne -1 -or $_.IndexOfAny($invalidPathChars) -ne -1) {
                throw "The directory name '$_' contains invalid characters."
            }
            $true
        })]
        [String] $SubfolderName = "SVGO",

        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $Parallel,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Int32] $MaxThreads = 18
    )

    begin {

        $NVM_FOR_WINDOWS_IS_INSTALLED = $false
        if($env:NVM_HOME -and $env:NVM_SYMLINK) {
            $NVM_FOR_WINDOWS_IS_INSTALLED = $true
        }

        $nvmCmd = Get-Command nvm.exe -CommandType Application -ErrorAction 0
        if(-not $nvmCmd){
            throw "Can't find nvm.exe in PATH."
        }

        if($NVM_FOR_WINDOWS_IS_INSTALLED){
            function ReturnLatestNodeWithSVGO {
                $VersionsWithSVGO = @()
                $InstalledVersions = Get-ChildItem -LiteralPath $env:NVM_HOME -Directory -Force | Where-Object { ($_.Name).StartsWith('v') }
                foreach ($nodeVersion in $InstalledVersions) {
                    $svgoCmdPath = Join-Path -Path $nodeVersion.FullName -ChildPath 'svgo.cmd'
                    if(Test-Path -Path $svgoCmdPath){
                        $VersionsWithSVGO += ($nodeVersion.BaseName).TrimStart('v')
                    }
                }
                $VersionsWithSVGO | Sort-Object -Descending | Select-Object -First 1
            }

            $latestVersionWithSVGO = ReturnLatestNodeWithSVGO
            if(-not$latestVersionWithSVGO){
                throw "No installed versions of NodeJS have SVGO installed."
            }

            $activeVersion = (Get-NodeInstalledVersionDetails -Active).Version
            if($activeVersion -ne $latestVersionWithSVGO){
                & $nvmCmd "use" $latestVersionWithSVGO
            }
        }

        $cmdSvgo = Get-Command svgo.cmd -CommandType Application -ErrorAction SilentlyContinue
        if(-not$cmdSvgo){
            Write-Error "SVGO isn't installed. Install it by running 'npm install -g svgo', or 'yarn global add svgo'"
        }

        $svgFolderList = [List[DirectoryInfo]]@()
        $svgFileList = [List[FileInfo]]@()
    }

    process {
        $resolvedPaths = Get-Item -LiteralPath $LiteralPath -Force
        foreach ($resolvedItem in $resolvedPaths) {
            if($resolvedItem.PSIsContainer){
                $null = $svgFolderList.Add($resolvedItem)
            }
            elseif(Test-Path -LiteralPath $resolvedItem -PathType Leaf){
                if($resolvedItem.FullName -match "\.(svg)$") {
                    $null = $svgFileList.Add($resolvedItem)
                }
            }
        }
    }

    end {

        $filesToDirectlyProcess = [HashSet[String]]@()
        $foldersToDirectlyProcess = [HashSet[String]]@()

        if($svgFolderList){
            foreach ($curFolder in $svgFolderList) {
                $containingSvgs = Get-ChildItem -LiteralPath $curFolder.FullName -File -Filter *.svg
                if(($containingSvgs.Count -eq 0) -or (-not$containingSvgs)){
                    Write-Warning "Skipping '$($curFolder.FullName)' as it contains no SVG files."
                    continue
                }
                if($PlaceInSubfolder){
                    $subfolderPath = [Path]::Combine($curFolder.FullName, $SubfolderName)
                    $newSubfolderFullname = (New-Item -Path $subfolderPath -ItemType Directory -Force).FullName
                    try {
                        $containingSvgs | % {
                            $curSvg = $_.FullName
                            $finalCopyPath = [Path]::Combine($newSubfolderFullname, $_.Name)
                            [File]::Copy($curSvg, $finalCopyPath, $true) | Out-Null
                        }
                        $foldersToDirectlyProcess.Add($newSubfolderFullname)
                    }
                    catch {
                        Write-Error "Error copying $($containingSvgs) to '$newSubfolderFullname'"
                        continue
                    }
                }
                else {
                    $null = $foldersToDirectlyProcess.Add($curFolder.FullName)
                }
            }
        }

        if($svgFileList){
            foreach ($svg in $svgFileList) {
                if($PlaceInSubfolder){
                    $newSubfolderPath = [System.IO.Path]::Combine($svg.Directory, $SubfolderName)
                    if($foldersToDirectlyProcess -notcontains $newSubfolderPath){
                        New-Item -Path $newSubfolderPath -ItemType Directory -Force | Out-Null
                        $null = $foldersToDirectlyProcess.Add($newSubfolderPath)
                    }
                    try {
                        $newSvgPath = [System.IO.Path]::Combine($newSubfolderPath, $svg.Name)
                        [IO.File]::Copy($svg.FullName, $newSvgPath, $true)
                    }
                    catch {
                        Write-Error "Error copying '$($svg.FullName)' to '$newSubfolderPath' Details: $_"
                        continue
                    }
                }
                else {
                    $null = $filesToDirectlyProcess.Add($svg.FullName)
                }
            }
        }


        if($Parallel){
            if($foldersToDirectlyProcess.Count -gt 0){
                $foldersToDirectlyProcess | % -Parallel {
                    $cmdSvgo = Get-Command svgo.cmd -CommandType Application -ErrorAction 0
                    $curFolderFullname = $_
                    $svgoParams = '-rf', $curFolderFullname
                    & $cmdSvgo $svgoParams
                } -ThrottleLimit $MaxThreads
            }

            if($filesToDirectlyProcess.Count -gt 0){
                $filesToDirectlyProcess | % -Parallel {
                    $cmdSvgo = Get-Command svgo.cmd -CommandType Application -ErrorAction 0
                    $curFileFullname = $_
                    $svgoParams = $curFileFullname
                    & $cmdSvgo $svgoParams
                } -ThrottleLimit $MaxThreads
            }
        }
        else {
            if($foldersToDirectlyProcess.Count -gt 0){
                $foldersToDirectlyProcess | % {
                    $curFolderFullname = $_
                    $svgoParams = '-rf', $curFolderFullname
                    & $cmdSvgo $svgoParams
                }
            }
            if($filesToDirectlyProcess.Count -gt 0){
                $filesToDirectlyProcess | % {
                    $curFileFullname = $_
                    $svgoParams = $curFileFullname
                    & $cmdSvgo $svgoParams
                }
            }
        }

        Write-SpectreHost "[#3FEE9C][[SUCCESS]][/] All files have been processed with SVGO."
    }
}