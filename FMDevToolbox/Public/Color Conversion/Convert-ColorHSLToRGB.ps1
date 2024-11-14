function Convert-ColorHSLToRGB {
    param(
        [ValidateRange(0, 360)]
        [int] $Hue,
        [ValidateRange(0, 100)]
        [int] $Saturation,
        [ValidateRange(0, 100)]
        [int] $Lightness
    )

    $ConvertPqtToRgb = {
        param( [double] $P, [double] $Q, [double] $T )
        if ($T -lt 0) { $T += 1 }
        if ($T -gt 1) { $T -= 1 }
        if ($T -lt (1 / 6)) { return $P + ($Q - $P) * 6 * $T }
        if ($T -lt (1 / 2)) { return $Q }
        if ($T -lt (2 / 3)) { return $P + ($Q - $P) * (2 / 3 - $T) * 6 }
        return $P
    }

    $huePercent = $Hue / 360.0
    $saturationPercent = $Saturation / 100.0
    $lightnessPercent = $Lightness / 100.0

    if ($saturationPercent -eq 0) {
        $red = $lightnessPercent
        $green = $lightnessPercent
        $blue = $lightnessPercent
    } else {
        $q = if ($lightnessPercent -lt 0.5) {
            $lightnessPercent * (1 + $saturationPercent)
        } else {
            $lightnessPercent + $saturationPercent - ($lightnessPercent * $saturationPercent)
        }
        $p = 2 * $lightnessPercent - $q

        $red = & $ConvertPqtToRgb -P $p -Q $q -T ($huePercent + (1 / 3))
        $green = & $ConvertPqtToRgb -P $p -Q $q -T $huePercent
        $blue = & $ConvertPqtToRgb -P $p -Q $q -T ($huePercent - (1 / 3))
    }

    return @(
        [int]($red * 255),
        [int]($green * 255),
        [int]($blue * 255)
    )
}