function Convert-PlaintextListToPowershellArray {
    <#
    .SYNOPSIS
    Converts a plaintext list into a PowerShell array declaration.

    .DESCRIPTION
    This function takes a list of strings from either the pipeline, clipboard, or
    direct input and converts it into a PowerShell array declaration. It supports
    sorting, removing duplicates, stripping quotes, and outputting to a file or
    clipboard. The function can also suppress console output if desired.

    .PARAMETER InputList
    A list of strings to be converted into a PowerShell array. Accepts pipeline
    input.

    .PARAMETER ListFromClipboard
    Indicates that the input list should be taken from the clipboard.

    .PARAMETER SortList
    Specifies how the list should be sorted. Options are 'Ascending', 'Descending',
    or 'None'. Default is 'Ascending'.

    .PARAMETER ArrayName
    The name of the PowerShell array to be created. Default is 'NewArray'.

    .PARAMETER OutputFilepath
    An optional file path where the resulting PowerShell array declaration should be saved.

    .PARAMETER CopyToClipboard
    Copies the resulting PowerShell array declaration to the clipboard.

    .PARAMETER StripQuotes
    Removes any leading or trailing quotes from each item in the list.

    .PARAMETER RemoveDuplicates
    Removes duplicate entries from the list before processing.

    .PARAMETER SuppressOutput
    Suppresses the output of the PowerShell array declaration to the console.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to convert a list of strings from the pipeline into a PowerShell array.
    "Item1", "Item2", "Item3" | Convert-PlaintextListToPowershellArray -ArrayName "MyArray"

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to convert a list from the clipboard, sort it in descending order, and copy the result back to the clipboard.
    Convert-PlaintextListToPowershellArray -ListFromClipboard -SortList "Descending" -CopyToClipboard

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to remove duplicates and strip quotes from an input list, then save the result to a file.
    $list = @('"Item1"', '"Item2"', '"Item1"')
    Convert-PlaintextListToPowershellArray -InputList $list -RemoveDuplicates -StripQuotes -OutputFilepath "C:\output.txt"

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to suppress output while converting a list and saving the result to a specified file.
    Convert-PlaintextListToPowershellArray -InputList @("A", "B", "C") -SuppressOutput -OutputFilepath "C:\array.ps1"

    .OUTPUTS
    System.String. The PowerShell array declaration as a string, unless suppressed.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 05-13-2025
    #>
    [CmdletBinding(DefaultParameterSetName = "InputList")]
    [OutputType([System.String])]
    param(
        [Parameter(
            Position=0,
            ParameterSetName="InputList",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string[]] $InputList,

        [Parameter(
            Position=0,
            ParameterSetName="Clipboard",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Switch] $ListFromClipboard,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('Ascending','Descending','None')]
        [String] $SortList = 'None',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidatePattern('^\w+$')]
        [String] $ArrayName = 'NewArray',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({$_ -notmatch '[\?\*]'},
            ErrorMessage = "Wildcard characters *, ? are not acceptable.")]
        [String[]] $OutputFilepath,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $CopyToClipboard,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $StripQuotes,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $RemoveDuplicates,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $SuppressOutput
    )

    begin {}
    process {
        [string[]] $outputList = if ($PSCmdlet.ParameterSetName -eq 'Clipboard') {
            $clipboardArray = Get-Clipboard
            if (-not $clipboardArray) {
                Write-Error "Clipboard is empty."
                return
            }
            $clipboardArray
        } else {
            $InputList
        }

        if ($StripQuotes) { $outputList = $outputList.Trim('"\''') }
        if ($RemoveDuplicates) { $outputList = $outputList | Select-Object -Unique }
        if ($SortList -ne 'None') {
            $outputList = $outputList | Sort-Object -Descending:($SortList -eq 'Descending')
        }

        [string[]] $outputArr = @( ('${0} = @(' -f $ArrayName) )
        $outputList | % { $outputArr += '    "{0}"' -f $_ }
        $outputArr += ')'

        # Make sure that the .NET framework uses the same working dir. as PS.
        [IO.Directory]::SetCurrentDirectory($PWD.ProviderPath)

        if($CopyToClipboard){ $outputArr | Set-Clipboard }
        if(-not([String]::IsNullOrWhiteSpace($OutputFilepath))){
            $finalOutputFile = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($OutputFilepath)
            $finalOutputFile = Get-UniqueNameIfDuplicate -LiteralPath $finalOutputFile
            $UTF8_ENC = [System.Text.UTF8Encoding]::new($true)
            Write-Verbose "Saving output file to '$finalOutputFile'"
            [System.IO.File]::WriteAllLines($finalOutputFile, $outputArr, $UTF8_ENC)
        }
        if(-not$SuppressOutput){ $outputArr }
    }
}