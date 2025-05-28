function Format-TypeConcurrentDictionary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String] $InputString,

        [ValidateSet('Full', 'FullSimplified', 'Simplified', 'Minimal', 'MinimalSimplified')]
        [ValidateNotNullOrEmpty()]
        [String] $FormatStyle = 'Simplified'
    )

    $reCCDict = [regex]'(?<def>System\.Collections\.Concurrent\.ConcurrentDictionary`\d)\[(?<key>[^,]+),(?<val>[^\]]+)\]'
    $reResults = $reCCDict.Match($InputString).Groups

    $ccdictDef = $reResults['def'].Value
    $ccdictDefNoIdx = $reResults['def'].Value -replace '[`\d]', ''
    $ccdictDefShort = $ccdictDef -replace 'System.Collections.Concurrent.', '';
    $ccdictDefShortNoIdx = $ccdictDefShort -replace '[`\d]', ''
    $ccdictKey = $reResults['key'].Value
    $ccdictVal = $reResults['val'].Value

    $outputStr = switch ($FormatStyle) {
        'Full' { $InputString }
        'FullSimplified' { $ccdictDefNoIdx + " (Key: $ccdictKey, Value: $ccdictVal)" }
        'Minimal' { $ccdictDefShortNoIdx + " (Key: $ccdictKey, Value: $ccdictVal)" }
        'MinimalSimplified' { $ccdictDefShortNoIdx + "($ccdictKey, $ccdictVal)" }
    }

    $outputStr
}