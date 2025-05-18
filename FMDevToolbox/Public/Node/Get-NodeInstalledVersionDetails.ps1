using module "..\..\Private\Completions\FMCompleters.psm1"
function Get-NodeInstalledVersionDetails {
    <#
    .SYNOPSIS
    Retrieves details about installed Node.js versions.

    .DESCRIPTION
    The Get-NodeInstalledVersionDetails function provides detailed information about the Node.js
    versions installed on a system. It supports retrieving specific versions, the latest version,
    or the active version. Additional options include showing NPM details, checking for NPM updates,
    and enumerating global modules.

    .PARAMETER Version
    Specifies the Node.js versions to retrieve details for. Default is 'All'.

    .PARAMETER Latest
    Switch to retrieve details of the latest installed Node.js version.

    .PARAMETER Active
    Switch to retrieve details of the currently active Node.js version.

    .PARAMETER ShowNPMDetails
    Switch to include NPM version details in the output.

    .PARAMETER CheckForNPMUpdates
    Switch to check if there are updates available for NPM.

    .PARAMETER EnumerateGlobalModules
    Switch to enumerate globally installed Node.js modules.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to retrieve details for all installed Node.js versions.
    Get-NodeInstalledVersionDetails

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to retrieve details for the latest installed Node.js version.
    Get-NodeInstalledVersionDetails -Latest

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to retrieve details for two specific Node.js versions, including NPM details.
    Get-NodeInstalledVersionDetails -Version "23.6.1", "22.13.1" -ShowNPMDetails

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to check for NPM updates for the active Node.js version.
    Get-NodeInstalledVersionDetails -Active -CheckForNPMUpdates

    .EXAMPLE
    # **Example 5**
    # This example demonstrates how to enumerate global modules for all installed Node.js versions.
    Get-NodeInstalledVersionDetails -Version 'All' -EnumerateGlobalModules

    .OUTPUTS
    Outputs a PSCustomObject containing details about the Node.js installation, including version, type, active status, install directory, node binary path, architecture, and optionally NPM details and global modules.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 01-27-2025
    #>
    [CmdletBinding(DefaultParameterSetName = "Version")]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            ParameterSetName = "Version",
            HelpMessage = "The versions of Node.js you wish to retrieve details for."
        )]
        [ValidateNotNullOrEmpty()]
        [CompletionsNodeVersionsPlusAll()]
        [String[]] $Version = 'All',
        [Parameter(ParameterSetName="Latest")]
        [Switch] $Latest,
        [Parameter(ParameterSetName="Active")]
        [Switch] $Active,
        [Parameter(ParameterSetName="Version")]
        [Parameter(ParameterSetName="Latest")]
        [Parameter(ParameterSetName="Active")]
        [Switch] $ShowNPMDetails,
        [Parameter(ParameterSetName="Version")]
        [Parameter(ParameterSetName="Latest")]
        [Parameter(ParameterSetName="Active")]
        [Switch] $CheckForNPMUpdates,
        [Parameter(ParameterSetName="Version")]
        [Parameter(ParameterSetName="Latest")]
        [Parameter(ParameterSetName="Active")]
        [Switch] $EnumerateGlobalModules
    )

    if($PSBoundParameters['CheckForNPMUpdates'] -and -not$PSBoundParameters['ShowNPMDetails']){
        Write-Verbose "-CheckForNPMUpdates was passed, but -ShowNPMDetails wasn't. Overriding -ShowNPMDetails to true."
        $PSBoundParameters['ShowNPMDetails'] = $true
    }

    [PSCustomObject[]] $versionList = @()
    if (Confirm-NVMForWindowsIsInstalled) {
        $nvmCmd = Get-Command nvm.exe -CommandType Application
        (& $nvmCmd 'list') -split "\r?\n" | % {
            $activeVersion = $false
            if([String]::IsNullOrEmpty($_)){ return }
            if($_ -match '\* '){ $activeVersion = $true }
            $v = [version] (($_ -replace '\* ', '') -replace '\(([\w\s\-]+)\)', '').Trim()
            $versionList += [PSCustomObject]@{
                Version = $v
                Type = 'NVMForWindows'
                Active = $activeVersion
                Latest = $false
                InstallDir = "$env:NVM_HOME\v$v"
            }
        } | Sort-Object -Property Version -Descending
    }
    elseif(Confirm-NodeJSNormalInstall) {
        $nodeCmd = Get-Command node -CommandType Application
        [version] $v = (& $nodeCmd '--version').TrimStart('v').Trim()
        $versionList += [PSCustomObject]@{
            Version = $v
            Type = 'NormalInstall'
            Active = $true
            Latest = $true
            InstallDir = Split-Path -LiteralPath $nodeCmd.Path
        }
    }

    $versionList[0].Latest = $true

    if($PSBoundParameters['Latest']){
        $versionList = $versionList | Select-Object -First 1
    }
    elseif($PSBoundParameters['Active']){
        $versionList = $versionList | Where-Object { $_.Active -eq $true }
    }
    elseif($PSBoundParameters['Version'] -and $Version -ne 'All'){
        $versionList = $versionList | Where-Object {
            $Version -contains (($_.Version).ToString())
        }
    }
    if($versionList.Count -eq 0){
        Write-Warning "No versions match the passed set of parameters."
        return
    }

    $GetLatestNPMVersion = {
        $npmUrl = "https://registry.npmjs.org/npm/latest"
        try { [version]((Invoke-RestMethod -Uri $npmUrl -Method Get -ea SilentlyContinue -Verbose:$false).version) }
        catch {
            Write-Warning "Unable to determine latest NPM version."
            return "Unable to determine"
        }
    }



    $versionList | % {

        $vObj = $_
        $curVersion = $vObj.Version
        $curType = $vObj.Type
        $curIsActive = $vObj.Active
        $curIsLatest = $vObj.Latest
        $curInstallDir = $vObj.InstallDir

        $nodeExe = Join-Path -Path $curInstallDir -ChildPath 'node.exe'
        $nodeCmd = Get-Command $nodeExe -CommandType Application
        $archParams = "-p", "process.arch"
        $architecture = (& $nodeCmd $archParams).Trim()

        $output = [PSCustomObject]@{
            Version          = $curVersion
            Type             = $curType
            Active           = $curIsActive
            Latest           = $curIsLatest
            InstallDirectory = $curInstallDir
            NodeBinary       = $nodeExe
            Architecture     = $architecture
        }

        #  NPM Version and Update Check  //////////////////////////////////////////////////////////#

        if($PSBoundParameters['ShowNPMDetails']){
            $npmJson = [System.IO.Path]::Combine(($curInstallDir), 'node_modules', 'npm', 'package.json')
            $npmVer  = [version] ((Get-Content -LiteralPath $npmJson -Raw | ConvertFrom-Json).version).Trim()
            $output | Add-Member -NotePropertyName 'NPMVersion' -NotePropertyValue $npmVer
        }

        if($PSBoundParameters['CheckForNPMUpdates']){
            $latestNpm = (& $GetLatestNPMVersion)
            if($latestNpm){
                $needsUpdate = ($npmVer -lt $latestNpm) ? $true : $false
                $output | Add-Member -NotePropertyName 'NPMLatestRelease' -NotePropertyValue $latestNpm
                $output | Add-Member -NotePropertyName 'NPMNeedsUpdate' -NotePropertyValue $needsUpdate
                $output | Add-Member -NotePropertyName 'NPMUpdateCommand' -NotePropertyValue 'npm install -g npm@latest'
            }
        }

        #  Global Module Enumeration  /////////////////////////////////////////////////////////////#

        if($PSBoundParameters['EnumerateGlobalModules']){

            $nodeModules = [System.IO.Path]::Combine(($curInstallDir), 'node_modules')
            $moduleDirs = Get-ChildItem $nodeModules -Directory -Force

            $globalModulesAccumulator = foreach ($dir in $moduleDirs) {
                $moduleDirBase = [System.IO.Path]::GetFileName($dir.FullName)
                if($moduleDirBase.StartsWith('@')){
                    [System.IO.DirectoryInfo[]] $currentModuleDirs = Get-ChildItem -LiteralPath $dir.FullName -Directory -Depth 0
                    $currentModuleDirs | % {
                        [PSCustomObject]@{ FullPath = $_.FullName; Scope = $moduleDirBase; Module = $_.Name; }
                    }
                }
                else {
                    [PSCustomObject]@{ FullPath = $dir.FullName; Scope = $null; Module = $moduleDirBase; }
                }
            }
            $globalModules = foreach ($moduleObject in $globalModulesAccumulator) {
                $jsonFilePath = Get-ChildItem -LiteralPath $moduleObject.FullPath -Include 'package.json'
                Write-Verbose "Global Module $($moduleObject.Module) package.json found at $jsonFilePath"
                $jsonData = Get-Content $jsonFilePath | ConvertFrom-Json
                [PSCustomObject]@{
                    ModuleName    = $jsonData.name
                    ModuleVersion = $jsonData.version
                    ModuleID      = "{0}@{1}" -f $jsonData.name, $jsonData.version
                    ModuleLink    = "https://www.npmjs.com/package/$($jsonData.name)"
                }
            }
            [String[]] $GlobalModuleIDArray = @()
            foreach ($gMod in $globalModules) {
                $GlobalModuleIDArray += $gMod.ModuleID
            }
            $output | Add-Member -NotePropertyName 'GlobalModules' -NotePropertyValue $globalModules
            $output | Add-Member -NotePropertyName 'GlobalModuleIDs' -NotePropertyValue $GlobalModuleIDArray

        }
        $output
    }
}