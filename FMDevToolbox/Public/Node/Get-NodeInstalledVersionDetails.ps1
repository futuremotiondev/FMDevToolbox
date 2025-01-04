function Get-NodeInstalledVersionDetails {
    [CmdletBinding(DefaultParameterSetName = "All")]
    param (
        [Parameter(ParameterSetName = "Latest")]
        [Switch] $NVMLatest,
        [Parameter(ParameterSetName = "Oldest")]
        [Switch] $NVMOldest,
        [Parameter(ParameterSetName = "Active")]
        [Switch] $NVMActive
    )

    $nvmIsInstalled = Test-NVMForWindowsInstalled
    if(-not($nvmIsInstalled)){
        if($PSBoundParameters.ContainsKey('NVMLatest')){
            throw "The -NVMLatest switch cannot be used if NVM for Windows is not installed."
        }
        if($PSBoundParameters.ContainsKey('NVMOldest')){
            throw "The -NVMOldest switch cannot be used if NVM for Windows is not installed."
        }
        if($PSBoundParameters.ContainsKey('NVMLatest')){
            throw "The -NVMActive switch cannot be used if NVM for Windows is not installed."
        }
    }

    if ($nvmIsInstalled) {
        Write-Verbose "NVM for Windows is installed."
        $cmd = Get-Command nvm.exe -CommandType Application -ErrorAction Stop
        $versionList = & $cmd 'list'
        $activeVersion = [regex]::Match($versionList, '\*\s*([0-9.]+)').Groups[1].Value
        $nodeVersions = $versionList -split "\r?\n" | % {
            if ([String]::IsNullOrEmpty($_)) { return }
            $version = (($_ -replace '\* ', '') -replace '\(([\w\s\-]+)\)', '').Trim()

            $isActive = $false
            if ($activeVersion -eq $version) {
                $isActive = $true
            }

            $rootFolder = [System.IO.Path]::Combine($env:NVM_HOME, "v$version")
            $modulesFolder = [System.IO.Path]::Combine($env:NVM_HOME, "v$version", "node_modules")
            $globalModulesList = Get-NodeGlobalModules -GlobalModuleDirectory $modulesFolder
            $docsURL = "https://nodejs.org/dist/v{0}/docs/api/" -f $version
            $npmVersionObject = Get-NodeInstalledNPMVersion -NodeVersion $version
            [PSCustomObject]@{
                InstallType      = "NVM for Windows"
                Version          = $version
                Folder           = $rootFolder
                IsActive         = $isActive
                DocsURL          = $docsURL
                NPMVersion       = $npmVersionObject.NPMVersion
                NPMLatestVersion = $npmVersionObject.NPMLatestVersion
                NPMNeedsUpdate   = $npmVersionObject.NeedsUpgrade
                GlobalModules    = $globalModulesList
            }
        }
        if ($PSBoundParameters['NVMActive']) {
            $activeVersion = $nodeVersions | Where-Object { $_.IsActive }
            if ($activeVersion) {
                return $activeVersion
            } else {
                Write-Verbose "No version of node is active."
                return $null
            }
        }
        if ($PSBoundParameters['NVMLatest']) {
            $nodeVersions[0]
            return
        }
        if ($PSBoundParameters['NVMOldest']) {
            $nodeVersions[-1]
            return
        }
        $nodeVersions
    }
    else{
        Write-Verbose "NVM for Windows is not installed."
        try {
            $nodeCmd = Get-Command node.exe -CommandType Application
        }
        catch {
            Write-Error "node.exe isn't in PATH."
            return
        }
        $nodeVersion = (& $nodeCmd '--version').TrimStart('v')
        $nodeFolder = [System.IO.Directory]::GetParent($nodeCmd.Path).FullName
        $nodeModulesFolder = Join-Path $nodeFolder -ChildPath "node_modules"
        if(-not(Test-Path -LiteralPath $nodeModulesFolder -PathType Container)){
            $nodeModulesFolder = $null
        }
        $docsURL = "https://nodejs.org/dist/v{0}/docs/api/" -f $nodeVersion
        $globalModulesList = Get-NodeGlobalModules -GlobalModuleDirectory $nodeModulesFolder
        $npmVersionObject = Get-NodeInstalledNPMVersion -NodeVersion $nodeVersion
        [PSCustomObject]@{
            InstallType      = "Default Install"
            Version          = $nodeVersion
            Folder           = $nodeFolder
            IsActive         = $true
            DocsURL          = $docsURL
            NPMVersion       = $npmVersionObject.NPMVersion
            NPMLatestVersion = $npmVersionObject.NPMLatestVersion
            NPMNeedsUpdate   = $npmVersionObject.NeedsUpgrade
            GlobalModules    = $globalModulesList
        }
    }
}

#Get-NodeInstalledVersionDetails
