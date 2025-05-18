function Get-PythonInstallations {
    [CmdletBinding()]
    param (
        [Switch] $SuppressFreeThreaded
    )

    if($Ascending -and $Descending){
        throw "The Ascending and Descending switches cannot be used together."
    }

    $cmdPy = Get-Command py.exe -CommandType Application -EA 0
    if(!$cmdPy) { throw "Py Launcher (py.exe) is not available in PATH." }
    [String[]] $py1= (& $cmdPy -0) -split "\r?\n"
    [String[]] $py2 = (& $cmdPy -0p) -split "\r?\n"

    for ($idx = 0; $idx -lt $py1.Count; $idx++) {

        $ShortVersion = ((($py1[$idx] -replace $([regex]::Escape('-V:')), '').Trim()) -replace '[\s\*]+Python\s([\d\.]+)(.*)$', '')
        $Bitness      = $py1[$idx] -replace '^(:?.*)(\(.*\))$', '$2' -replace ',[\s]freethreaded\)', ') FT' -replace '^\(', '' -replace '\)$', ''
        $Path         = $py2[$idx] -replace '^(:?\s\-V\:)', '' -replace '[\s\*]+', ' ' -replace '(.*) (.*)$', '$2'
        $PyBinary     = [System.IO.Path]::GetFileName($Path)

        $IsFreeThreaded = $false
        $Params = '--version'
        [String] $VersionString = & $Path $Params
        $VersionString = $VersionString.Trim()
        $FullVersion = $VersionString.TrimStart('Python ').Trim()

        if($ShortVersion -match '(\d\.*)t'){
            if($SuppressFreeThreaded){ continue }
            $ShortVersion = $ShortVersion.TrimEnd('t')
            $Bitness = $Bitness.TrimEnd(' FT') -replace '\)$',''
            $IsFreeThreaded = $true
        }

        $Bitness = $Bitness -replace '\-bit', ''

        [PSCustomObject]@{
            Python       = $VersionString
            Version      = $ShortVersion
            FullVersion  = $FullVersion
            Arch         = $Bitness
            PythonPath   = $Path
            FreeThreaded = $IsFreeThreaded
            PythonBinary = $PyBinary
        }
    }
}