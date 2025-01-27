<#
.SYNOPSIS
    Converts JSXBIN files to JSX format.

.DESCRIPTION
    The ConvertFrom-JSXBINToJSX function processes JSXBIN files and converts them into JSX format.
    It supports outputting the converted file to a specified folder, subdirectory, or the same
    directory as the source file. Optionally, it can format the output using Prettier.

.PARAMETER LiteralPath
    Specifies the path to the input JS or JSX file. This parameter is mandatory.

.PARAMETER OutputFolder
    Specifies the folder where the converted JSX file will be saved.
    This parameter is mandatory when using the "OutputFolder" parameter set.

.PARAMETER Subdirectory
    Specifies the subdirectory within the source file's directory where the converted JSX file will be saved. T
    his parameter is mandatory when using the "Subdirectory" parameter set.

.PARAMETER SameFolder
    Indicates that the converted JSX file should be saved in the same folder as the source file.
    This parameter is mandatory when using the "SameFolder" parameter set.

.PARAMETER FormatWithPrettier
    If specified, formats the output JSX file using Prettier.

.PARAMETER PrettierConfigFile
    Specifies the path to the Prettier configuration file. Defaults to a script-level variable if not provided.

.OUTPUTS
    None. The function outputs the converted JSX file to the specified location.

.EXAMPLE
    ConvertFrom-JSXBINToJSX -LiteralPath "C:\Scripts\example1.jsxbin" -OutputFolder "C:\ConvertedFiles" -FormatWithPrettier

    This example converts the file `example1.jsxbin` located in `C:\Scripts` to JSX format and saves it in `C:\ConvertedFiles`. The output is formatted with Prettier.

.EXAMPLE
    ConvertFrom-JSXBINToJSX -LiteralPath "D:\Projects\example2.jsxbin" -Subdirectory "Converted" -PrettierConfigFile "D:\Configs\.prettierrc"

    This example converts the file `example2.jsxbin` located in `D:\Projects` to JSX format and saves it in a subdirectory named `Converted`. It uses a custom Prettier configuration file.

.EXAMPLE
    ConvertFrom-JSXBINToJSX -LiteralPath "E:\Work\example3.jsxbin" -SameFolder

    This example converts the file `example3.jsxbin` located in `E:\Work` to JSX format and saves it in the same directory without formatting it with Prettier.

.NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 11-12-2024
#>
function ConvertFrom-JSXBINToJSX {
    [CmdletBinding(DefaultParameterSetName = "Subdirectory")]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = "OutputFolder")]
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = "Subdirectory")]
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = "SameFolder")]
        [Alias("Path", "PSPath")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                if (-not(Test-Path -LiteralPath $_ -PathType Leaf)) {
                    throw "Passed JS or JSX file does not exist. ($_)"
                } else {
                    if ($_ -notmatch "(\.js|\.jsxbin)") {
                        throw "Passed file is not a .js or .jsxbin file ($_)."
                    } else { $true }
                }
            })]
        [String[]] $LiteralPath,

        [Parameter(Mandatory, ParameterSetName = "OutputFolder")]
        [String] $OutputFolder,

        [Parameter(Mandatory, ParameterSetName = "Subdirectory")]
        [String] $Subdirectory,

        [Parameter(Mandatory, ParameterSetName = "SameFolder")]
        [Switch] $SameFolder,

        [Parameter(Mandatory = $false, ParameterSetName = "OutputFolder")]
        [Parameter(Mandatory = $false, ParameterSetName = "Subdirectory")]
        [Parameter(Mandatory = $false, ParameterSetName = "SameFolder")]
        [Switch] $FormatWithPrettier,

        [Parameter(Mandatory = $false, ParameterSetName = "OutputFolder")]
        [Parameter(Mandatory = $false, ParameterSetName = "Subdirectory")]
        [Parameter(Mandatory = $false, ParameterSetName = "SameFolder")]
        [ValidateScript({
                if (-not(Test-Path -LiteralPath $_ -PathType Leaf)) {
                    throw "Passed config file does not exist. ($_)"
                }
            })]
        [String] $PrettierConfigFile = $script:PrettierConfig
    )

    begin {
        if ($FormatWithPrettier) {
            $PrettierCMD = Get-CommandPrettierNext -ErrorAction Stop
        }
        $ScriptList = [System.Collections.Generic.List[String]]@()
    }

    process {
        foreach ($S in $LiteralPath) {
            $null = $ScriptList.Add($S)
        }
    }

    end {

        $ScriptList | ForEach-Object {

            $Script = $_
            $Params = @()
            $FilenameBase = [System.IO.Path]::GetFileNameWithoutExtension($Script)
            $NewFilename = "$FilenameBase.jsx"

            switch ($PSCmdlet.ParameterSetName) {
                'Subdirectory' {
                    $ScriptFolder = [System.IO.Directory]::GetParent($Script).FullName
                    $OutputDir = [System.IO.Path]::Combine($ScriptFolder, $Subdirectory)
                    if (-not(Test-Path -LiteralPath $OutputDir -PathType Container)) {
                        [System.IO.Directory]::CreateDirectory($OutputDir) | Out-Null
                    }
                    $OutputDir = $OutputDir.TrimEnd("\") + '\'
                    $OutputFile = [System.IO.Path]::Combine($OutputDir, $NewFilename)
                    $Params += '-o', $OutputFile, $Script
                }
                'OutputFolder' {
                    if (-not(Test-Path -LiteralPath $OutputFolder -PathType Container)) {
                        [System.IO.Directory]::CreateDirectory($OutputFolder) | Out-Null
                    }
                    $OutputDir = $OutputFolder.TrimEnd("\") + '\'
                    $OutputFile = [System.IO.Path]::Combine($OutputDir, $NewFilename)
                    $Params += '-o', $OutputFile, $Script
                }
                'SameFolder' {
                    $OutputDir = [System.IO.Directory]::GetParent($Script).FullName
                    $OutputDir = $OutputDir.TrimEnd("\") + '\'
                    $OutputFile = [System.IO.Path]::Combine($OutputDir, $NewFilename)
                    $Params += '-o', $OutputFile, $Script
                }
            }

            Get-Content -LiteralPath $Script | ForEach-Object {
                if ($_ -match '@JSXBIN@') {
                    & jsxer.exe $Params
                    return
                }
            }
            if ($FormatWithPrettier) {
                if (Test-Path -LiteralPath $OutputFile -PathType Leaf) {
                    $PrettierParams = $OutputFile, '-w', '--no-cache', '--config-path', $PrettierConfigFile
                    & $PrettierCMD $PrettierParams
                } else {
                    Write-Error "$OutputFile isn't present. No Prettier formatting has occurred." -ErrorAction Continue
                }
            }
        }
    }
}
