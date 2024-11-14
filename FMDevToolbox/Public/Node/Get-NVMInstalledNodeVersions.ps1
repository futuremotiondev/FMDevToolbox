function Get-NVMInstalledNodeVersions {
    [CmdletBinding()]
    param ()

    $NVMNodeVersionsArray = Get-NVMNodeVersions
    foreach ($Version in $NVMNodeVersionsArray) {

        $NodeVersionInstallPath = Join-Path $env:NVM_HOME -ChildPath "v$Version"
        $NodeModulesFolder = Join-Path $NodeVersionInstallPath -ChildPath "node_modules"
        $ModuleDirectories = Get-ChildItem -LiteralPath $NodeModulesFolder -Directory -Depth 0 | % {$_.FullName}

        Write-Verbose "Node v$Version install path is $NodeVersionInstallPath"
        Write-Verbose "Node v$Version modules folder is $NodeModulesFolder"

        $NPMJson = Get-Content -Raw $([System.IO.Path]::Combine($NodeModulesFolder, 'npm', 'package.json')) | ConvertFrom-JSON
        $NPMVersion = $NPMJson.version
        $MajorVersion = ($Version -split '\.')[0]
        $DocsURL = "https://nodejs.org/dist/v{0}/docs/api/" -f $Version
        $ChangelogURL = "https://github.com/nodejs/node/blob/main/doc/changelogs/CHANGELOG_V{0}.md#{1}" -f $MajorVersion, $Version
        $DownloadURL = "https://nodejs.org/dist/v{0}/node-v{0}-x64.msi" -f $Version

        Write-Verbose "Node v$Version NPM version is $NPMVersion"


        $GlobalModuleList = [System.Collections.Generic.List[Object]]@()
        $CorruptGlobalModuleList = [System.Collections.Generic.List[String]]@()

        foreach ($ModuleDir in $ModuleDirectories) {

            $Dirname = [System.IO.Path]::GetFileName($ModuleDir)
            Write-Verbose "Node v$Version - Found installed module: $Dirname"

            if((Get-ChildItem -Path $ModuleDir).Count -eq 0){
                Write-Verbose "Installed module directory is empty: $Dirname"
                Write-Verbose "Deleting $Dirname as it contains no content."
                [System.IO.Directory]::Delete($ModuleDir, $true)
                continue
            }

            if($Dirname.StartsWith('@')){
                $ModuleDir = Get-ChildItem -LiteralPath $ModuleDir -Directory -Depth 0 | % {$_.FullName}
                Write-Verbose "Module ($Dirname) is @scoped. Root module directory is $ModuleDir"
            }

            $JSONFile = Get-ChildItem -LiteralPath $ModuleDir -Include 'package.json' | % {$_.FullName}

            if(-not$JSONFile){
                Write-Error "package.json was not found in $ModuleDir. Is the module corrupt?"
                $CorruptGlobalModuleList.Add($ModuleDir)
            }
            else {
                Write-Verbose "$Dirname package.json found at $JSONFile"
                $JSONData = Get-Content $JSONFile | ConvertFrom-Json
                $ModuleName = $JSONData.name
                $ModuleVersion = $JSONData.version
                $FormattedModule = "$ModuleName@$ModuleVersion"
                $url = "https://www.npmjs.com/package/$ModuleName"

                $o = [PSCustomObject]@{
                    ModuleName = $ModuleName
                    ModuleVersion = $ModuleVersion
                    ModuleID = $FormattedModule
                    ModuleLink = $url
                }

                $GlobalModuleList.Add($o)
            }
        }

        [PSCustomObject]@{
            Label = "Node v$Version"
            Version = $Version
            DocsURL = $DocsURL
            ChangelogURL = $ChangelogURL
            DownloadURL = $DownloadURL
            Path = $NodeVersionInstallPath
            GlobalModules = $GlobalModuleList
            GlobalModulesCorrupt = $CorruptGlobalModuleList
            NPMVersion = $NPMVersion
        }
    }

}