function Test-FunctionAvailability {
    <#
    .SYNOPSIS
    Checks if a specified function is available in the current PowerShell session.

    .DESCRIPTION
    The Test-FunctionAvailability function determines whether a given function name exists within
    the current PowerShell session. It returns a boolean value: True if the function is available,
    and False otherwise.

    .PARAMETER FunctionName
    Specifies the name of the function to check for availability.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to check if a function named 'Get-Data' is available.
    Test-FunctionAvailability -FunctionName 'Get-Data'

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to verify the existence of a function named 'Export-Report'.
    if (Test-FunctionAvailability -FunctionName 'Export-Report') {
        Write-Output "Function 'Export-Report' is available."
    } else {
        Write-Output "Function 'Export-Report' is not available."
    }

    .OUTPUTS
    System.Boolean
    Returns True if the function is available; otherwise, False.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 12-14-2024
    #>
    param (
        [Parameter(Mandatory,Position=0)]
        [string]$FunctionName
    )
    return [bool](Get-Command -Name $FunctionName -CommandType Function -ErrorAction SilentlyContinue)
}