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
    [CmdletBinding(DefaultParameterSetName="Path")]
    param (
        # Define parameters for the function, allowing input via pipeline or direct specification.
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "Path",
            HelpMessage="Path to one or more directories."
        )]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [String[]] $Path,

        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "LiteralPath",
            HelpMessage="Literal path to one or more directories."
        )]
        [ValidateScript({
            if ($_ -match '[\?\*]') { throw "Wildcard chars are not acceptable." }
            if (-not [Path]::IsPathRooted($_)) { throw "Relative paths are not allowed." }
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
        $resolvedPaths = if($PSBoundParameters['Path']) {
            $Path | Get-Item -Force
        } else {
            $LiteralPath | Get-Item -Force
        }
        foreach ($item in $resolvedPaths) {
            if ($item.PSIsContainer) {
                $null = $dirSet.Add($item.FullName)
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
            Write-SpectreHost "[#FFFFFF]Directories to be deleted:[/]"
            foreach ($fld in $foldersToRemove) {
                Write-SpectreHost "[#DEE7F0]└── $fld[/]"
            }
        }
        else {
            # Remove identified junk folders using parallel processing.
            $foldersToRemove | % -Parallel {
                Remove-Item -LiteralPath $_ -Force -Recurse -Confirm:$false -ErrorAction Continue
            } -ThrottleLimit $MaxThreads
        }

        if(-not $DryRun){
            # Filter existing directories after folder removal to ensure they still exist.
            $dirSetNew = @($dirSet | Where-Object {
                Test-Path -LiteralPath $_ -PathType Container
            })
        }
        else {
            $dirSetNew = $dirSet
        }

        # Identify junk files within each existing directory and add them to the removal list.
        foreach ($dir in $dirSetNew) {
            $dChild = Get-ChildItem -LiteralPath $dir -Recurse -File -Force
            $dsFile = '.DS_Store'
            $adRegex = [regex]'^\._.+'
            $filteredFiles = if ($SkipAppleDoubleFiles) {
                $dChild | Where-Object { $_.Name -eq $dsFile }
            } else {
                $dChild | Where-Object { $_.Name -eq $dsFile -or $adRegex.IsMatch($_.Name) }
            }
            $filteredFiles | % { $null = $filesToRemove.Add($_.FullName) }
        }

        if(-not $DryRun){
            # Remove identified junk files using parallel processing.
            $filesToRemove | % -Parallel {
                Remove-Item -LiteralPath $_ -Force -Confirm:$false -ErrorAction Continue
            } -ThrottleLimit $MaxThreads
        }
        else {
            Write-SpectreHost "`n[#FFFFFF]Files to be deleted:[/]"
            foreach ($fle in $filesToRemove) {
                Write-SpectreHost "[#DEE7F0]└── $fle[/]"
            }
        }

    }
}