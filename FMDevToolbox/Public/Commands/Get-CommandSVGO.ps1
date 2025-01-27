function Get-CommandSVGO {
    [CmdletBinding()]
    param()
    $svgoCmd = Get-Command svgo.cmd -CommandType Application -EA 0
    if($svgoCmd){

    }
    # Check for NVM managed Node.js installations
    if (Confirm-NVMForWindowsIsInstalled) {

        $NVMCmd = Get-Command nvm.exe -CommandType Application
        $CurrentNode = (& $NVMCmd current).TrimStart('v')
        $ValidNodeVersions = Get-NVMNodeVersions

        if (-not $CurrentNode) {
            Write-Verbose "Current version of Node could not be found. Checking all installed Node versions."
        } else {
            Write-Verbose "Current version of Node is v$CurrentNode, but SVGO isn't installed. Checking other versions."
            $ValidNodeVersions = $ValidNodeVersions | Where-Object { $_ -ne $CurrentNode }
        }

        foreach ($Version in $ValidNodeVersions) {
            $SVGOExists = Test-Path -LiteralPath "${env:NVM_HOME}\v$Version\svgo.cmd" -PathType Leaf
            if ($SVGOExists) {
                Write-Verbose "SVGO exists in an installed version of Node through NVM for Windows. Switching to v$Version."
                & $NVMCmd use $Version 2>&1 | Out-Null
                Start-Sleep -Seconds 1
                if (Test-Path -LiteralPath "$env:NVM_SYMLINK") {
                    $CMD = Test-SVGOExistence -Path "${env:NVM_SYMLINK}\svgo.cmd"
                    if ($CMD) {
                        Write-Verbose "Successfully switched to v$Version and found SVGO."
                        return $CMD
                    }
                }
            }
        }
    }
}
