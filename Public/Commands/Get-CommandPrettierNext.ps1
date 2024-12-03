function Get-CommandPrettierNext {
    [CmdletBinding()]
    $PathsToCheck = @( "prettier-next.cmd" )
    foreach ($File in $PathsToCheck) {
        $CMD = Get-Command $File -CommandType Application -ErrorAction SilentlyContinue
        if ($CMD) { return $CMD }
    }
    Write-Error "prettier-next.cmd (CLI for Prettier) wasn't found in PATH. It likely needs to be installed globally via Node.js (@prettier/cli)."
    return $null
}