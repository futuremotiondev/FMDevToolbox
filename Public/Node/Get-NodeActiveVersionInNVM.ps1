function Get-NodeActiveVersionInNVM {
    [CmdletBinding()]
    $NVMCmd = Get-CommandNVM -ErrorAction Stop
    $VersionList = & $NVMCmd 'list'
    $activeVersion = [regex]::Match($VersionList, '\*\s*([0-9.]+)').Groups[1].Value
    if(!$activeVersion){
        Write-Error "Can't determine the active node version via NVM."
        return $null
    }
    $activeVersion
}