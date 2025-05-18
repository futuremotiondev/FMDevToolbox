function Resolve-SymlinkTarget {
    [CmdletBinding(DefaultParameterSetName="Path")]
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
        [String[]] $LiteralPath
    )

    begin {

    }

    process {

        function ResolveSymlink1 {
            param (
                [Parameter(Mandatory,Position=0)]
                [String] $OriginalPath
            )
            while( $originalPathTarget = (Get-Item $OriginalPath).Target ) {
                $combinedPath = "{0}\{1}" -f (Split-Path -Parent $OriginalPath), (Split-Path -Parent $originalPathTarget)
                Push-Location $combinedPath -StackName SYMB
                $OriginalPath = (Split-Path -Leaf $originalPathTarget)
            }
            $OriginalPath = (Join-Path $PWD $OriginalPath)
            Pop-Location -StackName SYMB
            return $OriginalPath
        }

        function ResolveSymlink2 {
            param (
                [Parameter(Mandatory, Position = 0)]
                [String] $OriginalPath
            )

            while ($true) {
                $item = Get-Item $OriginalPath
                if (-not $item.PSIsContainer -or -not $item.Target) { break }

                # Store path components to avoid repeated operations
                $parentPath = Split-Path -Parent $OriginalPath
                $targetParentPath = Split-Path -Parent $item.Target
                $leafName = Split-Path -Leaf $item.Target

                # Combine paths using Join-Path for clarity and efficiency
                $combinedPath = Join-Path $parentPath $targetParentPath
                $OriginalPath = Join-Path $combinedPath $leafName
            }

            return (Resolve-Path $OriginalPath).Path
        }

        [string[]] $resolvedPaths = if($PSBoundParameters['Path']) {
            $Path | Get-Item -Force | % {
                if($_.PSIsContainer){
                    $_.FullName
                }
            }
        } elseif($PSBoundParameters['LiteralPath']) {
            Get-Item -LiteralPath $LiteralPath -Force | % {
                if($_.PSIsContainer){
                    $_.FullName
                }
            }
        }

        $resolvedPaths | % {
            $isSymlink = [bool](
                (Get-Item $_ -Force -ea 0).Attributes -band [IO.FileAttributes]::ReparsePoint
            )
            if($isSymlink){
                $Result1 = ResolveSymlink1 $_
                $Result2 = ResolveSymlink2 $_
                Write-Host -f Green "`$Result1:" $Result1
                Write-Host -f Green "`$Result2:" $Result2
            }
            else{
                return $_.FullName
            }
        }
    }
}

# "D:\Dev\00 Sample Code\XML\msm-sample-webapp\runtime\tomcat1\bin"
# "D:\Dev\00 Sample Code\XML\msm-sample-webapp\runtime\tomcat\bin"

# $tmp = (Get-Item "D:\Dev\00 Sample Code\XML\msm-sample-webapp\runtime\tomcat1\bin").Target
# (Split-Path -Leaf $tmp)
# (Get-Item "D:\Dev\00 Sample Code\XML\").LinkType

# Resolve-SymlinkTarget -LiteralPath "D:\Dev\00 Sample Code\XML\msm-sample-webapp\runtime\tomcat1\bin"