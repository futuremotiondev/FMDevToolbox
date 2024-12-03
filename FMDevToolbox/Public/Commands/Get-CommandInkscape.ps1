function Get-CommandInkscape {
    [CmdletBinding()]
    $CMD = Get-Command inkscape.com -CommandType Application -ErrorAction SilentlyContinue
    if($CMD){ return $CMD }
    $CMD = Get-Command "$env:FM_BIN\inkscape\bin\inkscape.com" -CommandType Application -ErrorAction SilentlyContinue
    if($CMD){ return $CMD }
    throw "Can't locate inkscape. Aborting"
}