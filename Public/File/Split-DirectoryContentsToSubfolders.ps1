function Split-DirectoryContentsToSubfolders {

    [CmdletBinding(DefaultParameterSetName="Prefix")]

    param (
        [parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [Object[]] $Directories,

        [Switch] $ProcessFolders,
        [Int32] $NumEntriesPerFolder = 1000,
        [Int32] $FolderNumberPadding = 2,

        [parameter( ValueFromPipelineByPropertyName, ParameterSetName='Prefix' )]
        [ValidateSet('None','FolderName', IgnoreCase = $true)]
        [String] $PathPrefix = 'None'
    )

    begin {
        $List = [System.Collections.Generic.List[String]]@()
    }

    process {
        foreach ($P in $Directories) {
            $Path = if ($P -is [String])  { $P }
                    elseif ($P.Path)	  { $P.Path }
                    elseif ($P.FullName)  { $P.FullName }
                    elseif ($P.PSPath)	  { $P.PSPath }
                    else { Write-Error "$P is an unsupported type."; throw }

            # Resolve paths
            $ResolvedPaths = Resolve-Path -Path $Path
            foreach ($ResolvedPath in $ResolvedPaths) {
                if (Test-Path -Path $ResolvedPath.Path -PathType Container) {
                    $List.Add($ResolvedPath.Path)
                } else {
                    Write-Warning "$ResolvedPath does not exist on disk."
                }
            }
        }
    }

    end {

        foreach ($Dir in $List) {

            Set-Location -LiteralPath $Dir
            $DirObject = Get-Item -LiteralPath $Dir

            $CreateNewFolder = {
                $Prefix = if($PathPrefix -eq 'none') { '' }
                          else { $DirObject.BaseName }

                $NewChunk = $Index + 1
                $IndexFormatted = $NewChunk.ToString().PadLeft($FolderNumberPadding, '0')
                $FormatDirName = if(-not($ProcessFolders)) { "$Prefix $IndexFormatted".Trim() }
                          else { (Get-RandomAlphanumericString -Length 10) + "-$Prefix $IndexFormatted".Trim() }

                $OutputDirectory = [IO.Path]::Combine($DirObject.FullName, "$FormatDirName")
                [IO.Directory]::CreateDirectory($OutputDirectory).FullName
            }

            $Enumeration = if($ProcessFolders) { $DirObject.EnumerateDirectories() }
                           else { $DirObject.EnumerateFiles() }

            foreach ($Object in $Enumeration) {
                if($i++ % $NumEntriesPerFolder -eq 0) {
                    $NewFolder = (& $CreateNewFolder)
                    $Index++
                }
                $Dest = "$NewFolder\$($Object.Name)"
                [System.IO.Directory]::Move($Object.FullName, $Dest) | Out-Null
            }

            if($ProcessFolders) {
                Get-ChildItem -LiteralPath $DirObject -Directory | % {
                    $folderName = Split-Path -Path $_ -Leaf
                    $newFolderName = ($folderName -replace '^[^-]*-', '').TrimStart()
                    $parentPath = Split-Path -Path $_ -Parent
                    $newFolderPath = Join-Path -Path $parentPath -ChildPath $newFolderName
                    Rename-Item -Path $_ -NewName $newFolderPath -Force | Out-Null
                }
            }
        }
    }
}

