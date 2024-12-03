function Get-NVMVersion {
    $NVMCmd = Get-CommandNVM -ErrorAction Stop
    if (!$NVMCmd) { return $null }
    $NVMVersion = & $NVMCmd '--version'
    return $NVMVersion
}