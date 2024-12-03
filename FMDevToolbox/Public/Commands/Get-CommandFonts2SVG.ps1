function Get-CommandFonts2SVG {
    [CmdletBinding()]
    $pathsToCheck = @(
        "$env:FM_PY_VENV\FontTools\Scripts\fonts2svg.exe",
        "D:\Dev\Python\.venv\FontTools\Scriptsfonts2svg.exe",
        "fonts2svg.exe"
    )
    foreach ($Path in $pathsToCheck) {
        $CMD = Get-Command $Path -CommandType Application -ErrorAction SilentlyContinue
        if ($CMD) { return $CMD }
    }
    Write-Error "Python FontTools fonts2svg.exe cannot be found. Install the FontTools VENV in $env:FM_PY_VENV\FontTools"
    return $null
}