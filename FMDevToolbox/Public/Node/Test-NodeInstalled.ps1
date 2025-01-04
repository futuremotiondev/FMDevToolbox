function Test-NodeInstalled {
    [CmdletBinding()]
    param ()
    try { Get-Command node.exe -CommandType Application }
    catch { return $false }
    return $true
}