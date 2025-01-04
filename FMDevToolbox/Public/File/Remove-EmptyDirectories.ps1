function Remove-EmptyDirectories {
    <#
    .SYNOPSIS
    Removes empty directories from specified paths.

    .DESCRIPTION
    The Remove-EmptyDirectories function scans specified directories and removes those that are empty.
    It supports both wildcard paths and literal paths, with options to confirm operations, delete folders containing only empty files, and enable a blacklist for folder names.

    .PARAMETER Path
    Specifies the path(s) to one or more locations. Supports wildcards.

    .PARAMETER LiteralPath
    Specifies the literal path(s) to one or more locations. Does not support wildcards.

    .PARAMETER ConfirmOperation
    Prompts for confirmation before performing the operation.

    .PARAMETER DeleteFoldersWithEmptyFiles
    Also deletes folders that contain only empty files.

    .PARAMETER EnableBlacklist
    Enables the use of a blacklist to skip certain folder names during deletion.

    .PARAMETER FoldernameBlacklist
    Specifies folder names to be skipped if EnableBlacklist is set. Default includes system and common folders.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to remove empty directories using a wildcard path.
    Remove-EmptyDirectories -Path "C:\Temp\*" -ConfirmOperation

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to remove empty directories using a literal path.
    Remove-EmptyDirectories -LiteralPath "C:\Temp" -DeleteFoldersWithEmptyFiles

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to remove empty directories while skipping blacklisted folders.
    Remove-EmptyDirectories -Path "C:\Projects\*" -EnableBlacklist -FoldernameBlacklist @(".git", "node_modules")

    .OUTPUTS
    None. The function performs deletions and outputs messages to the console.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 11-30-2024
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName='Path')]
    param(
        [Parameter(
            Mandatory,
            Position = 0,
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
            ValueFromPipeline,
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
        [Switch] $ConfirmOperation,
        [Switch] $DeleteFoldersWithEmptyFiles,
        [Switch] $EnableBlacklist,
        [String[]] $FoldernameBlacklist = @(
            "System Volume Information", "WindowsApps",
            ".git", 'NtUninstall', '$RECYCLE.BIN', 'GAC_MSIL'
        )
    )

    process {
        $ResolvedDirectories = if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $Path | Get-Item -Force
        } else {
            $LiteralPath | Get-Item -Force
        }
        foreach ($Dir in $ResolvedDirectories) {
            $CurrentFolder = $Dir.FullName
            if (-not (Test-Path -LiteralPath $CurrentFolder -PathType Container)) {
                Write-Warning "The path '$CurrentFolder' does not exist or is not a directory."
                continue
            }
            try {
                $DirectoryIsCompletelyEmpty = $false
                $AllSubdirectoriesAreEmpty = $false
                $NothingToDelete = $true
                $EmptyFoldersEmptyFiles = [System.Collections.Generic.List[String]]@()
                $EmptyFolders = [System.Collections.Generic.List[String]]@()
                $FolderMap = [System.Collections.Generic.List[String]]@()
                $RootFiles = [System.Collections.Generic.List[String]]@()

                Get-ChildItem -LiteralPath $CurrentFolder -Directory -Recurse -Depth 30 -Force | % {
                    $Children = Get-ChildItem -LiteralPath $_.FullName -Recurse -Depth 30 -Force
                    if (-not$Children) {
                        if($EnableBlacklist){
                            $PathParts = $_.FullName -split '\\'
                            if ($PathParts | Where-Object { $FoldernameBlacklist -contains $_ }) {
                                Write-Verbose "Skipping $($_.FullName) because it contains a blacklisted folder."
                                return
                            }
                        }

                        $null = $FolderMap.Add($_.FullName)
                        $null = $EmptyFolders.Add($_.FullName)
                    }
                    else {
                        if($DeleteFoldersWithEmptyFiles -and (($Children | Where-Object {$_.Length -gt 0} | Measure-Object).Count -eq 0)){
                            if($EnableBlacklist){
                                $PathParts = $_.FullName -split '\\'
                                if ($PathParts | Where-Object { $FoldernameBlacklist -contains $_ }) {
                                    Write-Verbose "Skipping $($_.FullName) because it contains a blacklisted folder."
                                    return
                                }
                            }
                            $null = $EmptyFoldersEmptyFiles.Add($_.FullName)
                        }
                        $null = $FolderMap.Add($_.FullName)
                    }
                }
                $FolderMapClone = [System.Collections.Generic.List[String]]@($FolderMap)
                foreach ($Folder in $FolderMapClone) {
                    if($EmptyFolders -contains $Folder){
                        $null = $FolderMap.Remove($Folder)
                    }
                    if($DeleteFoldersWithEmptyFiles -and ($EmptyFoldersEmptyFiles -contains $Folder)){
                        $null = $FolderMap.Remove($Folder)
                    }
                }
                [String[]] $RootFiles = Get-ChildItem -LiteralPath $CurrentFolder -File -Force | % { $_.FullName }
                if(-not$FolderMap){
                    $AllSubdirectoriesAreEmpty = $true
                    if(-not$RootFiles){
                        $DirectoryIsCompletelyEmpty = $true
                        $null = $EmptyFolders.Add($CurrentFolder)
                    }
                }

                if($EmptyFolders -or $EmptyFoldersEmptyFiles){ $NothingToDelete = $false }

                if($ConfirmOperation) {

                    $FolderMap.Sort()
                    $EmptyFolders.Sort()
                    $EmptyFoldersEmptyFiles.Sort()
                    $RootFiles = $RootFiles | Sort-Object

                    if($NothingToDelete){
                        Write-SpectreHost "`r`n[#aeb3bb]There are no empty directories in [/][#ffffff]$CurrentFolder[/][#aeb3bb] to delete.[/]"
                        return
                    }
                    if($DirectoryIsCompletelyEmpty){
                        Write-SpectreHost "`r`n[#aeb3bb]The entire directory tree [/][#ffffff]$CurrentFolder[/][#aeb3bb] is completely empty.[/]"
                    }
                    elseif($AllSubdirectoriesAreEmpty){
                        Write-SpectreHost "`r`n[#aeb3bb]All subdirectories of [/][#ffffff]$CurrentFolder[/][#aeb3bb] are empty.[/]"
                        if(-not$DirectoryIsCompletelyEmpty){
                            if($RootFiles){
                                Write-SpectreHost "`r`n[#aeb3bb]However, the following root files in [/][#FFFFFF]$CurrentFolder[/] [#aeb3bb]exist and will not be deleted:`r`n[/]"
                                $RootFiles | % {
                                    Write-SpectreHost "`t[#bcc2ca]File: [/][#aeb2b9]$_[/]"
                                }
                            }
                        }
                    }
                    if($EmptyFolders){
                        Write-SpectreHost "`r`n[#aeb3bb]The following empty directories in[/] [#FFFFFF]$CurrentFolder[/] [#aeb3bb]will be deleted:[/]`r`n"
                        $EmptyFolders | % {
                            Write-SpectreHost "[#bcc2ca]Directory:[/] [#aeb2b9]$_[/]"
                        }
                        if($DeleteFoldersWithEmptyFiles -and $EmptyFoldersEmptyFiles){
                            $EmptyFoldersEmptyFiles | % {
                                Write-SpectreHost "[#bcc2ca]Directory:[/] [#aeb2b9]$_[/] [#8a8e93](Contains empty files)[/]"
                            }
                        }
                    }
                    Write-SpectreHost "`n"
                    $Result = Read-SpectreConfirm -Message "[#95989d]Would you like to continue?[/]" -Color "#FFFFFF" -DefaultAnswer y -ConfirmSuccess "Deleting folders now." -ConfirmFailure "User aborted."
                    if(-not$Result){
                        return
                    }
                }
                if($EmptyFoldersEmptyFiles -and $DeleteFoldersWithEmptyFiles){
                    $EmptyFolders.AddRange($EmptyFoldersEmptyFiles)
                }
                foreach ($EmptyFolder in $EmptyFolders) {
                    if ($PSCmdlet.ShouldProcess($EmptyFolder, "Remove empty directory")) {
                        Remove-Item -LiteralPath $EmptyFolder -Force -Recurse -Confirm:$false
                        Write-Verbose "Removed empty directory: $EmptyFolder"
                    }
                }
            } catch {
                Write-Error "Failed to remove directory '$($CurrentFolder)': $_"
            }
        }
    }
}