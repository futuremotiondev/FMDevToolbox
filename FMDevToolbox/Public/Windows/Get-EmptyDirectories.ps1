Function Get-EmptyDirectories {
    [CmdletBinding(DefaultParameterSetName="Path")]
    param(
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

        [Parameter(Mandatory = $false)]
        [switch] $Recurse

    )
    begin {}
    process {
        $resolvedPaths = if($PSBoundParameters['Path']) {
            $Path | Get-Item -Force | % {
                if($_.PSIsContainer){
                    $_
                }
            }
        } elseif($PSBoundParameters['LiteralPath']) {
            Get-Item -LiteralPath $LiteralPath -Force | % {
                if($_.PSIsContainer){
                    $_
                }
            }
        }
    }
    end {
        $resolvedPaths | % -Parallel {
            $FolderIsEmpty = {
                param([string]$Folder)
                return [bool]($null -eq (Get-ChildItem $Folder))
            }
            $IsReparsePoint = {
                param([Parameter(Mandatory,Position=0)][System.IO.FileSystemInfo] $fso)
                return [bool]($fso.Attributes -band [IO.FileAttributes]::ReparsePoint)
            }
            $dirFull = $_.FullName
            $bParams = $Using:PSBoundParameters
            if ($bParams['Recurse']) {
                Get-ChildItem -LiteralPath $dirFull -Recurse -Directory -Force -EA 0 | % {
                    if((& $IsReparsePoint $_) -ne $true){
                        if (& $FolderIsEmpty $_.FullName) { $_.FullName }
                    }
                }
            }
            else {
                Get-ChildItem -LiteralPath $dirFull -Directory -Force -EA 0 | % {
                    if((& $IsReparsePoint $_) -ne $true){
                        if (& $FolderIsEmpty $_.FullName) { $_.FullName }
                    }
                }
            }
        } -ThrottleLimit 28
    }
}