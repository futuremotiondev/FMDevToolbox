function Confirm-NVMForWindowsIsInstalled {
    [CmdletBinding()]
    [OutputType([Boolean],[PSCustomObject])]
    param(
        [Parameter(HelpMessage = "If set, outputs an object with detailed error information.")]
        [Switch] $AsObject
    )

    # Define compatible NVM versions
    $compatibleNVMVersions = @("1.2.2", "1.2.1", "1.2.0", "1.1.11")

    # Attempt to get the nvm.exe command
    $NVMCMD = Get-Command nvm.exe -CommandType Application -EA 0

    # Check if nvm.exe is found
    if (-not $NVMCMD) {
        return $AsObject ? [PSCustomObject]@{
            Installed = $false
            Valid = $false
            ErrorCode = "NVMNotFound"
            ErrorDescription = "nvm.exe cannot be found in PATH. Make sure NVM for Windows is installed correctly."
        } : $false
    }

    # Retrieve and trim the NVM version
    $NVMVersion = (& $NVMCMD "--version" -EA 0).Trim()

    # Check if the NVM version is compatible
    if ($NVMVersion -notin $compatibleNVMVersions) {
        return $AsObject ? [PSCustomObject]@{
            Installed = $true
            Valid = $false
            ErrorCode = "InstalledNVMNotCompatible"
            ErrorDescription = "Installed version of NVM for Windows is incompatible with this module $($NVMVersion.ToString()). Supported versions are v1.2.2, v1.2.1, v1.2.0, and v1.1.11."
        } : $false
    }

    # Check if environment variables are set
    if (-not ($env:NVM_HOME -and $env:NVM_SYMLINK)) {
        return $AsObject ? [PSCustomObject]@{
            Installed = $true
            Valid = $false
            ErrorCode = "InstalledNVMNotCompatible"
            ErrorDescription = "Your version of NVM for Windows is misconfigured. The environment variables `$env:NVM_HOME and `$env:NVM_SYMLINK are not present."
        } : $false
    }

    # If all checks pass, return valid result
    return $AsObject ? [PSCustomObject]@{
        Installed = $true
        Valid = $true
        ErrorCode = $null
        ErrorDescription = $null
    } : $true
}