function Confirm-NVMForWindowsIsInstalled {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType([bool])]
    param()

    $NVMIsInstalled = $false
    $NVMCMD = Get-Command nvm.exe -CommandType Application -ErrorAction SilentlyContinue
    if($NVMCMD){
        $NVMIsInstalled = $true
        [Version] $NVMVersion = & $NVMCMD "--version"
        if (-not($NVMVersion.Major -eq 1 -and $NVMVersion.Minor -eq 1 -and $NVMVersion.Build -eq 11)) {
            Write-Error "NVM for Windows is installed, but its version is incompatible with this module. You must have version 1.1.11 installed. Get it from here: https://github.com/coreybutler/nvm-windows/releases/tag/1.1.11"
            return $false
        }
        else {
            return $true
        }
    }
    else {
        $CMD = Get-Command "$env:SystemDrive\Users\$env:USERNAME\AppData\Roaming\nvm\nvm.exe" -CommandType Application
        if($CMD){
            Write-Error "NVM for Windows is installed, not available in path. Your installation is likely corrupt."
            return $false
        }
        Write-Error "NVM for Windows is not installed. Get it from here: https://github.com/coreybutler/nvm-windows/releases/tag/1.1.11. Any version above 1.1.11 is incompatible with this module."
        return $false
    }
}