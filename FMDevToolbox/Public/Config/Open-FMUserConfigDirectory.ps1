function Open-FMUserConfigDirectory {
    [CmdletBinding()]
    param ()
    if(-not($script:FMUserConfigDir)){
        Write-Error "Futuremotion user configuration directory wasn't registered properly."
        return
    }
    else{
        if(-not(Test-Path -LiteralPath $script:FMUserConfigDir -PathType Container)){
            Write-Warning "Futuremotion user configuration directory doesn't exist. Creating it now."
            New-Item -Path $script:FMUserConfigDir -ItemType Directory -Force
        }
    }
    explorer.exe $script:FMUserConfigDir
}