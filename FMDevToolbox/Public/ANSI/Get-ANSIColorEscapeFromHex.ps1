function Get-ANSIColorEscapeFromHex {
    param (
        [string]$HexColor,
        [switch]$Background
    )

    # Remove any leading '#' if present
    $HexColor = $HexColor -replace '^#'

    # Validate hex color code
    if ($HexColor -match '^[0-9A-Fa-f]{6}$') {
        # Convert hex to RGB
        $Red = [convert]::ToByte($HexColor.Substring(0, 2), 16)
        $Green = [convert]::ToByte($HexColor.Substring(2, 2), 16)
        $Blue = [convert]::ToByte($HexColor.Substring(4, 2), 16)

        # Determine if setting foreground or background
        $colorType = if ($Background.IsPresent) { 48 } else { 38 }

        # Generate ANSI color escape sequence
        $EscapeSequence = ([char] 27) + [string]::Format('[{0};2;{1};{2};{3}m', $colorType, $Red, $Green, $Blue)

        # Return the escape sequence
        return $EscapeSequence
    }
    else {
        Write-Host "Invalid hex color code. Please provide a 6-digit hex color code." -ForegroundColor Red
    }
}