function Convert-SVGCropWithInkscape {
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
        [String] $InkscapeInstall = 'C:\Tools\inkscape\bin',
        [Switch] $Overwrite,
        [Switch] $PlaceInSubfolder,
        [String] $DestSubfolderName = "Cropped",
        [Switch] $Recurse
    )

    begin {

        # $LogFileName = "InkscapeSVGCrop_$((Get-Date -Format "yyyy-MM-dd_(mm{0}ss{1}fff{2})") -f "m","s","ms").log"
        # $LogFileRoot = $script:FMUserLogDir
        # if(-not(Test-Path -LiteralPath $LogFileRoot -PathType Container)){
        #     New-Item -Path $LogFileRoot -ItemType Directory -Force
        # }
        # $LogFilePath = Join-Path $LogFileRoot -ChildPath $LogFileName


        if(-not(Test-Path -LiteralPath $InkscapeInstall -PathType Container)){
            # New-Log -Message "The directory specified in -InkscapeInstall doesn't exist. Pass the correct Inkscape install directory to -InkscapeInstall." -Level ERROR -LogFilePath $LogFilePath
            throw "Passed -InkscapeInstall doesn't exist."
        }
        $inkPath = Join-Path $InkscapeInstall -ChildPath 'inkscape.exe'
        $cmdInk = Get-Command $inkPath -CommandType Application -EA 0
        if(-not($cmdInk)){
            # New-Log -Message "Inkscape.exe cannot be found in the passed -InkscapeInstall location." -Level ERROR -LogFilePath $LogFilePath
            throw "Inkscape.exe cannot be located in the passed -InkscapeInstall location."
        }
        if($PSBoundParameters['Overwrite'] -and $PSBoundParameters['PlaceInSubfolder']){
            # New-Log -Message "-Overwrite and -PlaceInSubfolder shouldn't be used together. Defaulting to -PlaceInSubfolder." -Level WARNING -LogFilePath $LogFilePath
            Write-Warning "-Overwrite and -PlaceInSubfolder shouldn't be used together. Defaulting to -PlaceInSubfolder."
            $Overwrite = $false
        }

        $svgTargets = [List[Object]]::new()
    }

    process {
        $resolved = if ($PSBoundParameters['Path']) {
            $Path | Get-Item -Force
        } elseif($PSBoundParameters['LiteralPath']) {
            $LiteralPath | Get-Item -Force
        }

        $resolved | % {
            $item = $_
            if($item.PSIsContainer) {
                $svgSplat = @{
                    Filter = '*.svg';
                    Force  = $true;
                    Path = $item.FullName;
                    File = $true;
                }
                if($PSBoundParameters['Recurse']){
                    # New-Log -Message "-Recurse flag has been set. Collecting all SVGs in every folder recursively." -Level INFO -LogFilePath $LogFilePath
                    $svgSplat['Recurse'] = $true
                }
                [Object[]] $svgFiles = gci @svgSplat | % { $_ }
                if($svgFiles){
                    # New-Log -Message "Adding all $($svgFiles.Count) SVG files in folder '$($item.Name)':" -Level INFO -LogFilePath $LogFilePath
                    foreach ($svgFile in $svgFiles) {
                        New-Log -Message "─── Added SVG: '$($svgFile.Name)'" -Level INFO -LogFilePath $LogFilePath
                        $null = $svgTargets.Add($svgFile)
                    }
                }
                else {
                    # New-Log -Message "No SVG files were found in folder $($item.Name)" -Level INFO -LogFilePath $LogFilePath
                }
            }
            else {
                if($_.Extension -eq '.svg') {
                    # New-Log -Message "─── Added SVG: '$($_.Name)'" -Level INFO -LogFilePath $LogFilePath
                    $null = $svgTargets.Add($_)
                }
            }
        }
        if(-not $svgTargets){
            # New-Log -Message "No valid SVGs were found in passed locations." -Level ERROR -LogFilePath $LogFilePath
            return
        }
    }

    end {
        $inkscapeActions = [List[String]]@()
        $svgTargets | % {
            $curSvg           = $_
            $curSvgName       = $_.Name
            $curSvgFullname   = $_.FullName
            $curSvgFolder     = $curSvg.Directory
            $curSvgBase       = $curSvg.BaseName

            if($PSBoundParameters['PlaceInSubfolder']){

                # New-Log "-PlaceInSubfolder is set. SVGs will be added to a subfolder called $DestSubfolderName in their current directories" INFO -LogFilePath $LogFilePath

                $newSubfolder = Join-Path $curSvgFolder -ChildPath $DestSubfolderName
                if(-not(Test-Path -LiteralPath $newSubfolder -PathType Container)){
                    try {
                        New-Item -Path $newSubfolder -ItemType Directory -Force | Out-Null
                        # New-Log "Created subfolder to store cropped svgs: $newSubfolder" SUCCESS -LogFilePath $LogFilePath
                    }
                    catch {
                        # New-Log "Unable to create subfolder for cropped SVGs. ($newSubfolder)" ERROR -LogFilePath $LogFilePath -IncludeCallerInfo
                        throw "Unable to create subfolder for cropped SVGs. ($newSubfolder)"
                    }
                }
                $destPath = Join-Path $newSubfolder -ChildPath $curSvgName
                $destPath = Get-UniqueNameIfDuplicate -LiteralPath $destPath
                # New-Log "Queuing up SVG file '$curSvgFullname' for crop operation. Final cropped file will be '$destPath'." INFO -LogFilePath $LogFilePath
                $null = $inkscapeActions.Add("file-open:$curSvgFullname; export-area-drawing; export-filename:$destPath; export-do`r`n")
            }
            else{
                if($Overwrite){
                    # New-Log "-Overwrite flag was set. Cropped SVGs will overwrite their originals." INFO -LogFilePath $LogFilePath
                    $null = $inkscapeActions.Add("file-open:$curSvgFullname; export-area-drawing; export-filename:$curSvgFullname; export-do`r`n")
                }
                else {
                    # New-Log "-Overwrite flag was not set. Cropped SVGs will be renamed with a '_Cropped' suffix." INFO -LogFilePath $LogFilePath
                    $destName = "${curSvgFolder}\${curSvgBase}_Cropped.svg"
                    $finalName = Get-UniqueNameIfDuplicate -LiteralPath $destName
                    if($destName -ne $finalName){
                        New-Log "Filename collision was detected, renaming final SVG from '$destName' to '$finalName'." INFO -LogFilePath $LogFilePath
                    }
                    # New-Log "Queuing up SVG file '$curSvgFullname' for crop operation. Cropped filename will be $finalName." INFO -LogFilePath $LogFilePath
                    $null = $inkscapeActions.Add("file-open:$curSvgFullname; export-area-drawing; export-filename:$finalName; export-do`r`n")
                }
            }
        }
        # New-Log -Message "Preparing for crop operation with Inkscape on $($svgTargets.Count) SVG files. Listing files to be cropped:" -Level INFO -LogFilePath $LogFilePath
        foreach ($tsvg in $svgTargets) {
            # New-Log -Message "─── $($tsvg.FullName) will be cropped." -Level INFO -LogFilePath $LogFilePath
        }
        $null = $inkscapeActions.Add("`r`nquit")
        try {
            $inkscapeActions | & $cmdInk "--shell" | Out-Null
        }
        catch {
            Write-Error "An error occurred cropping. Details: $($_.Exception.Message)" -ErrorAction Continue
        }
        if($LASTEXITCODE -eq 0){
            # New-Log -Message "Finished cropping $($svgTargets.Count) SVG files with inkscape." -Level SUCCESS -LogFilePath $LogFilePath
        }
        else{
            # New-Log -Message "The script attempted to crop $($svgTargets.Count) SVG files, but the last exit code was not 0. An error probably occurred." -Level ERROR -IncludeCallerInfo -LogFilePath $LogFilePath
        }
    }
}