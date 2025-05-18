function Clear-ConsoleWindow {
    <#
    .SYNOPSIS
    Clears the console window with options to retain buffer and cursor position.

    .DESCRIPTION
    The Clear-ConsoleWindow function clears the visible console screen. It provides
    options to either clear or retain the scrollback buffer and reset or maintain the
    cursor position. This is achieved using ANSI escape sequences.

    .PARAMETER DontClearBuffer
    A switch parameter that, when specified, prevents the clearing of the scrollback
    buffer.

    .PARAMETER DontResetCursor
    A switch parameter that, when specified, prevents resetting the cursor position
    to the top-left corner of the console.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to clear the console window while retaining the scrollback buffer.
    Clear-ConsoleWindow -DontClearBuffer

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to clear the console window while retaining the cursor position.
    Clear-ConsoleWindow -DontResetCursor

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to clear the console window completely, including the buffer and resetting the cursor.
    Clear-ConsoleWindow

    .OUTPUTS
    None. The function outputs directly to the console host.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 05-12-2025
    #>

    [CmdletBinding()]
    param (
        [switch]$DontClearBuffer,
        [switch]$DontResetCursor
    )

    # Start building the ANSI sequence based on switches
    $AnsiSequence = ""

    # Clear scrollback buffer unless suppressed
    if (-not $DontClearBuffer) {
        $AnsiSequence += "`e[3J"
    }

    # Reset cursor position unless suppressed
    if (-not $DontResetCursor) {
        $AnsiSequence += "`e[H"
    }

    # Always clear the visible screen
    $AnsiSequence += "`e[2J"

    # Output the sequence to the host
    Write-Host $AnsiSequence -NoNewline
}

# Set-Alias -Name clsc -Value Clear-ConsoleWindow