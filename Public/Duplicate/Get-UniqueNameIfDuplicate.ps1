﻿function Get-UniqueNameIfDuplicate {
    <#
    .SYNOPSIS
    Generates a unique file or directory name if a duplicate exists at the specified path.

    .DESCRIPTION
    The Get-UniqueNameIfDuplicate function checks for existing files or directories at the
    specified path and generates a unique name by appending an index to the base name.
    It supports both wildcard paths and literal paths, allowing for flexible input options.

    .PARAMETER Path
    Specifies one or more paths that may include wildcards. The function resolves these paths and
    processes each resolved path to ensure uniqueness.

    .PARAMETER LiteralPath
    Specifies one or more literal paths without wildcards. This parameter requires absolute paths
    and does not allow relative paths or wildcard characters.

    .PARAMETER IndexStart
    Specifies the starting index number to be appended to the base name in case of duplicates.
    Default is 2.

    .PARAMETER PadIndexTo
    Specifies the number of digits to pad the index with leading zeros. Default is 2.

    .PARAMETER IndexSeparator
    Specifies the separator string between the base name and the index. Default is a space (" ").

    .OUTPUTS
    Outputs the unique path names generated for each input path.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to generate a unique name for a file using a wildcard path.

    Get-UniqueNameIfDuplicate -Path "C:\MyFolder\*.txt"
    PS> C:\MyFolder\Saved Document 02.txt
    C:\MyFolder\School Report 03.txt
    C:\MyFolder\BusinessEarnings.txt (Was not modified because this file didn't exist.)

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to generate a unique name for a file using a literal path.

    Get-UniqueNameIfDuplicate -LiteralPath "C:\MyFolder\Report.docx"
    PS> C:\MyFolder\Report 02.docx

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to handle multiple paths with different extensions.

    Get-UniqueNameIfDuplicate -Path "C:\MyFolder\*.*" -IndexStart 1 -PadIndexTo 3 -IndexSeparator "_"
    PS> C:\MyFolder\Saved Document_001.docx
    C:\MyFolder\FavoriteWallpaper_002.jpg
    C:\MyFolder\Company Logo_004.png
    C:\MyFolder\FileThatDidNotExistAlready.png

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 12-02-2024
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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

        [Int] $IndexStart = 2,
        [Int] $PadIndexTo = 2,
        [String] $IndexSeparator = " "
    )

    process {
        $Resolved = @()
        if ($PSCmdlet.ParameterSetName -eq "Path") {
            foreach ($p in $Path) {
                $Resolved += Resolve-Path -Path $p -ErrorAction SilentlyContinue | ForEach-Object { $_.ProviderPath }
            }
        } elseif ($PSCmdlet.ParameterSetName -eq "LiteralPath") {
            $Resolved = $LiteralPath
        }

        foreach ($File in $Resolved) {
            $FileName = Split-Path -Path $File -Leaf
            $ParentDir = Split-Path -Path $File -Parent

            if (Test-Path -Path $File) {
                $BaseName, $Extension = if ($FileName.StartsWith(".") -or !(Test-Path -Path $File -PathType Leaf)) {
                    # Dotfile or Directory
                    $FileName, ""
                } else {
                    $lastDotIndex = $FileName.LastIndexOf(".")
                    if ($lastDotIndex -ne -1) {
                        # File with extension
                        $FileName.Substring(0, $lastDotIndex), $FileName.Substring($lastDotIndex)
                    } else {
                        # File without extension
                        $FileName, ""
                    }
                }
            } else {
                $BaseName, $Extension = $FileName, ""
            }

            $NewName = $FileName
            $IDX = $IndexStart

            while (Test-Path -Path (Join-Path -Path $ParentDir -ChildPath $NewName)) {
                $PaddedIDX = $IDX.ToString().PadLeft($PadIndexTo, '0')
                $NewName = if ($Extension) {
                    "{0}{1}{2}{3}" -f $BaseName, $IndexSeparator, $PaddedIDX, $Extension
                } else {
                    "{0}{1}{2}" -f $BaseName, $IndexSeparator, $PaddedIDX
                }
                $IDX++
            }

            Join-Path $ParentDir -ChildPath $NewName
        }
    }
}