function Get-CommandNode {
    [CmdletBinding()]
    param()
    $CMD = Get-Command node.exe -CommandType Application -ErrorAction SilentlyContinue
    if(-not$CMD){
        Write-Error "node.exe (Node.js Runtime) cannot be found. Install NodeJS and ensure it exists in PATH"
        return $null
    }
    return $CMD
}
