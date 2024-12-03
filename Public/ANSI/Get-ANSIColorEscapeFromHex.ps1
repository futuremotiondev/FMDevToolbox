function Get-ANSIColorEscapeFromHex {
    <#
    .SYNOPSIS
    Generates an ANSI color escape sequence from a hex color code.

    .DESCRIPTION
    The Get-ANSIColorEscapeFromHex function converts a 6-digit hex color code into an ANSI escape sequence for terminal text coloring.
    It supports both foreground and background colors and provides an option to reset the color formatting.

    .PARAMETER HexColor
    A 6-digit hexadecimal color code representing the desired color.

    .PARAMETER Background
    A switch indicating if the color should be applied as a background color.

    .PARAMETER Reset
    A switch to return the ANSI escape sequence for resetting color formatting.

    .OUTPUTS
    System.String

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to generate an ANSI escape sequence for a foreground color.
    Get-ANSIColorEscapeFromHex -HexColor "#FF5733"

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to generate an ANSI escape sequence for a background color.
    Get-ANSIColorEscapeFromHex -HexColor "4287f5" -Background

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to get the ANSI escape sequence to reset color formatting.
    Get-ANSIColorEscapeFromHex -Reset

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 11-18-2024
    #>
    param (
        [string] $HexColor,
        [switch] $Background,
        [Switch] $Reset
    )

    if ($Reset) { return ([char]27) }

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
        $EscapeSequence = ([char]27) + [string]::Format('[{0};2;{1};{2};{3}m', $colorType, $Red, $Green, $Blue)

        # Return the escape sequence
        return $EscapeSequence
    }
    else {
        Write-Host "Invalid hex color code. Please provide a 6-digit hex color code." -ForegroundColor Red
    }
}
