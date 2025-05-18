function Get-ANSIColorSequenceFrom2Hex {
    <#
    .SYNOPSIS
    Generates ANSI color sequences from foreground and background hex color codes.

    .DESCRIPTION
    The Get-ANSIColorSequenceFrom2Hex function converts two 6-digit hex color codes into ANSI escape sequences for both foreground and background colors.
    It supports options for unescaped output and returning the result as an object containing separate and combined ANSI sequences.

    .PARAMETER Foreground
    Specifies the 6-digit hex color code for the foreground. The hex code must be a valid 6-digit hexadecimal string.

    .PARAMETER Background
    Specifies the 6-digit hex color code for the background. This parameter is optional.

    .PARAMETER Unescaped
    Outputs the ANSI sequences without the escape character prefix (`e[). By default, the sequences include this prefix.

    .PARAMETER AsObject
    Returns the ANSI sequences as a custom object with properties for foreground, background, and combined sequences.

    .OUTPUTS
    String or PSCustomObject

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to generate ANSI sequences for both foreground and background colors.
    Get-ANSIColorSequenceFrom2Hex -Foreground "#FF5733" -Background "#33FF57"

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to generate only a foreground ANSI sequence.
    Get-ANSIColorSequenceFrom2Hex -Foreground "#3357FF"

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to generate unescaped ANSI sequences for both colors.
    Get-ANSIColorSequenceFrom2Hex -Foreground "#AA33FF" -Background "#FF33AA" -Unescaped

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to return the ANSI sequences as a custom object.
    Get-ANSIColorSequenceFrom2Hex -Foreground "#FFAA33" -Background "#33AAFF" -AsObject

    .EXAMPLE
    # **Example 5**
    # This example demonstrates how to use the pipeline to pass a foreground hex color and generate an ANSI sequence.
    "#FF5733" | ForEach-Object { Get-ANSIColorSequenceFrom2Hex -Foreground $_ }

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 02-26-2025
    #>
    [OutputType([String])]
    param (
        [Parameter(Mandatory, Position=0)]
        [string] $Foreground,
        [string] $Background,
        [switch] $Unescaped,
        [Switch] $AsObject
    )

    function Convert-HexToAnsi {
        param (
            [Parameter(Mandatory,Position=0)]
            [string] $HexColor,
            [switch] $IsBackground
        )
        $HexColor = $HexColor -replace '^#'
        if ($HexColor -match '^[0-9A-Fa-f]{6}$') {
            $R = [convert]::ToByte($HexColor.Substring(0, 2), 16)
            $G = [convert]::ToByte($HexColor.Substring(2, 2), 16)
            $B = [convert]::ToByte($HexColor.Substring(4, 2), 16)
            $C = if($IsBackground) { 48 } else { 38 }
            return ("{0};2;{1};{2};{3}m" -f $C, $R, $G, $B)
        }
        else {
            throw "Invalid hex color code. Provide a 6-digit hex color code."
        }
    }

    try {

        $fgAnsiSequence = Convert-HexToAnsi -HexColor $Foreground
        $bgAnsiSequence = if ($Background) {
            Convert-HexToAnsi -HexColor $Background -IsBackground
        } else{ '' }

        if(-not $Unescaped){
            $fgAnsiSequence = "`e[$fgAnsiSequence"
            if(-not [String]::IsNullOrEmpty($bgAnsiSequence)){
                $bgAnsiSequence = "`e[$bgAnsiSequence"
            }
        }
        if($AsObject){
            return [PSCustomObject]@{
                ForegroundANSI = $fgAnsiSequence
                BackgroundANSI = $bgAnsiSequence
                CombinedANSI = "${fgAnsiSequence}${bgAnsiSequence}"
            }
        }
        else {
            return "${fgAnsiSequence}${bgAnsiSequence}"
        }

    } catch {
        Write-Error "An error occurred creating ANSI sequences. Details: $($_.Exception.Message)"
    }
}

