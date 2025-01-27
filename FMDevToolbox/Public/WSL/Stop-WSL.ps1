function Stop-WSL {
    $wslCmd = Get-Command wsl.exe -EA 0
    $wslCmdParams = '--shutdown'
    if($wslCmd) { & $wslCmd $wslCmdParams }
    else {
        Write-Error "wsl.exe couldn't be located in PATH."
        return
    }
}