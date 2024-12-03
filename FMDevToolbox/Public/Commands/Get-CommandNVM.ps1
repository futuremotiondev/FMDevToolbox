function Get-CommandNVM {
    [CmdletBinding()]
    $CMD = Get-Command nvm.exe -CommandType Application -ErrorAction SilentlyContinue
    if($CMD){
        return $CMD
    }
    $PathsToCheck = @(
        "$env:NVM_HOME\nvm.exe",
        "$env:SystemDrive\Users\$env:USERNAME\AppData\Roaming\nvm\nvm.exe"
    )
    foreach ($Path in $PathsToCheck) {
        $CMD = Get-Command $Path -CommandType Application -ErrorAction SilentlyContinue
        if ($CMD) { return $CMD }
    }
    Write-Error "NVM (Node Version Manager) cannot be found. Make sure it's installed."
    return $null
}


