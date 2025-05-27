using namespace System.IO
using namespace System.Collections.Generic

function Optimize-SVGsWithSVGO {
    <#
    .SYNOPSIS
    Optimizes SVG files using SVGO.

    .DESCRIPTION
    This function processes SVG files located at specified paths, optimizing them
    using SVGO. It supports processing files in parallel and can place optimized
    files into a subfolder.

    .PARAMETER LiteralPath
    Specifies the literal path to one or more locations containing SVG files.
    Wildcard characters are not supported.

    .PARAMETER PlaceInSubfolder
    Indicates whether the optimized SVG files should be placed in a subfolder.

    .PARAMETER SubfolderName
    Specifies the name of the subfolder where optimized SVG files will be placed if
    PlaceInSubfolder is used. Defaults to "SVGO".

    .PARAMETER Parallel
    Enables parallel processing of SVG files for optimization.

    .PARAMETER MaxThreads
    Specifies the maximum number of threads to use for parallel processing.
    Defaults to 18.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to optimize SVG files from a specific directory.
    Optimize-SVGsWithSVGO -LiteralPath "C:\SVGs"

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to optimize SVG files and place them in a subfolder named "Optimized".
    Optimize-SVGsWithSVGO -LiteralPath "C:\SVGs" -PlaceInSubfolder -SubfolderName "Optimized"

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to optimize SVG files using parallel processing with a custom thread limit.
    Optimize-SVGsWithSVGO -LiteralPath "C:\SVGs" -Parallel -MaxThreads 10

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to optimize SVG files from multiple directories using pipeline input.
    "C:\SVGs1", "C:\SVGs2" | Optimize-SVGsWithSVGO

    .EXAMPLE
    # **Example 5**
    # This example demonstrates how to optimize SVG files from a directory and place them in a default subfolder.
    Optimize-SVGsWithSVGO -LiteralPath "C:\SVGs" -PlaceInSubfolder

    .EXAMPLE
    # **Example 6**
    # This example demonstrates how to handle errors when optimizing SVG files.
    try {
        Optimize-SVGsWithSVGO -LiteralPath "C:\SVGs"
    } catch {
        Write-Error "An error occurred during SVG optimization."
    }

    .OUTPUTS
    Writes success messages to the host upon successful optimization of SVG files.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 05-17-2025
    #>
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

        # Helper function to generate a unique subfolder path
        function Get-UniqueSubfolderPath {
            param (
                [string]$baseDirectory,
                [string]$subfolderName
            )

            $uniquePath = [System.IO.Path]::Combine($baseDirectory, $subfolderName)
            $counter = 2

            while (Test-Path -Path $uniquePath) {
                $uniquePath = [System.IO.Path]::Combine($baseDirectory, "$subfolderName {0:D2}" -f $counter)
                $counter++
            }

            return $uniquePath
        }

        if ($svgFileList) {
            # Group SVGs by their base directory
            $groupedByDirectory = $svgFileList | Group-Object { [System.IO.Path]::GetDirectoryName($_) }

            foreach ($group in $groupedByDirectory) {
                $baseDirectory = $group.Name
                $svgFiles = $group.Group

                if ($PlaceInSubfolder) {
                    # Check if a subfolder path is already recorded for this base directory
                    $existingSubfolderPath = $foldersToDirectlyProcess | Where-Object { $_ -like "$baseDirectory\$SubfolderName*" } | Select-Object -First 1

                    if (-not $existingSubfolderPath) {
                        # Use the helper function to get a unique subfolder path
                        $newSubfolderPath = Get-UniqueSubfolderPath -baseDirectory $baseDirectory -subfolderName $SubfolderName

                        New-Item -Path $newSubfolderPath -ItemType Directory -Force | Out-Null
                        $null = $foldersToDirectlyProcess.Add($newSubfolderPath)
                    }
                    else {
                        $newSubfolderPath = $existingSubfolderPath
                    }

                    foreach ($svg in $svgFiles) {
                        try {
                            $svgFullName = [System.IO.Path]::GetFullPath($svg)
                            $svgName = [System.IO.Path]::GetFileName($svg)
                            $newSvgPath = [System.IO.Path]::Combine($newSubfolderPath, $svgName)
                            [IO.File]::Copy($svgFullName, $newSvgPath, $true)
                        }
                        catch {
                            Write-Error "Error copying '$svg' to '$newSubfolderPath' Details: $_"
                            continue
                        }
                    }
                }
                else {
                    foreach ($svg in $svgFiles) {
                        $null = $filesToDirectlyProcess.Add([System.IO.Path]::GetFullPath($svg))
                    }
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

        Write-SpectreHost "`n[#3FEE9C][[SUCCESS]][/] All files have been processed with SVGO."
    }
}