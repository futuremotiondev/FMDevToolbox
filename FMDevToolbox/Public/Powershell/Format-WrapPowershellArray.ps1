
function Format-WrapPowershellArray {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [String[]] $InputArray,
        [String] $OutputVariableName = "OutputArray",
        [int] $MaxCharacterWidth = 100
    )

    process {
        $currentLine = "    "
        Write-Output "`$$OutputVariableName = @("
        foreach ($item in $InputArray) {
            if (($currentLine.Length + $item.Length + 4) -le $MaxCharacterWidth) {
                # Add the item to the current line
                if ($currentLine.Trim() -ne "") {
                    $currentLine += ", '$item'"
                } else {
                    $currentLine = "    '$item'"
                }
            } else {
                # Output the current line and start a new one
                Write-Output $currentLine
                $currentLine = "    '$item'"
            }
        }

        # Output any remaining items in the last line
        if ($currentLine.Trim() -ne "") {
            Write-Output $currentLine
        }

        Write-Output ")"
    }
}
