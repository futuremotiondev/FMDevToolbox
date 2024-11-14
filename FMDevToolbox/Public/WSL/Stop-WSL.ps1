function Stop-WSL {
    $CMD = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if($CMD) { wsl.exe --shutdown }
    else { New-Log -Message "wsl.exe cannot be found and therefore cannot be stopped. You don't have WSL installed." -LEVEL WARNING }
}