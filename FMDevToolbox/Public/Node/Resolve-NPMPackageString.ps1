using namespace System.Text.RegularExpressions
function Resolve-NPMPackageString {
    <#
    .SYNOPSIS
    Parses and resolves NPM package strings into their components: scope, package name, and version.

    .DESCRIPTION
    The Resolve-NPMPackageString function takes an array of NPM package strings and parses them to extract the scope, package name, and version string. It returns a custom object with these details for each input string.

    .PARAMETER PackageString
    An array of NPM package strings to be parsed. The string format should follow the pattern `@scope/package@version`.

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    Returns a custom object containing:
    - Input: Original package string
    - Valid: Boolean indicating if the parsing was successful
    - Scope: Parsed scope of the package (if any)
    - PackageName: Parsed package name
    - VersionString: Parsed version string (if any)

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to parse a scoped package string.
    Resolve-NPMPackageString -PackageString "@scope/package@1.0.0"

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to parse a package string without a scope.
    Resolve-NPMPackageString -PackageString "package@2.0.0"

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to handle multiple package strings from the pipeline.
    "@scope/package@1.0.0", "package@2.0.0" | Resolve-NPMPackageString

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 11-28-2024
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    param (
        [Parameter(
            Mandatory,
            Position=0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [String[]] $PackageString
    )

    begin {
        [regex] $rePattern = '^(@(?<Scope>[^/]+)/)?(?<PackageName>[^@/]+)(@(?<VersionString>.+))?$'
    }

    process {

        $PackageString | % {
            try {
                [MatchCollection] $NPMMatches = $rePattern.Matches($_)

                if($NPMMatches){
                    $PackageScope = $NPMMatches.Captures.Groups['Scope']
                    $PackageName = $NPMMatches.Captures.Groups['PackageName']
                    $VersionString = $NPMMatches.Captures.Groups['VersionString']

                    if(-not$PackageName){
                        Write-Verbose "Invalid package notation: '$_'. A PackageName is required."
                        return $null
                    }
                    [PSCustomObject]@{
                        Input         = $_
                        IsValid       = $true
                        Scope         = $PackageScope
                        PackageName   = $PackageName
                        VersionString = $VersionString
                    }
                }
                else {
                    Write-Verbose "Invalid package notation: '$_'."
                    [PSCustomObject]@{
                        Input         = $_
                        IsValid       = $false
                        Scope         = $null
                        PackageName   = $null
                        VersionString = $null
                    }
                }
            } catch {
                Write-Verbose "An error occurred while parsing the package notation: $_"
                [PSCustomObject]@{
                    Input         = $_
                    IsValid       = $false
                    Scope         = $null
                    PackageName   = $null
                    VersionString = $null
                }
            }
        }
    }
}