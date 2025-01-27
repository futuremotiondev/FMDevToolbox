using module "..\..\Private\Completions\FMCompleters.psm1"

using namespace Spectre.Console

function Convert-ToPercentage {
    [CmdletBinding()]

    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [double[]] $DecimalValue,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $TrimTrailingZerosFromString,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('Decimal', 'Double', 'Single', 'String', 'StringWithPercentSign')]
        [string] $ReturnValueFormat = 'Decimal',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('ValuesOnly', 'Object', 'ObjectTable', 'ObjectSpectreTable')]
        [String] $ReturnCollectionType = 'ValuesOnly',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateRange(0, 20)]
        [int] $DecimalPlaces = 0,

        [Parameter(ValueFromPipelineByPropertyName)]
        [CompletionsSpectreColors()]
        [string] $SpectreBorderColor = '#5e5e5e',

        [Parameter(ValueFromPipelineByPropertyName)]
        [CompletionsSpectreColors()]
        [string] $SpectreHeaderColor = '#97e0d4',

        [Parameter(ValueFromPipelineByPropertyName)]
        [CompletionsSpectreColors()]
        [string] $SpectreTextColor = '#9f9f9f',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet([ValidateSpectreTableBorders])]
        [string] $SpectreBorderStyle = 'Rounded'
    )

    begin {

        if($ReturnCollectionType -ne 'ObjectSpectreTable'){
            $ParamBorderColor = $PSBoundParameters.ContainsKey('SpectreBorderColor')
            $ParamHeaderColor = $PSBoundParameters.ContainsKey('SpectreHeaderColor')
            $ParamTextColor = $PSBoundParameters.ContainsKey('SpectreTextColor')
            $ParamBorderStyle = $PSBoundParameters.ContainsKey('SpectreBorderStyle')
            $AnySpectreParamsPassed = ($ParamBorderColor -or $ParamHeaderColor -or $ParamTextColor -or $ParamBorderStyle)
            if($AnySpectreParamsPassed){
                Write-Error -Message "Spectre Formatting Parameters can only be passed when -ReturnCollectionType is set to 'ObjectSpectreTable'" -ErrorAction Stop
            }
        }

        $FinalValues = [System.Collections.Generic.List[Object]]@()
    }

    process {

        foreach ($Value in $DecimalValue) {

            # Calculate the percentage value
            $Percentage = $Value * 100

            # Format the percentage based on the specified decimal places
            $Formatted = "{0:N$($DecimalPlaces)}" -f $Percentage

            $ValueDecimal = $Formatted -as [decimal]
            $ValueDouble = $Formatted -as [double]
            $ValueSingle = $Formatted -as [single]
            $ValueString = $Formatted -as [string]
            $ValueStringPercent = "$Formatted%"

            if($TrimTrailingZerosFromString){
                $ValueString = $ValueString -replace '\.?0+$'
                $ValueStringPercent = "$ValueString%"
            }

            $ReturnType = $ReturnCollectionType

            if($ReturnType -eq 'ValuesOnly'){
                $val = switch ($ReturnValueFormat) {
                    "Decimal" { $ValueDecimal }
                    "Double" { $ValueDouble }
                    "Single" { $ValueSingle }
                    "String" { $ValueString }
                    "StringWithPercentSign" { $ValueStringPercent }
                }
                $FinalValues.Add($Val)
            } else {
                $Val = [PSCustomObject]@{
                    OriginalDecimal = $Value
                    FinalDecimal = $ValueDecimal
                    FinalDouble = $ValueDouble
                    FinalSingle = $ValueSingle
                    FinalString = $ValueString
                    FinalStringWithPercent = $ValueStringPercent
                }
                $FinalValues.Add($Val)
            }
        }
    }
    end {
        if($ReturnCollectionType -eq 'Object'){ $FinalValues }
        elseif($ReturnCollectionType -eq 'ObjectTable'){ $FinalValues | Format-Table -AutoSize }
        elseif($ReturnCollectionType -eq 'ObjectSpectreTable'){
            $formatSpectreTableSplat = @{
                Border      = $SpectreBorderStyle
                Color       = $SpectreBorderColor
                HeaderColor = $SpectreHeaderColor
                TextColor   = $SpectreTextColor
            }
            $FinalValues | Format-SpectreTable @formatSpectreTableSplat
        }
        else { $FinalValues }
    }
}