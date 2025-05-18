using namespace System.Collections.Generic
using namespace System.IO

function Copy-WindowsPathsToClipboard {
    <#
    .SYNOPSIS
    Copies specified file and directory paths to the clipboard with various
    formatting options.

    .DESCRIPTION
    The Copy-WindowsPathsToClipboard function allows users to copy paths of files and directories to the clipboard. It supports both wildcard and literal path inputs, provides options for formatting the output (such as excluding extensions, changing slash formats), and allows sorting of the paths.
    Users can also choose to output the results directly to the console or even format them as a PowerShell array.

    .PARAMETER Path
    Specifies one or more paths with wildcards. Supports pipeline input.

    .PARAMETER LiteralPath
    Specifies one or more literal paths without wildcards. Supports pipeline input.

    .PARAMETER FilenamesOnly
    If set, only filenames will be included in the output.

    .PARAMETER NoQuotes
    If set, excludes quotes from the output paths.

    .PARAMETER SlashFormat
    Specifies the format of slashes in the output paths. Valid values are 'Default', 'DoubleBackslash', 'ForwardSlash', and 'DoubleForwardSlash'.

    .PARAMETER NoExtension
    If set, removes file extensions from filenames.

    .PARAMETER SortOrder
    Determines the order of sorting: 'FoldersFirst' or 'FilesFirst'.

    .PARAMETER AsPowershellArray
    If set, outputs the paths as a PowerShell array.

    .PARAMETER ArrayName
    Specifies the name of the PowerShell array if AsPowershellArray is specified.

    .PARAMETER OnlyFiles
    If set, omits the inclusion of folders in the results.

    .PARAMETER OnlyFolders
    If set, omits the inclusion of files in the results.

    .PARAMETER OutputResults
    If set, outputs the final sorted list of paths to the console as well as just copying them to the clipboard.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to copy paths using wildcards to the clipboard.
    Copy-WindowsPathsToClipboard -Path "C:\Users\*\Documents\*.txt"

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to use literal paths and exclude quotes from the output.

    Copy-WindowsPathsToClipboard -LiteralPath "C:\Program Files" -NoQuotes

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to copy only filenames without extensions to the clipboard.

    Copy-WindowsPathsToClipboard -Path "C:\Temp\*" -FilenamesOnly -NoExtension

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to sort files first and change slash format to forward slashes.

    Copy-WindowsPathsToClipboard -Path "C:\Projects\*" -SortOrder "FilesFirst" -SlashFormat "ForwardSlash"

    .EXAMPLE
    # **Example 5**
    # This example demonstrates how to output paths as a PowerShell array named MyArray.
    Copy-WindowsPathsToClipboard -Path "C:\Data\*" -AsPowershellArray -ArrayName "MyArray"

    .EXAMPLE
    # **Example 6**
    # This example demonstrates how to use pipeline input to copy paths to the clipboard.
    "C:\Logs", "C:\Reports" | Copy-WindowsPathsToClipboard -OutputResults

    .OUTPUTS
    Outputs the final sorted list of paths if OutputResults is specified.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 05-13-2025
    #>

    [CmdletBinding(DefaultParameterSetName="Path")]
    param(
        # Define a parameter for accepting paths with wildcards, allowing pipeline input.
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

        # Define a parameter for literal paths without wildcards, allowing pipeline input.
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "LiteralPath",
            HelpMessage="Literal path to one or more locations."
        )]
        # Validate that the path does not contain wildcard characters.
        [ValidateScript({$_ -notmatch '[\?\*]'},
            ErrorMessage = "Wildcard characters *, ? are not acceptable with -LiteralPath")]
        # Ensure the path is absolute.
        [ValidateScript({[System.IO.Path]::IsPathRooted($_)},
            ErrorMessage = "Relative paths are not allowed in -LiteralPath.")]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,

        # Option to only include filenames in the output.
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $FilenamesOnly,

        # Option to exclude quotes from the output paths.
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $NoQuotes,

        # Specify the format of slashes in the output paths.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('Default', 'DoubleBackslash', 'ForwardSlash', 'DoubleForwardSlash')]
        [string] $SlashFormat = 'Default',

        # Option to remove file extensions from filenames.
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $NoExtension,

        # Determine the order of sorting: folders first or files first.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('FoldersFirst','FilesFirst')]
        [string] $SortOrder = "FoldersFirst",

        # Option to output the paths as a PowerShell array.
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $AsPowershellArray,

        # Name of the PowerShell array if AsPowershellArray is specified.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $ArrayName = "NewArray",

        # Omit the inclusion of files in the results
        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $OnlyFiles,

        # Omit the inclusion of folders in the results
        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $OnlyFolders,

        # Omit the inclusion of folders in the results
        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $OutputResults
    )

    begin {
        # Initialize lists to store file and directory information.
        $pathList = [List[FileSystemInfo]]@()
        $fileListProcessed = [List[String]]@()
        $dirListProcessed = [List[String]]@()
        if($OnlyFiles -and $OnlyFolders){
            Write-Error "-SkipFiles and -SkipFolders cannot be used together as it would generate no output."
            return
        }
    }

    process {
        # Resolve paths based on the parameter set used (Path or LiteralPath).
        $resolvedPaths = if($PSBoundParameters['Path']) {
            Get-Item -Path $Path -Force
        } elseif($PSBoundParameters['LiteralPath']) {
            Get-Item -LiteralPath $LiteralPath -Force
        }

        # Add resolved paths to the path list.
        $resolvedPaths | % {
            $null = $pathList.Add($_)
        }
    }

    end {
        # Process each item in the path list.
        foreach ($item in $pathList) {
            $curPathFullname = $item.FullName
            $curPathIsDirectory = $item.PSIsContainer

            # Determine the final path format based on options like FilenamesOnly and NoExtension.
            $finalPath = if ($FilenamesOnly) {
                if ($NoExtension -and -not $curPathIsDirectory) {
                    [System.IO.Path]::GetFileNameWithoutExtension($curPathFullname)
                } else {
                    [System.IO.Path]::GetFileName($curPathFullname)
                }
            } else {
                if ($NoExtension -and -not $curPathIsDirectory) {
                    $curPathFullname.Substring(0, $curPathFullname.LastIndexOf('.'))
                } else {
                    $curPathFullname
                }
            }

            # Enclose the path in quotes unless NoQuotes is specified.
            if (-not $NoQuotes) { $finalPath = "`"$finalPath`"" }

            # Add the formatted path to the appropriate list (directories or files).
            if ($curPathIsDirectory) {
                if(-not$OnlyFolders){
                    $null = $dirListProcessed.Add($finalPath)
                }
            } else {
                if(-not$OnlyFiles){
                    $null = $fileListProcessed.Add($finalPath)
                }
            }
        }

        # Sort directories and files separately.
        $sortedPaths = $dirListProcessed | Sort-Object
        $sortedFiles = $fileListProcessed | Sort-Object
        $sortedList = @()

        # Combine sorted lists based on the specified SortOrder.
        switch ($SortOrder) {
            'FoldersFirst' {
                $sortedList += $sortedPaths
                $sortedList += $sortedFiles
            }
            'FilesFirst' {
                $sortedList += $sortedFiles
                $sortedList += $sortedPaths
            }
        }

        # Replace backslashes with the specified slash format if needed.
        if (($SlashFormat -ne 'Default') -and (-not $FilenamesOnly)) {
            $BackslashEscaped = [regex]::Escape('\')
            $replacement = switch ($SlashFormat) {
                'DoubleBackslash' { '\\' }
                'ForwardSlash' { '/' }
                'DoubleForwardSlash' { '//' }
            }
            $sortedList = $sortedList | % { $_ -replace $BackslashEscaped, $replacement }
        }

        # Convert the list to a PowerShell array if AsPowershellArray is specified.
        if ($AsPowershellArray) {
            $sortedList = Convert-PlaintextListToPowershellArray -InputList $sortedList -ArrayName $ArrayName -StripQuotes
        }

        # Copy the final sorted list of paths to the clipboard.
        $sortedList | Set-Clipboard
        if($OutputResults) {
            $sortedList
        }
    }
}