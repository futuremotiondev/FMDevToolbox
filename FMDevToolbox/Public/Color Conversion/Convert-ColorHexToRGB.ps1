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
    $Red = [convert]::ToByte($Hex.Substring(0, 2), 16)
    $Green = [convert]::ToByte($Hex.Substring(2, 2), 16)
    $Blue = [convert]::ToByte($Hex.Substring(4, 2), 16)

    return @(
        [int]$Red,
        [int]$Green,
        [int]$Blue
    )
}