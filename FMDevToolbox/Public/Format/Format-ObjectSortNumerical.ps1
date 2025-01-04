function Format-ObjectSortNumerical {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Object[]] $InputObject,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateRange(2, 100)]
        [Byte] $MaximumDigitCount = 50,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $Descending

    )

    begin {
        $InnerInputObject = [System.Collections.Generic.List[Object]]@()
    }

    process {
        $InputObject | ForEach-Object {
            $InnerInputObject.Add($_)
        }
    }

    end {
        $InnerInputObject | Sort-Object -Property `
        @{  Expression = {
                [Regex]::Replace($_, '(\d+)', { "{0:D$MaximumDigitCount}" -f [Int32] $Args[0].Value })
            }
        },
        @{ Expression = { $_ } } -Descending:$Descending
    }
}