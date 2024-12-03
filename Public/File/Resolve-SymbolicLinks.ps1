function Resolve-SymbolicLinks {
    [CmdletBinding()]
    param(
        [parameter(Mandatory,Position=0,ValueFromPipeline)]
        [Array[]] $SymlinkList,
        [Switch] $PrefixContainingFolderName
    )
    process {
        foreach ($Symlink in $SymlinkList) {
            try {
                $ResolvedTarget = $Symlink.ResolveLinkTarget($true)
            } catch {
                Write-Warning "The symbolic link target for $Symlink is missing. Removing the symlink."
                Remove-Item -LiteralPath $Symlink.FullName -Force -Recurse
                Remove-EmptyDirectories -Directories ([System.IO.Directory]::GetParent($Symlink.FullName).FullName)
                continue
            }
            if (Test-Path -LiteralPath $ResolvedTarget.FullName) {
                $LinkPath = $Symlink.FullName
                Remove-Item -LiteralPath $LinkPath -Force
                $ReplacedFile = Copy-Item -LiteralPath $ResolvedTarget.FullName -Destination $LinkPath -Force -PassThru
                if (Test-Path -LiteralPath $ReplacedFile.FullName -PathType Container) {
                    Remove-EmptyDirectories -Directories $ReplacedFile.FullName
                }
            } else {
                Write-Warning "The symlink target `"$ResolvedTarget`" doesn't exist. Removing the symlink."
                Remove-Item -LiteralPath $Symlink.FullName -Force -Recurse
                Remove-EmptyDirectories -Directories ([System.IO.Directory]::GetParent($Symlink.FullName).FullName)
            }
        }
    }
}