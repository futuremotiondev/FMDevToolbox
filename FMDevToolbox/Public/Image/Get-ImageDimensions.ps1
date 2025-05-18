using namespace System.Collections.Generic

function Get-ImageDimensions {
    [cmdletbinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "Path",
            HelpMessage="Path to one or more images (Supports wildcards)."
        )]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [String[]] $Path,

        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "LiteralPath",
            HelpMessage="Literal path to one or more images."
        )]
        [ValidateScript({$_ -notmatch '[\?\*]'},
            ErrorMessage = "Wildcard characters *, ? are not acceptable with -LiteralPath")]
        [ValidateScript({[System.IO.Path]::IsPathRooted($_)},
            ErrorMessage = "Relative paths are not allowed in -LiteralPath.")]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,
        [Switch] $Recurse,
        [Int32] $Depth = 10,
        [Int32] $MaxThreads = 24

    )

    begin {
        $supportedImageTypes = @('.bmp','.gif','.jpeg','.jpg','.png','.tif','.tiff')
        $imagesToProcess = [HashSet[String]]@()
    }

    process {
        $resolvedPaths = if ($PSBoundParameters['Path']) {
            $Path | Get-Item -Force
        } elseif($PSBoundParameters['LiteralPath']) {
            $LiteralPath | Get-Item -Force
        }
        $resolvedPaths | % {
            $fName = $_.FullName
            if (Test-Path -LiteralPath $fName -PathType Container) {
                $imageFiles = if($PSBoundParameters.ContainsKey('Recurse')){
                    Get-ChildItem -LiteralPath $fName -Force -Recurse -Depth $Depth -File -EA 0 |
                        Where-Object { $_.Extension -in $supportedImageTypes }
                } else{
                    Get-ChildItem -LiteralPath $fName -Force -File -EA 0 |
                        Where-Object { $_.Extension -in $supportedImageTypes }
                }
                if($imageFiles){
                    foreach ($img in $imageFiles) {
                        $null = $imagesToProcess.Add($img.FullName)
                    }
                }
            } elseif(Test-Path -LiteralPath $fName -PathType Leaf) {
                if($_.Extension -in $supportedImageTypes){
                    $null = $imagesToProcess.Add($fName)
                }
            }
        }
    }

    end {

        $imagesToProcess | ForEach-Object -Parallel {
            $imgObject = [System.Drawing.Image]::FromFile($_)
            try {
                [PSCustomObject]@{
                    ImageName = [System.IO.Path]::GetFileName($_)
                    Width     = $imgObject.Width
                    Height    = $imgObject.Height
                    Extension = [System.IO.Path]::GetExtension($_)
                    FullPath  = $image
                }
            } finally {
                $imgObject.Dispose()
            }
        } -ThrottleLimit $MaxThreads
    }
}