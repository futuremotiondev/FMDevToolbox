function Convert-ColorRGBToHex {
    param(
        [int] $Red,
        [int] $Green,
        [int] $Blue
    )
    $r = [convert]::Tostring($Red, 16)
    $g = [convert]::Tostring($Green, 16)
    $b = [convert]::Tostring($Blue, 16)
    if ($r.Length -eq 1) { $r = '0' + $r }
    if ($g.Length -eq 1) { $g = '0' + $g }
    if ($b.Length -eq 1) { $b = '0' + $b }
    return "#$r$g$b"
}