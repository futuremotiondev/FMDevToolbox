function Get-InstalledPSCoreVersion {
    [CmdletBinding(DefaultParameterSetName="Full")]
    param (
        [Parameter(ParameterSetName='Major')]
        [switch] $Major,
        [Parameter(ParameterSetName='Minor')]
        [switch] $Minor,
        [Parameter(ParameterSetName='Patch')]
        [switch] $Patch
    )
    $latestVersion = Get-ChildItem HKLM:\SOFTWARE\Microsoft\PowerShellCore\InstalledVersions |
        ForEach-Object { Get-ItemProperty $_.PSPath } |
        Where-Object { $_.SemanticVersion -notlike '*preview*' } |
        Sort-Object -Property SemanticVersion -Descending |
        Select-Object -First 1

    if (-not $latestVersion) { return $null }

    $versionParts = $latestVersion.SemanticVersion.Split('.')

    switch ($PSCmdlet.ParameterSetName) {
        'Full'  { return $latestVersion.SemanticVersion }
        'Major' { return $versionParts[0] }
        'Minor' { return $versionParts[1] }
        'Patch' { return $versionParts[2] }
    }
}