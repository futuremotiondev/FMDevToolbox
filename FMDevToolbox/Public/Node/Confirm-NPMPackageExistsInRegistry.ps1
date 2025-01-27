using namespace System.Text.RegularExpressions
function Confirm-NPMPackageExistsInRegistry {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage="A NPMjs Package Name."
        )]
        [ValidateNotNullOrEmpty()]
        [String[]] $PackageName
    )

    begin {}

    process {
        $PackageName | % {
            $PackageURI = 'https://registry.npmjs.org/' + $_
            $npmParams = @{
                Uri = $PackageURI
                Method = 'GET'
                Headers = @{
                    'Accept' = 'application/vnd.npm.install-v1+json; q=1.0, application/json; q=0.8, */*'
                }
            }
            try {
                Write-Verbose "Checking if $_ exists in the NPMjs Registry..."
                $null = Invoke-RestMethod @npmParams
            } catch {
                Write-Verbose "Failure: $_ does not exist in the NPMjs Registry."
                return $false
            }
            Write-Verbose "Success: $_ does exist in the NPMjs Registry."
            $true
        }
    }
}