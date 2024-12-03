function Get-CommandImageMagick {
    [CmdletBinding()]
    $CMD = Get-Command magick.exe -CommandType Application -ErrorAction SilentlyContinue
    if($CMD){ return $CMD }
    $CMD = Get-Command "$env:FM_BIN\ImageMagick\magick.exe" -CommandType Application -ErrorAction SilentlyContinue
    if($CMD){ return $CMD }
    Write-Error "magick.exe (Image Magick) cannot be found. Make sure it's available in PATH."
}