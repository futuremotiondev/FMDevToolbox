﻿using namespace System.Management.Automation
class NodeVersions : IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        $Versions = Get-NVMNodeVersions
        return $Versions += 'All'
    }
}

function Get-NVMInstalledNPMVersions {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet([NodeVersions])]
        [String] $NodeVersion = 'All'
    )

    $NodeVersionsObject = Get-NVMInstalledNodeVersions
    $NPMObjects = [System.Collections.Generic.List[Object]]@()

    foreach ($Version in $NodeVersionsObject) {
        if(($NodeVersion -ne $Version.Version) -and $NodeVersion -ne 'All'){
            continue
        }
        else {
            $NPMJson = [System.IO.Path]::Combine($Version.Path, 'node_modules', 'npm', 'package.json')
            $NPMJsonContent = Get-Content $NPMJson | ConvertFrom-Json
            $NPMVersion = $NPMJsonContent.version
            $NPMSupportedVersions = $NPMJsonContent.engines.node
            $LatestNPMVersion = (Get-NPMLatestVersion).Version
            $OutputObject = [PSCustomObject]@{
                Label = "Node v$($Version.Version)"
                CurrentNPMVersion = $NPMVersion
                LatestNPMVersion = $LatestNPMVersion
                SupportedNodeVersions = $NPMSupportedVersions
                NPMUpdateCommand = 'npm install -g npm@latest'
            }

            $NPMObjects.Add($OutputObject)
        }

    }

    return $NPMObjects
}