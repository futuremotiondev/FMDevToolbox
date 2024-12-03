<#
.SYNOPSIS
    Moves variable fonts to a specified directory.

.DESCRIPTION
    The Move-VariableFont function moves variable fonts to a specified directory.
    The function supports both wildcard and literal paths.

.PARAMETER Path
    Specifies the paths to process. This parameter accepts pipeline input and can be a string, or an object with a Path, FullName, or PSPath property.

.PARAMETER LiteralPath
    Specifies the literal paths to process. This parameter accepts pipeline input and can be a string, or an object with a PSPath property. Wildcard characters are not acceptable with this parameter.

.PARAMETER Destination
    Specifies the destination directory to move the variable fonts to. This parameter is mandatory.

.EXAMPLE
    Move-VariableFont -Path "C:\Fonts\*.ttf" -Destination "C:\VariableFonts"

    This example moves all variable TrueType font files in the "C:\Fonts" directory to the "C:\VariableFonts" directory.

.EXAMPLE
    Move-VariableFont -LiteralPath "C:\Fonts\MyFont.ttf" -Destination "C:\VariableFonts"

    This example moves the "MyFont.ttf" file in the "C:\Fonts" directory to the "C:\VariableFonts" directory if it is a variable font.

.EXAMPLE
    Get-ChildItem -Path "C:\Fonts" -Filter "*.ttf" | Move-VariableFont -Destination "C:\VariableFonts"

    This example moves all variable TrueType font files in the "C:\Fonts" directory to the "C:\VariableFonts" directory, using pipeline input.

.EXAMPLE
    Move-VariableFont -Path "C:\Fonts\MyFolder\*.ttf" -Destination "C:\VariableFonts"

    This example moves all variable TrueType font files in the "MyFolder" subdirectory of the "C:\Fonts" directory to the "C:\VariableFonts" directory.

.AUTHOR
    Futuremotion
    https://www.github.com/fmotion1
#>
function Move-VariableFont {
    [cmdletbinding(DefaultParameterSetName = 'Path')]
    param(
        [parameter(
            Mandatory,
            ParameterSetName  = 'Path',
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]] $Path,

        [parameter(
            Mandatory,
            ParameterSetName = 'LiteralPath',
            Position = 0,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript({
            if ($_ -notmatch '[\?\*]') {
                $true
            } else {
                throw 'Wildcard characters *, ? are not acceptable with -LiteralPath'
            }
        })]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')]
        [string[]] $LiteralPath,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String] $Destination
    )

    begin {

        if(-not($Destination | Test-Path -PathType Container)){
            New-Item -Path $Destination -ItemType Directory -Force
        }

        $ResolvedPathList = [System.Collections.Generic.List[String]]@()
    }

    process {
        # Resolve paths if necessary.
        $Paths = if($PSCmdlet.ParameterSetName -eq 'Path') { $Path } else { $LiteralPath }
        $Paths | ForEach-Object {
            $ResolvedPaths = Resolve-Path -Path $_
            foreach ($ResolvedPath in $ResolvedPaths) {
                if ((Test-Path -Path $ResolvedPath.Path) -and ($ResolvedPath.Path -match "\.(ttf)$")) {
                    $ResolvedPathList.Add($ResolvedPath.Path)
                } else {
                    Write-Warning "$ResolvedPath does not exist on disk."
                }
            }
        }

        $ResolvedPathList | ForEach-Object {

            $Font = $_
            $FontIsVariable = Test-IsFontVariable -LiteralPath $Font

            if($FontIsVariable){
                Move-Item $Font -Destination $Destination
            }
        }
    }
}