function Format-String {
    <#
    .SYNOPSIS
    Formats a string according to the specified case style.

    .DESCRIPTION
    The `Format-String` function takes an input string and formats it according to a specified case style.
    Supported styles include CamelCase, KebabCase, LowerCase, PascalCase, SentenceCase, SnakeCase, TitleCase, TrainCase, and UpperCase.
    An optional delimiter can be provided for splitting the input string into words.

    .PARAMETER String
    The input string to be formatted.

    .PARAMETER Format
    Specifies the format style to apply to the input string.
    Valid options are: CamelCase, KebabCase, LowerCase, PascalCase, SentenceCase, SnakeCase, TitleCase, TrainCase, UpperCase.

    .PARAMETER Delimiter
    The delimiter used to split the input string into words. Defaults to a space (" ").

    .OUTPUTS
    System.String

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to convert a string to TitleCase.
    Format-String -String "hello world" -Format "TitleCase"

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to convert a string to SnakeCase.
    Format-String -String "hello world" -Format "SnakeCase"

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to convert a string to UpperCase.
    Format-String -String "hello world" -Format "UpperCase"

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to convert a string to CamelCase.
    Format-String -String "hello world" -Format "CamelCase"

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 11-14-2024
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String] $String,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateSet ("CamelCase", "KebabCase", "LowerCase", "PaslcalCase", "SentenceCase", "SnakeCase", "TitleCase", "TrainCase", "UpperCase")]
        [String] $Format,
        [String] $Delimiter = " "
    )

    begin {
        $ConvertToTitleCase = {
            param (
                [Parameter(Mandatory, Position=0)]
                [String] $String,
                [String] $Delimiter = " "
            )
            # Split the string and convert each word to title case in one step
            $FormattedString = ($String.Split($Delimiter) | ForEach-Object {
                (Get-Culture).TextInfo.ToTitleCase($_.ToLower())
            }) -join $Delimiter
            return $FormattedString
        }

        # List cases that have to be capitalized
        $Delimiters = [Ordered]@{
            "CamelCase" = ""
            "KebabCase" = "-"
            "LowerCase" = $Delimiter
            "PaslcalCase" = ""
            "SentenceCase" = " "
            "SnakeCase" = "_"
            "TitleCase" = " "
            "TrainCase" = "_"
            "UpperCase" = $Delimiter
        }
        $Capitalise = [Ordered]@{
            First = @("PaslcalCase", "SentenceCase", "TitleCase", "TrainCase")
            Others = @("CamelCase", "PaslcalCase", "SentenceCase", "TitleCase", "TrainCase")
        }
        # Create array of words
        if ($Delimiters.$Format -ne " ") {
            $String = $String -replace ("[^A-Za-z0-9\s]", "")
        }
        $Words = $String.Split($Delimiter)
        $Counter = 0
        $FormattedWords = [System.Collections.ArrayList]@()
    }

    process {
        foreach ($Word in $Words) {
            if ($Format -ne "UpperCase") {
                if ($Counter -gt 0) {
                    if ($Format -in $Capitalise.Others) {
                        $Formatted = & $ConvertToTitleCase -String $Word
                        [Void] $FormattedWords.Add($Formatted)
                    } else {
                        [Void] $FormattedWords.Add($Word.ToLower())
                    }
                } else {
                    if ($Format -in $Capitalise.First) {
                        $Formatted = & $ConvertToTitleCase -String $Word
                        [Void] $FormattedWords.Add($Formatted)
                    } else {
                        [Void] $FormattedWords.Add($Word.ToLower())
                    }
                }
            } else {
                [Void]$FormattedWords.Add($Word.ToUpper())
            }
            $Counter += 1
        }
        # Reconstruct string
        $FormattedString = $FormattedWords -join $Delimiters.$Format
        return $FormattedString
    }
}
