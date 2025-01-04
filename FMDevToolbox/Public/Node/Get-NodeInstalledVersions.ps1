function Get-NodeInstalledVersions {
    [CmdletBinding()]
    param()
    if (Test-NVMForWindowsInstalled) {
        Write-Verbose "NVM for Windows is installed."
        $cmd = Get-Command nvm.exe -CommandType Application -ErrorAction Stop
        $versionList = & $cmd 'list'
        $versionList -split "\r?\n" | % {
            if ([String]::IsNullOrEmpty($_)) { return }
            $nodeVersion = (($_ -replace '\* ', '') -replace '\(([\w\s\-]+)\)', '').Trim()
            [PSCustomObject]@{
                Version  = $nodeVersion
            }
        }
    }
    else{
        Write-Verbose "NVM for Windows is not installed."
        try {
            $nodeCmd = Get-Command node.exe -CommandType Application
        }
        catch {
            Write-Error "node.exe isn't in PATH and likely not installed."
            return
        }
        $nodeVersion = @((& $nodeCmd '--version').TrimStart('v'))
        [PSCustomObject]@{
            Version  = $nodeVersion
        }
    }
}

#Get-NodeInstalledVersions