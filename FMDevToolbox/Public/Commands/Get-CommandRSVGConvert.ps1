function Get-CommandRSVGConvert {
    [CmdletBinding()]
    $CMD = Get-Command rsvg-convert.exe -CommandType Application -ErrorAction SilentlyContinue
    if($CMD){ return $CMD }
    $CMD = Get-Command "$env:FM_BIN\rsvg-convert.exe" -CommandType Application -ErrorAction SilentlyContinue
    if($CMD){ return $CMD }
    Write-Error "rsvg-convert.exe (librsvg) cannot be found. Make sure its available in PATH."
}
