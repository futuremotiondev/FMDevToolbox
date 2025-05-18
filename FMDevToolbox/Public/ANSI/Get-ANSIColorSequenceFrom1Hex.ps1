function Get-ANSIColorSequenceFrom1Hex {
    [OutputType([String])]
    param (
        [Parameter(Mandatory,Position=0)]
        [string] $HexColor,
        [switch] $Background,
        [switch] $Unescaped
    )
    if ($HexColor -match '^#[0-9A-Fa-f]{6}$') {
        $HexColor = $HexColor -replace '^#'
        $R = [convert]::ToByte($HexColor.Substring(0, 2), 16)
        $G = [convert]::ToByte($HexColor.Substring(2, 2), 16)
        $B = [convert]::ToByte($HexColor.Substring(4, 2), 16)
        $C = if($Background) { 48 } else { 38 }
        $ANSI = "{0};2;{1};{2};{3}m" -f $C, $R, $G, $B
        if($Unescaped){ $ANSI }
        else { "`e[$ANSI" }
    }
    else {
        Write-Error "Invalid hex color code."
    }
}