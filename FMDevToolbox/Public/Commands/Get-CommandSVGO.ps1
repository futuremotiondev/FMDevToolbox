function Get-CommandSVGO {
    [CmdletBinding()]
    param()
    function Test-SVGOExistence {
        param ([string]$Path)
        return Get-Command $Path -CommandType Application -ErrorAction SilentlyContinue
    }

    # Check for svgo.cmd in various locations
    $Locations = @(
        "svgo.cmd",
        "${env:SystemDrive}\Program Files\nodejs\svgo.cmd"
    )
    foreach ($Location in $Locations) {
        $CMD = Test-SVGOExistence -Path $Location
        if ($CMD) { return $CMD }
    }
    # Check for NVM managed Node.js installations
    if (Confirm-NVMForWindowsIsInstalled) {
        $NVMCmd = Get-CommandNVM -ErrorAction Stop
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
    # Check for the executable release by Antonytm
    $CMD = Test-SVGOExistence -Path "svgo-win.exe"
    if ($CMD) {
        Write-Warning "Found the executable release of SVGO by Antonytm (svgo-win.exe), but since it's unmaintained, things might break!"
        return $CMD
    }
    throw "svgo.cmd cannot be located. Install it globally in Nodejs and make sure it's available in PATH."
}
