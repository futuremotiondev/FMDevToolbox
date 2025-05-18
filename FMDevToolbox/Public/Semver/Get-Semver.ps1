using namespace System.Management.Automation
function Get-Semver {
    [OutputType([SemanticVersion])]
    [CmdletBinding()]
    param (
        [SemanticVersion] $Version
    )
    return $Version
}
