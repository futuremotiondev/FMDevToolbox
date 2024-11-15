﻿using namespace System.Management.Automation
class NodeVersions : IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        $Versions = Get-NVMNodeVersions
        return $Versions += 'All'
    }
}
function Update-NVMGlobalNodePackagesByVersion {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet([NodeVersions])]
        [String[]] $Versions = 'All'

    )

    begin {
        $NVMCmd = Get-CommandNVM -ErrorAction Stop
        $NPMCmd = Get-CommandNPM -ErrorAction Stop
        $ActiveNode = Get-NVMActiveNodeVersion
        if($Versions -eq 'All'){
            [String[]] $VersionsToProcess = Get-NVMNodeVersions
        }
        else{
            [String[]] $VersionsToProcess = $Versions
        }
    }

    process {

        foreach ($Version in $VersionsToProcess) {

            & $NVMCmd "use $Version"

            Write-SpectreHost -Message "About to update all global packages for [white]Node $Version[/]"
            Read-Host "Press any key to continue with the operation."

            & $NPMCmd "update -g"
        }

    }

    end {
        Write-SpectreHost -Message "Switching back to your previously activated Node version ([white]$Version[/])"
        & $NVMCmd "use $ActiveNode"
    }
}