function Test-NVMForWindowsInstalled {
    [CmdletBinding()]
    param ()

    try { $cmd = Get-Command nvm.exe -CommandType Application }
    catch { return $false }

    $nvmWindowsVersion = & $cmd '--version'
    if($nvmWindowsVersion -ne '1.1.11'){
        Write-Verbose "NVM is installed, but the version is incompatible. Install v1.1.11 from https://github.com/coreybutler/nvm-windows/releases/tag/1.1.11"
        Write-Warning "NVM is installed, but the version is incompatible. Install v1.1.11 from https://github.com/coreybutler/nvm-windows/releases/tag/1.1.11"
        return $false
    }
    return $true
}