function Get-GitIgnore {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    param (
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String[]] $Languages = @("Node", "CSharp", "VSCode"),
        [String] $OutputPath,
        [Switch] $ListAvailable
    )
    process {

    }
    end {}
}