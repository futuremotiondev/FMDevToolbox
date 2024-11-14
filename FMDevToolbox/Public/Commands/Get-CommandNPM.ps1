function Get-CommandNPM {
    [CmdletBinding()]
    $PathsToCheck = @( "npm.cmd" )
    if($env:NVM_HOME){ $PathsToCheck += "$env:NVM_HOME\npm.cmd" }
    if($env:NVM_SYMLINK){ $PathsToCheck += "$env:NVM_SYMLINK\npm.cmd" }

    foreach ($File in $PathsToCheck) {
        $CMD = Get-Command $File -CommandType Application -ErrorAction SilentlyContinue
        if ($CMD) { return $CMD }
    }
    Write-Error "NPM (Node Package Manager) cannot be found. Make sure your node installation is configured properly."
    return $null
}
