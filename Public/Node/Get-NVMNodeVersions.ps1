function Get-NVMNodeVersions {
    $NVMCmd = Get-CommandNVM -ErrorAction Stop
    $NVMOutput = (& $NVMCmd 'list') -split "\r?\n"
    foreach ($Item in $NVMOutput) {
        if([String]::IsNullOrEmpty($Item)){ continue }
        (($Item -replace '\* ', '') -replace '\(([\w\s\-]+)\)', '').Trim()
    }
}