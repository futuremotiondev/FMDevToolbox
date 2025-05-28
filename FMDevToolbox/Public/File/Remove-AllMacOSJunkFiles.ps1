using namespace System.Collections.Generic

function Remove-AllMacOSJunkFiles {
    <#
    .SYNOPSIS
    Removes macOS-specific junk files and folders from specified directories.

    .DESCRIPTION
    The Remove-AllMacOSJunkFiles function scans specified directories for known macOS
    junk files and folders, such as '.DS_Store' and '.Spotlight-V100', and removes
    them. It supports both wildcard paths and literal paths, with options to skip
    AppleDouble files and control the number of parallel threads used for deletion.

    .PARAMETER Path
    Specifies one or more directory paths to scan for macOS junk files. Supports wildcards.

    .PARAMETER LiteralPath
    Specifies one or more literal directory paths to scan for macOS junk files. Does not support wildcards.

    .PARAMETER SkipAppleDoubleFiles
    A switch parameter that, when set, skips the removal of AppleDouble files (e.g., '._filename').

    .PARAMETER MaxThreads
    Specifies the maximum number of threads to use for parallel file and folder removal operations. Default is 16.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to remove macOS junk files from a specific directory using a wildcard path.
    Remove-AllMacOSJunkFiles -Path "C:\Users\*\Documents"

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to remove macOS junk files from a specific directory using a literal path.
    Remove-AllMacOSJunkFiles -LiteralPath "C:\Users\JohnDoe\Documents"

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to remove macOS junk files while skipping AppleDouble files.
    Remove-AllMacOSJunkFiles -Path "C:\Projects" -SkipAppleDoubleFiles

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to remove macOS junk files using a custom thread limit.
    Remove-AllMacOSJunkFiles -Path "D:\Backup" -MaxThreads 8

    .EXAMPLE
    # **Example 5**
    # This example demonstrates how to use pipeline input to remove macOS junk files from multiple directories.
    "C:\Data", "D:\Archive" | Remove-AllMacOSJunkFiles

    .EXAMPLE
    # **Example 6**
    # This example demonstrates how to remove macOS junk files from a directory structure without using wildcards.
    Remove-AllMacOSJunkFiles -LiteralPath "E:\Media\Photos"

    .OUTPUTS
    None. This function does not produce any output objects.

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
            ParameterSetName = "LiteralPath",
            HelpMessage="Literal path to one or more directories."
        )]
        [ValidateScript({
            if ($_ -match '[\?\*]') { throw "Wildcard chars are not acceptable." }
            $true
        })]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,

        # Optional switch to skip AppleDouble files.
        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $SkipAppleDoubleFiles,

        # Set maximum number of threads for parallel deletion operations.
        [Parameter(ValueFromPipelineByPropertyName)]
        [Int32] $MaxThreads = 16,

        # Show what will be deleted instead of actually deleting.
        # Basically, a custom -whatif.
        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $DryRun
    )

    begin {

        # Dictionary of known macOS junk folders to be removed.
        $junkDirs = @{
            SPOTLIGHT = '.Spotlight-V100'
            FSEVENTS  = '.fseventsd'
            TRASHES   = '.Trashes'
            REVISIONS = '.DocumentRevisions-V100'
            MBACKUPS  = '.MobileBackups'
            MACOSX    = '__MACOSX'
        }

        # Initialize a HashSet to store unique directory paths.
        $dirSet = [HashSet[string]]::new()
    }

    process {
        # Resolve paths based on parameter set and add them to the directory set if they are containers.
        $resolvedPaths = $LiteralPath | % {
            $PSCmdlet.GetUnresolvedProviderPathFromPSPath($_)
        }
        foreach ($item in $resolvedPaths) {
            $itemObj = Get-Item -LiteralPath $item -Force
            if ($itemObj.PSIsContainer) {
                $null = $dirSet.Add($itemObj.FullName)
            }
        }
    }

    end {

        # Initialize HashSets to store paths of folders and files to be removed.
        $foldersToRemove = [HashSet[string]]::new()
        $filesToRemove = [HashSet[string]]::new()

        # Identify junk folders within each directory and add them to the removal list.
        foreach ($dir in $dirSet) {
            gci -LP $dir -Recurse -Directory -Force | ? { $junkDirs.Values -contains $_.Name } |
            % { $null = $foldersToRemove.Add($_.FullName) }
        }

        if($DryRun){

            if($foldersToRemove.Count -gt 0){
                Write-SpectreHost "[#FFFFFF]Directories to be deleted:[/]"
                foreach ($fld in $foldersToRemove) {
                    Write-SpectreHost "[#878D94]└─ $fld[/]"
                }
            }
            else {
                Write-SpectreHost "[#FFFFFF]No directories to be deleted.[/]"
            }


        }
        else {
            # Remove identified junk folders using parallel processing.
            $foldersToRemove | % -Parallel {
                Remove-Item -LiteralPath $_ -Force -Recurse -Confirm:$false -ErrorAction Continue
            } -ThrottleLimit $MaxThreads
        }

        [string[]] $dirSetNew = @()
        if(-not $DryRun){
            # Filter existing directories after folder removal to ensure they still exist.
            foreach ($dir in $dirSet) {
                if($dir){
                    $dirSetNew += $dir
                }
            }
        }
        else {
            foreach ($dir in $dirSet) {
                $dirSetNew += $dir
            }
        }

        # Identify junk files within each existing directory and add them to the removal list.
        foreach ($dir in $dirSetNew) {
            $dChild = Get-ChildItem -LiteralPath $dir -Recurse -File -Force
            $dsFile = @('DS_Store','.DS_Store')
            $adRegex = [regex]'^\._.+'
            $filteredFiles = if ($SkipAppleDoubleFiles) {
                $dChild | Where-Object { $_.Name -in $dsFile }
            } else {
                $dChild | Where-Object { ($_.Name -in $dsFile) -or ($adRegex.IsMatch($_.Name)) }
            }
            $filteredFiles | % { $null = $filesToRemove.Add($_.FullName) }
        }

        if(-not $DryRun){
            $filesToRemove | % -Parallel {
                Write-Verbose "Removing file $_"
                Remove-Item -LiteralPath $_ -Force -ErrorAction Continue
            } -ThrottleLimit $MaxThreads
        }
        else {
            Write-SpectreHost "`n[#FFFFFF]Files to be deleted:[/]"
            foreach ($fle in $filesToRemove) {
                Write-SpectreHost "[#878D94]└─ $fle[/]"
            }
        }

    }
}