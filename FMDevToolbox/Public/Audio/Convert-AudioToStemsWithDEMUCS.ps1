using namespace System.Collections.Generic

function Convert-AudioToStemsWithDEMUCS {

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

        [Parameter(
			ValueFromPipelineByPropertyName,
			HelpMessage="The output folder to save the stems."
		)]
        [ValidateScript({$_ -notmatch '[\?\*]'},
            ErrorMessage = "Wildcard characters *, ? are not acceptable with -OutputDirectory")]
        [ValidateNotNullOrEmpty()]
        [String] $OutputDirectory = 'DEMUCS Separated',

        [Parameter(HelpMessage="The path to your miniconda installation.")]
        [ValidateNotNullOrEmpty()]
        [String] $MinicondaInstallPath = "C:\Python\miniconda3",

        [Parameter(HelpMessage="The name of your conda environment where DEMUCS is fully installed.")]
        [ValidateNotNullOrEmpty()]
        [String] $DemucsVenvName = "DEMUCS",

        # MDX and MDX_EXTRA seem to perform better with bass heavy
        # music. Drum isolation is cleaner.
		[Parameter(HelpMessage="The DEMUCS model to use. MDX and MDX_EXTRA generally perform better.")]
        [ValidateSet('htdemucs', 'htdemucs_ft', 'htdemucs_6s', 'hdemucs_mmi', 'mdx','mdx_extra')]
        [String] $Model = 'mdx_extra',

        # By Default DEMUCS separates incoming audio into all stems: Drums, Vocals, Bass, and Other.
        # However, you can enable a two-stem separation mode where you can instruct DEMUCS to
        # separate one selected stem to wave, and the remaining to another "Other" wave output. By
        # setting `-Stems` to "Drums", DEMUCS will output two files, the drums-only stem, and
        # another "Other" stem that includes everything except the drums.
		[Parameter(HelpMessage="Specifies what stems to extract from the input file.")]
        [ValidateSet('All','Vocals','Drums','Bass','Other')]
        [String] $Stems = 'All',


        # Regarding Segments:
        # DEMUCS by defailt splits the incoming audio into chunks to help with lowering memory
        # demands. The segment value is an integer describing the size of each chunk (split) in
        # seconds. If you have a GPU, but you run out of memory, you can lower the segment value. A
        # segment length of at least 10 is recommended (the bigger the number is, the more memory is
        # required, but quality may increase). Note that the Hybrid Transformer models only support
        # a maximum segment length of 7.8 seconds. If this still does not help, please add -UseCPU
        # to $true in this function. This will disable GPU acceleration but allow you to Still
        # separate tracks (With a heavy performance penalty).
        #
        # -MDXSegment: The segment value for non Hybrid Transformer models like `mdx_extra`. If you
        # choose a model such as `mdx_extra`, this segment value will be passed to DEMUCS.
        #
        # -HTDemucsSegment: The segment value for Hybrid Transformer models like `htdemucs_ft`. If
        # you choose a model such as `htdemucs_ft`, this segment value will be passed to DEMUCS.
		[Parameter(HelpMessage="Segment value for non Hybrid Transformer models (mdx_extra).")]
        [String] $MDXSegment = '88',
        [Parameter(HelpMessage="Segment value for Hybrid Transformer models (htdemucs_ft).")]
        [String] $HybridSegment = '25',


        # -BitDepth specifies the output bit-depth of the separated stems. Valid values are 16-Bit
        # Wave, 24-Bit Wave, and 32-Bit Wave. 16-Bit is the default. If you set -BitDepth to 24, the
        # `--int24` flag is passed to DEMUCS. If you set -BitDepth to 32, the `--float32` flag is
        # passed to DEMUCS.
        [Parameter(HelpMessage="Specifies the output bit-depth of the separated stems.")]
        [ValidateSet('16','24','32', IgnoreCase = $true)]
        [String] $BitDepth = '16',

        # SHIFTS performs multiple predictions with random shifts (Randomized equivariant
        # stabilization) of the input and averages them. This makes prediction `-Shifts` times
        # slower but improves the accuracy of DEMUCS by 0.2 points of SDR (signal-to-distortion
        # ratio). The value of 10 was used on the original paper, although 5 yields mostly the same
        # gain. This function defaults to 5. This also means that separation is five times slower,
        # but will yeild higher quality results.
        [Parameter(HelpMessage="Performs multiple predictions with random shifts (Randomized equivariant stabilization). Higher values are slower by a factor of 1 * `Shifts`, but can increase SDR (signal-to-distortion ratio).")]
        [ValidateRange(0,10)]
        [String] $Shifts = '5',

        # If -CPU is set, DEMUCS will not use CUDA and your GPU to accelerate stem separation. This
        # will greatly increase the time it takes to separate input audio. The default setting uses
        # your GPU and CUDA, and is generally much faster.
        [Parameter(HelpMessage="When set, DEMUCS will not use CUDA and your GPU to accelerate stem separation, but your CPU instead.")]
        [Switch] $CPU,

        [Parameter(HelpMessage="When set, this function will scan recursively within all passed folders and separate every audio file found.")]
        [Switch] $Recurse

    )

    begin {
        # Activate the conda environment for DEMUCS.
        $condaHook = [System.IO.Path]::Combine($MinicondaInstallPath, 'shell', 'condabin', 'conda-hook.ps1')
        & $condaHook
        try {
            conda activate $DemucsVenvName
        }
        catch {
            throw "An error occurred activating $DemucsVenvName. (Specified by -DemucsVenvName). More details: $_"
        }

        $audioFileList = [HashSet[String]]::new()

        if([String]::IsNullOrEmpty($OutputDirectory)){
            $OutputDirectory = 'DEMUCS Separated'
        }

        $OuputDirectoryIsAbsolute = $false
        if([System.IO.Path]::IsPathRooted($OutputDirectory)){
            $OuputDirectoryIsAbsolute = $true
            try {
                if(-not(Test-Path -LiteralPath $OutputDirectory -PathType Container)){
                    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
                }
            }
            catch {
                throw "Couldn't create output directory. Details: $($_.Exception.Message)"
            }
        }
    }

    process {

        $resolvedPaths = if($PSBoundParameters['Path']) {
            $Path | Get-Item -Force
        } elseif($PSBoundParameters['LiteralPath']) {
            Get-Item -LiteralPath $LiteralPath -Force
        }
        $resolvedPaths | % {
            $currentResolvedItem = $_
            $currentResolvedItemFullname = ($currentResolvedItem.FullName).TrimEnd("\")
            if (Test-Path -LiteralPath $currentResolvedItemFullname -PathType Container) {
                $gciSplat = @{
                    LiteralPath = $currentResolvedItemFullname
                    Force	    = $true
                    ErrorAction = 'SilentlyContinue'
                    File		= $true
                    Include     = ('*.wav', '*.flac', "*.mp3", "*.ogg")
                }
                if($PSBoundParameters.ContainsKey('Recurse')){
                    $gciSplat['Recurse'] = $true
                }
                $childItems = Get-ChildItem @gciSplat
                if($childItems){
                    foreach ($item in $childItems) {
                        $null = $audioFileList.Add(($item.FullName).TrimEnd("\"))
                    }
                }
            } elseif(Test-Path -LiteralPath $currentResolvedItemFullname -PathType Leaf) {
                if($currentResolvedItem.Extension -in @('.wav', '.flac', ".mp3", ".ogg")){
                    $null = $audioFileList.Add($currentResolvedItemFullname)
                }
            }
        }

        $audioFileList | % {

            $DFileObj     = Get-Item -LiteralPath $_ -Force
            $DFile        = $DFileObj.FullName
            $DFileName    = $DFileObj.Name
            $DFolder      = $DFileObj.Directory.FullName
            $Model        = $Model.ToLower()
            $DOutFilename = "$(Get-Date -Format 'MM-dd-yyyy-ffff') {track} - {stem}.{ext}"
            $DSegmentNum  = ($Model -like 'mdx*') ? $MDXSegment : $HybridSegment
            $DUseCPUStr   = ($CPU) ? 'cpu' : 'cuda'

            # Determine output bit depth
            $DBitDepth = switch ($BitDepth) {
                '24' { '--int24' }
                '32' { '--float32' }
                default { $null }
            }

            # Determine stems options
            $DStems = switch ($Stems) {
                'drums' { '--two-stems=drums' }
                'vocals' { '--two-stems=vocals' }
                'bass' { '--two-stems=bass' }
                'other' { '--two-stems=other' }
                default { $null }
            }


			$headerPanelSplat = @{
				Message = "[#9DA0A4]DEMUCS Settings for[/] [#FFFFFF]$DFileName[/]"
				PanelWidth = 'FullWidth'
				PanelHeight = 'Medium'
			}
            Write-Host "`r`n"
			Show-FMSpectreBorderedHeaderPanel @headerPanelSplat

            $StemOutputFolder = if (-not $OuputDirectoryIsAbsolute) {
                $D = Join-Path $DFolder -ChildPath $OutputDirectory
                try {
                    if (-not (Test-Path -LiteralPath $D)) {
                        mkdir $D -Force | Out-Null
                    }
                } catch { throw "Failure creating output directory for $DFileName. ($D) Details: $($_.Exception.Message)" }
                $D
            } else {
                $OutputDirectory
            }


            if(-not ($OuputDirectoryIsAbsolute)){
                try {
                    $StemOutputFolder = Join-Path $DFolder -ChildPath $OutputDirectory
                    if(-not(Test-Path -LiteralPath $StemOutputFolder -PathType Container)){
                        New-Item -Path $StemOutputFolder -ItemType Directory -Force
                    }
                }
                catch {
                    throw "Couldn't create the output directory for $DFileName. ($StemOutputFolder) Details: $_"
                }
            }
            else {
                $StemOutputFolder = $OutputDirectory
            }

			[PSCustomObject]@{
				FileName         = $DFileName
				Model            = $Model.ToUpper()
				Stems            = $Stems.ToUpper()
				BitDepth         = $BitDepth
				ComputeDevice    = $DUseCPUStr
				OutputFolder     = $StemOutputFolder
			} | Format-SpectreTable -Border Rounded -Color "#66696B" -TextColor "#FFFFFF" -Expand

            $ModelFormatted = $Model.ToLower().Trim()
			# & print_argv.exe -n $ModelFormatted -v -o "$StemOutputFolder" "--filename" "$DOutFilename" -d "$DUseCPUStr" "--shifts" $Shifts --segment "$DSegmentNum" $DStems $DBitDepth $DFile | Tee-Object -Variable output | Out-Null
			& demucs -n $ModelFormatted -v -o "$StemOutputFolder" "--filename" "$DOutFilename" -d "$DUseCPUStr" "--shifts" $Shifts --segment "$DSegmentNum" $DStems $DBitDepth $DFile | Tee-Object -Variable output | Out-Null
		}
    }
    end {
        conda deactivate
    }
}

