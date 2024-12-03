function Get-NodeNVMInstallationDirectory {
    [CmdletBinding()]
    param()

    if($env:NVM_HOME){
        return $env:NVM_HOME
    }
    $NVMCmd = Get-CommandNVM -ErrorAction Stop
    $NVMRootDir = (((& $NVMCmd "root") -split "`n")[1]) -replace 'Current Root: ', '' -replace '^[\s]+(.*)$', '$1'
    if([String]::IsNullOrEmpty($NVMRootDir)){
        Write-Error "nvm.exe (Node Version Manager) can't be found. Make sure it's installed."
        return $null
    }
    return $NVMRootDir
}