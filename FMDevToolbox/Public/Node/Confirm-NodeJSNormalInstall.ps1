function Confirm-NodeJSNormalInstall {
    [CmdletBinding()]
    [OutputType([Boolean],[PSCustomObject])]
    param(
        [Parameter(HelpMessage = "If set, outputs an object with detailed error information.")]
        [Switch] $AsObject
    )

    $NVMInstallObject = Confirm-NVMForWindowsIsInstalled -AsObject -EA 0
    if ($NVMInstallObject.Installed) {
        return $AsObject ? [PSCustomObject]@{
            Installed = $false
            Valid = $null
            ErrorCode = "NVMForWindowsIsInstalled"
            ErrorDescription = "NVM for Windows is installed. Not a normal NodeJS install."
        } : $false
    }
    $nodeCmd = Get-Command node -CommandType Application -EA 0
    if(-not$nodeCmd){
        return $AsObject ? [PSCustomObject]@{
            Installed = $false
            Valid = $false
            ErrorCode = "NodeExecutableNotFound"
            ErrorDescription = "node.exe is not available in PATH. NodeJS doesn't seem to be installed."
        } : $false
    }
    else {
        return $AsObject ? [PSCustomObject]@{
            Installed = $true
            Valid = $true
            ErrorCode = $null
            ErrorDescription = $null
        } : $true
    }
}