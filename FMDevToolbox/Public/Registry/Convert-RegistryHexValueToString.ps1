using namespace System.Text.RegularExpressions

function Convert-RegistryHexValueToString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline,HelpMessage = "The full hex value to resolve to a string.")]
        [String[]] $RegHexValue,
        [Switch] $ReturnUnescapedOnly
    )

    begin {
        function SanitizeRegValue($val) {
            $rval = $val -replace '^\[.*\]\r?\n', ''
            ((($rval -replace '\\\r?\n', '') -replace '(\,)\r?\n', '$1') -replace "\s+", '').Trim()
        }
    }

    process {

        $RegHexValue | % {

            $valFormatted = SanitizeRegValue $_
            $rePrefixType = [regex]::new(
                '^(?<nameordefault>.*)=hex(?:\((?<valuetype>\d)\))?:(?<hexvalues>[a-fA-F0-9,]+)',
                [RegexOptions]::Compiled
            )
            [Match] $reMatch = $rePrefixType.Match($valFormatted)

            if($reMatch.Success){
                $keyPrefixName    = $reMatch.Groups['nameordefault'].Value
                $keyValueType     = $reMatch.Groups['valuetype'].Value
                $keyHexValues     = $reMatch.Groups['hexvalues'].Value
                $keyHexValuesData = $keyHexValues.Replace(',', '')

                # Set default values
                $valueIsDefault = $false
                $valueName = $null
                if($keyPrefixName -eq '@'){
                    $valueIsDefault = $true
                }
                else {
                    $reNameValue = [regex]::new( '^"(?<name>[^"]+)"$', [RegexOptions]::Compiled )
                    [Match] $reName = $reNameValue.Match($keyPrefixName)
                    if($reName.Success){
                        $valueName = $reName.Groups['name'].Value
                    }
                }
                if(-not$valueIsDefault -and -not$valueName){
                    Write-Error "Couldn't determine the passed values name, or if it's a default value." -EA Continue
                }

                switch ($keyValueType) {
                    "2"	{
                        $valueType = "REG_EXPAND_SZ"
                        $valueTypeLabel = "Expandable String"
                        break
                    }
                    "7" {
                        $valueType = "REG_MULTI_SZ"
                        $valueTypeLabel = "Multi-String"
                        break
                    }
                    default {
                        $valueType = "REG_BINARY"
                        $valueTypeLabel = "Binary"
                        break
                    }
                }

                try {
                    $byteArray = [System.Convert]::FromHexString($keyHexValuesData)
                    $unescapedStr = [Text.Encoding]::Unicode.GetString($byteArray)
                }
                catch {
                    Write-Error "Call to [System.Convert]::FromHexString() and [Text.Encoding]::Unicode.GetString() failed. Couldn't determine the unescaped string."
                    return
                }
                if($ReturnUnescapedOnly){
                    return $unescapedStr
                }
                else {
                    [PSCustomObject]@{
                        Unescaped      = $unescapedStr
                        IsDefault      = $valueIsDefault
                        Name           = $valueName
                        ValueType      = $valueType
                        ValueTypeLabel = $valueTypeLabel
                        HexDataList    = $keyHexValues
                        HexData        = $keyHexValuesData
                        ByteArray      = $byteArray
                        OriginalInput  = $_
                    } | Format-List
                }
            }
        }
    }
}