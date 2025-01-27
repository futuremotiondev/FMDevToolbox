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
			Mandatory,
			Position=1,
			ValueFromPipelineByPropertyName,
			HelpMessage="The output folder to save the stems."
		)]
		[ValidateScript({$_ -notmatch '[\?\*]'},
            ErrorMessage = "Wildcard characters *, ? are not acceptable with -OutputFolder")]
        [ValidateScript({[System.IO.Path]::IsPathRooted($_)},
            ErrorMessage = "Relative paths are not allowed in -OutputFolder.")]
        [ValidateNotNullOrEmpty()]
        [String] $OutputFolder,

        [Parameter(HelpMessage="The path to your miniconda installation.")]
        [ValidateNotNullOrEmpty()]
        [String] $MinicondaInstallPath = "C:\Python\miniconda3",

        [Parameter(HelpMessage="The name of your conda environment where DEMUCS is fully installed.")]
        [ValidateNotNullOrEmpty()]
        [String] $DemucsVenvName = "DEMUCS",

        # MDX and MDX_EXTRA seem to perform better with bass heavy
        # music. Drum isolation is cleaner.
		[Parameter(HelpMessage="The DEMUCS model to use. MDX and MDX_EXTRA generally perform better.")]
        [ValidateSet('HTDEMUCS_FT','MDX','MDX_EXTRA')]
        [String] $Model = 'MDX_EXTRA',


		[Parameter(HelpMessage="Specifies what stems to extract from the input file.")]
        [ValidateSet('ALL','DRUMS','VOCALS','BASS','OTHER')]
        [String] $Stems = 'ALL',

		[Parameter(HelpMessage="Specifies what stems to extract from the input file.")]
        [String] $MDXSegment = '88',


        # If you want to use GPU acceleration, you will need at least
        # 3GB of RAM on your GPU for demucs. However, about 7GB of
        # RAM will be required if you use the default arguments. Add
        # --segment SEGMENT to change size of each split. If you only
        # have 3GB memory, set SEGMENT to 8 (though quality may be
        # worse if this argument is too small).

        [Parameter()]
        [String] $HTDemucsSegment = '25',

        [Parameter(HelpMessage="The bit-depth of the resulting stems.")]
        [ValidateSet('16','24','32', IgnoreCase = $true)]
        [String] $BitDepth = '16',

        # SHIFTS performs multiple predictions with random shifts
        # (a.k.a randomized equivariant stabilization) of the input
        # and average them. This makes prediction SHIFTS times slower
        # but improves the accuracy of Demucs by 0.2 points of SDR.
        # The value of 10 was used on the original paper, although 5
        # yields mostly the same gain. It is deactivated by default.
        [Parameter(HelpMessage="SHIFTS performs multiple predictions with random shifts of the input and average them. This makes extraction times slower but improves accuracy slightly.")]
        [String] $Shifts = '0',

        [Parameter(HelpMessage="Set this if you want to use your CPU for stem separation. The default setting uses your GPU and is generally faster.")]
        [Switch] $UseCPU = $false

    )

    begin {
        # Activate the conda environment for DEMUCS.
        $condaHook = [System.IO.Path]::Combine($MinicondaInstallPath, 'shell', 'condabin', 'conda-hook.ps1')
        & $condaHook
        conda activate $DemucsVenvName
    }

    process {
        $resolvedPaths = if($PSBoundParameters['Path']) {
            $Path | Get-Item -Force
        } elseif($PSBoundParameters['LiteralPath']) {
            Get-Item -LiteralPath $LiteralPath -Force
        }
        $resolvedPaths | % {
			if(-not(Test-Path -LiteralPath $OutputFolder -PathType Container)){
				Write-Error "Output folder does not exist. Skipping this file $($_.Name)"
				return
			}
            $DFile           = $_.FullName
            $DFileName       = $_.Name
            $DTime           = Get-Date -Format 'MM-dd-yyyy-ffff'
            $DFNameStart     = "{0} {1}" -f $DTime, $Model
            $DOutFilename    = "($DFNameStart) {track} - {stem}.{ext}"
            $DSegmentNum     = ($Model -eq 'mdx_extra') ? $MDXSegment : $HTDemucsSegment
            $DUseCPUStr      = ($UseCPU -eq $true) ? 'cpu' : 'cuda'
			$DBitDepth = switch ($BitDepth) {
				"16" { '' }; "24" { '--int24' }; "32" { '--float32' };
			}
			$DStems = switch ($Stems) {
				'all' { '' }; 'drums' { '--two-stems=drums' }; 'vocals' { '--two-stems=vocals' };
				'bass' { '--two-stems=bass' }; 'other' { '--two-stems=other' };
			}
			$headerPanelSplat = @{
				Message = "[#9DA0A4]DEMUCS Settings for[/] [#FFFFFF]$DFileName[/]"
				PanelWidth = 'FullWidth'
				PanelHeight = 'Medium'
			}
			Show-FMSpectreBorderedHeaderPanel @headerPanelSplat
			[PSCustomObject]@{
				FileName         = $DFileName
				Model            = $Model.ToUpper()
				Stems            = $Stems.ToUpper()
				BitDepth         = $BitDepth
				Segment          = $DSegmentNum
				Shifts           = $Shifts
				ComputeDevice    = $DUseCPUStr
				StemOutputFolder = $OutputFolder
			} | Format-SpectreTable -Border Rounded -Color "#66696B" -TextColor "#FFFFFF" -Expand

			Write-Host "`n"

			& demucs -n $Model -v "-o" "$OutputFolder" "--filename" "$DOutFilename" "-d" "$DUseCPUStr" "--shifts" $Shifts $DStems $DBitDepth "$DFile" | Tee-Object -Variable output | Out-Null

		}

        end {
            conda deactivate
        }
    }
}

