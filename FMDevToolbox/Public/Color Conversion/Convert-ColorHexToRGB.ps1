function Convert-ColorHexToRGB {
    param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "HTMLHex",
            HelpMessage="Specify an HTML hex color code like #FFFFFF")]
        [ValidatePattern('^#[A-Fa-f0-9]{6}$')]
        [string] $HexColor
    )

    # Remove any leading '#' if present
    $Hex = $HexColor -replace '^#'

    # Convert hex to RGB
    $Red   = [convert]::ToByte($Hex.Substring(0, 2), 16)
    $Green = [convert]::ToByte($Hex.Substring(2, 2), 16)
    $Blue  = [convert]::ToByte($Hex.Substring(4, 2), 16)

    return @(
        [int]$Red,
        [int]$Green,
        [int]$Blue
    )
}

# Convert Hex to RGB
function HexToRgb($hex) {
    $hex = $hex.TrimStart('#')  # Remove '#' if present
    # Convert each pair of hex digits to an integer
    [int]$redc   = [Convert]::ToInt32($hex.Substring(0, 2), 16)
    [int]$greenc = [Convert]::ToInt32($hex.Substring(2, 2), 16)
    [int]$bluec  = [Convert]::ToInt32($hex.Substring(4, 2), 16)
    return [PSCustomObject]@{ R = $redc; G = $greenc; B = $bluec }
}


