function Rename-Fonts {
    <#
    .SYNOPSIS
    Renames font files using specified naming conventions with FoundryTools-CLI's command line tool. (ftcli.exe)

    .DESCRIPTION
    Renames font files using specified naming conventions with FoundryTools-CLI's command line tool. (ftcli.exe)
    The function utilizes ftcli.exe to rename font files located at specified paths or literal paths.
    It supports various renaming methods and can overwrite existing files if necessary.
    The function also allows recursive processing of directories.

    **DEPENDENCY NOTE:**

    This function depends on an active installation of Python and the package `foundrytools-cli` installed in a defined directory.
    The repository of this tool can be found here: https://github.com/ftCLI/FoundryTools-CLI
    The PyPi link to this tool can be found here: https://pypi.org/project/foundrytools-cli/

    By default, this venv (Virtual Environment) must exist in a specific directory: `$env:FM_PY_VENV\FontTools`
    If you would like to specify a different location, it must be passed into this function via the `-CustomVirtualEnvironment` parameter.

    You can create this VENV with the following commands:

    ```
    cd $env:FM_PY_VENV
    py -3.12 -m venv FontTools
    .\FontTools\Scripts\Activate.ps1
    python -m pip install foundrytools-cli
    ```

    .PARAMETER Path
    Specifies one or more locations where font files are located, supporting wildcards.

    .PARAMETER LiteralPath
    Specifies a literal path to one or more locations where font files are located. Wildcards are not supported.

    .PARAMETER Method
    Defines the renaming method to be used. Options include 'FamilyNameStyleName', 'PostScriptName', 'FullFontName', or numeric values '1', '2', '3'.

    .PARAMETER Overwrite
    Indicates that existing files should be overwritten if they have the same name as the renamed file.

    .PARAMETER Recurse
    Indicates that the operation should include all subdirectories recursively.

    .PARAMETER CustomVirtualEnvironment
    Specifies a custom path for the function to look for the FoundryTools-CLI virtual environment that will be used for all renaming operations.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to rename fonts in a directory using the default method.
    Rename-Fonts -Path "C:\Fonts"

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to rename fonts in a directory with a specific method and overwrite existing files.
    Rename-Fonts -Path "C:\Fonts" -Method "PostScriptName" -Overwrite

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to rename fonts using a literal path without recursion.
    Rename-Fonts -LiteralPath "C:\Fonts\MyFont.ttf"

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to rename fonts in a directory using a numeric method identifier.
    Rename-Fonts -Path "C:\Fonts" -Method "2"

    .OUTPUTS
    None. The function performs actions on the file system and does not produce output objects.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 01-03-2025
    #>
    [CmdletBinding(SupportsShouldProcess=$true, DefaultParameterSetName='Path')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    param (
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

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('FamilyNameStyleName','PostScriptName','FullFontName','1','2','3')]
        [String] $Method,
        [Switch] $Overwrite,
        [Switch] $Recurse,
        [String] $CustomVirtualEnvironment = "$env:FM_PY_VENV\FontTools"
    )

    begin {
        $sourceDict = @{
            FamilyNameStyleName = '1'
            PostScriptName      = '2'
            FullFontName        = '3'
        }
        if(-not(Test-Path -LiteralPath $CustomVirtualEnvironment)){
            Write-Error "The provided virtual environment does not exist."
            return
        }
        $activationScript = "$CustomVirtualEnvironment\Scripts\Activate.ps1"
        if(-not(Test-Path -LiteralPath $activationScript)){
            Write-Error "Activation script doesn't exist in the provided VENV. ($activationScript)."
            return
        }
        $ftcliCmd = Get-Command "$CustomVirtualEnvironment\Scripts\ftcli.exe" -CommandType Application -ErrorAction SilentlyContinue
        if(-not($ftCliCmd)){
            Write-Error "Can't find ftcli.exe in the virtual environment. Make sure FoundryTools-CLI is installed."
            return
        }
        $validFontArray = @('.ttf','.otf','.ttc','.woff','.woff2')
        $fileList = [System.Collections.Generic.List[String]]@()
        $dirList = [System.Collections.Generic.List[String]]@()
        if(!$Method){
            $OokiiSplat = @{
                MainInstruction = "Please specify the how to extract the file names"
                MainContent     = "[1] FamilyName-StyleName [2] PostScript Name [3] Full Font Name"
                WindowTitle     = "ftCLI Font Renamer"
                InputText       = '1'
                MaxLength       = 1
            }
            do {
                $ReturnObject = Invoke-OokiiInputDialog @OokiiSplat
                if($ReturnObject.Result -eq 'Cancel'){ exit 2 }
                $Method = $ReturnObject.Input
            } while ( @('1', '2', '3') -notcontains $Method )
        }
        & $activationScript
    }

    process {
        $resolvedPaths = if($PSBoundParameters['Path']) {
            $Path | Get-Item -Force
        } elseif($PSBoundParameters['LiteralPath']) {
            $LiteralPath | Get-Item -Force
        }
        $resolvedPaths | % {
            if (Test-Path -LiteralPath $_.FullName -PathType Container) {
                $null = $dirList.Add($_.FullName)
            } elseif(Test-Path -LiteralPath $_.FullName -PathType Leaf) {
                if($validFontArray -contains $_.Extension){
                    $null = $fileList.Add($_.FullName)
                }
            }
        }
    }

    end {
        $methodNum = if ($Method -in @(1, 2, 3)) {
            "$Method"
        } else {
            $sourceDict[$Method]
        }
        $ftcliParams = "utils", "font-renamer", "-s", $methodNum
        if($Recurse)  { $ftcliParams += "-r" }
        if($Overwrite){ $ftcliParams += "-o" }
        foreach ($file in $fileList) {
            if ($PSCmdlet.ShouldProcess($file, "Rename file")) {
                & $ftcliCmd $ftcliParams $file | Out-Null
            }
        }
        foreach ($directory in $dirList) {
            if ($PSCmdlet.ShouldProcess($directory, "Rename all files in directory")) {
                & $ftcliCmd $ftcliParams $directory | Out-Null
            }
        }
        & deactivate
    }
}

