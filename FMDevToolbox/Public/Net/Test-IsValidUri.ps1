using namespace System
using namespace System.Text.RegularExpressions

function Test-IsValidUri {
    <#
    .SYNOPSIS
        Validates a URI string against specified allowed schemes.

    .DESCRIPTION
        The Test-IsValidUri function checks if a given URI string is valid based on the specified allowed schemes.
        It uses regular expressions to ensure the URI format is correct and that it does not contain invalid characters immediately after the scheme.
        The function supports pipeline input for the URI string.

    .PARAMETER UriString
        The URI string to validate. This parameter is mandatory and accepts pipeline input.

    .PARAMETER AllowedSchemes
        Specifies the allowed URI schemes for validation. Default schemes are 'http' and 'https'.
        Acceptable values include 'http', 'https', 'file', 'ftp', 'ftps', and 'mailto'.

    .OUTPUTS
        [Bool] - Returns $true if the URI is valid, otherwise $false.

    .EXAMPLE
        # **Example 1**
        # This example demonstrates how to validate an HTTP URI.
        Test-IsValidUri -UriString "http://example.com"

    .EXAMPLE
        # **Example 2**
        # This example demonstrates how to validate an HTTPS URI with custom allowed schemes.
        Test-IsValidUri -UriString "https://secure.example.com" -AllowedSchemes @('https')

    .EXAMPLE
        # **Example 3**
        # This example demonstrates how to validate a file URI using the pipeline.
        "file:///C:/path/to/file.txt" | Test-IsValidUri -AllowedSchemes @('file')

    .EXAMPLE
        # **Example 4**
        # This example demonstrates how to validate multiple URIs with different schemes using the pipeline.
        "ftp://fileserver.com", "mailto:user@example.com" | Test-IsValidUri -AllowedSchemes @('ftp', 'mailto')

    .EXAMPLE
        # **Example 5**
        # This example demonstrates how to handle an invalid URI and log the error message.
        try {
            Test-IsValidUri -UriString "invalid://example"
        } catch {
            Write-Host "Validation failed: $($_.Exception.Message)"
        }

    .NOTES
        Author: Futuremotion
        Website: https://github.com/futuremotiondev
        Date: 03-14-2025
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, HelpMessage="The URI string to validate.")]
        [ValidateNotNullOrEmpty()]
        [String] $UriString,

        [Parameter(ValueFromPipelineByPropertyName, HelpMessage = "Allowed URI schemes to validate.")]
        [ValidateSet('http', 'https', 'file', 'ftp', 'ftps', 'mailto')]
        [ValidateNotNullOrEmpty()]
        [String[]] $AllowedSchemes = @('http', 'https')
    )

    begin {
        # Construct the regex pattern dynamically based on allowed schemes
        $schemesPattern = ($AllowedSchemes -join '|')
        $reBasicValidation = [regex]::new("^($schemesPattern)://([^/$.?#\s][^\s]*)$", [RegexOptions]::Compiled)

        # Regex to detect spaces or invalid characters after scheme
        $reInvalidChar = [regex]::new("^($schemesPattern)://([\s/$.?#]+)", [RegexOptions]::Compiled)
    }

    process {
        try {
            $match = $reInvalidChar.Match($UriString)
            if ($match.Success) {
                $invalidChars = $match.Groups[2].Value.Replace(' ', '')
                $invalidCharsArray = @()
                if($match.Groups[2].Value.Contains(' ')){
                    $invalidCharsArray += 'Whitespace'
                }
                $invalidStr = ($invalidCharsArray += $invalidChars.ToCharArray() | Select-Object -Unique) -join ', '
                throw [System.ArgumentException]::new("Invalid characters were found directly after the URI scheme: ($invalidStr)")
            }
            if (-not $reBasicValidation.Match($UriString).Success) {
                throw [System.FormatException]::new("The URI does not match the expected pattern for allowed schemes: ($($AllowedSchemes -join ', '))")
            }
            $uri = $null
            if (-not [Uri]::TryCreate($UriString, [UriKind]::Absolute, [ref]$uri)) {
                throw [System.UriFormatException]::new("Unable to create a valid URI object from the provided string")
            }
            if ($uri.Scheme -notin $AllowedSchemes) {
                throw [System.NotSupportedException]::new("Unsupported URL scheme. ($($uri.Scheme)) is not in the list of allowed schemes: ($($AllowedSchemes -join ', '))")
            }
            return $true
        }
        catch {
            Write-Error "URI Validation Failed. $($_.Exception.Message)"
            return $false
        }
    }
}