using module "..\..\Private\Completions\FMCompleters.psm1"
function Read-PressAnyKeyToContinue {
    <#
    .SYNOPSIS
    Displays a message and waits for the user to press any key to continue.

    .DESCRIPTION
    The Read-PressAnyKeyToContinue function outputs a specified message to the console and pauses
    execution until the user presses any key. This is useful for creating interactive scripts that
    require user acknowledgment before proceeding.

    .PARAMETER Message
    The message to display to the user before waiting for key input.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to prompt the user with a custom message.
    Read-PressAnyKeyToContinue -Message "Press any key to proceed with the operation."

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to use the function in a script to pause execution.
    Write-Host "Starting important process..."
    Read-PressAnyKeyToContinue -Message "Ensure all preparations are complete. Press any key to start."
    Write-Host "Process started."

    .EXAMPLE
    # **Example 3**
    # This example demonstrates using the function without specifying a message parameter.
    Read-PressAnyKeyToContinue

    .OUTPUTS
    None. The function does not return any output but pauses script execution.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 12-14-2024
    #>
    param (
        [String] $Message = 'Press any key to continue...',
        [ValidateSet([ValidateConsoleColors])]
        [String] $MessageColor = 'White',
        [Switch] $DisableSpectreOutput
    )

    if(-not$DisableSpectreOutput){
        if(Test-FunctionAvailability -FunctionName "Write-SpectreHost"){
            Write-SpectreHost $Message
        }
    }
    else{
        Write-Host $Message -f $MessageColor
    }
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}