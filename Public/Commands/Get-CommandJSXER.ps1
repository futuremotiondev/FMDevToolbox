function Get-CommandJSXER {
    [CmdletBinding()]
    $CMD = Get-Command jsxer.exe -CommandType Application -ErrorAction SilentlyContinue
    if ($CMD) { return $CMD }
    Write-Error "jsxer.exe (JSXBIN Decompiler) isn't located in PATH. Install it from github.com/AngeloD2022/jsxer"
    return $null
}