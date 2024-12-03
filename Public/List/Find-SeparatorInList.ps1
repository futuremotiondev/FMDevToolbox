using namespace System.Text.RegularExpressions

function Find-SeparatorInList {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $InputText,
        [Switch] $IncludeDot,
        [Switch] $InputIsFileList
    )

    process {
        $InputText = $InputText.Trim()
        $reDelimiters = @{
            Tab = '\t'
            Pipe = '\|'
        }
        if (-not $InputIsFileList) {
            if ($IncludeDot) {
                $reDelimiters["Dot"] = '\.'
            }
            $reDelimiters["Comma"] = '\,'
            $reDelimiters["Semicolon"] = ';'
            $reDelimiters["Colon"] = '\:'
        }

        $reOps = [RegexOptions]::IgnoreCase -bor [RegexOptions]::Compiled
        $maxCount = 1
        $bestDelimiter = $null
        $bestDelimiterRegex = $null
        $delimiterFound = $false
        $bestGuess = $null

        foreach ($delim in $reDelimiters.GetEnumerator()) {
            $re = [regex]::new($delim.Value, $reOps)
            $parts = $re.Split($InputText)
            if ($parts.Count -gt $maxCount) {
                $maxCount = $parts.Count
                $bestDelimiter = $delim.Key
                $bestDelimiterRegex = $delim.Value
                $bestDelimiterValue = $delim.Value -replace '^\\', ''
                $delimiterFound = $true
                $bestGuess = $delim.Key
            }
        }

        $crlfCount = ([regex]::Matches($InputText, "\r\n")).Count
        $lfCount = ([regex]::Matches($InputText, "\n")).Count
        $newlineType = $null
        $linebreaksPresent = $false
        $linebreaksMalformed = $false

        if ($crlfCount -gt 0 -or $lfCount -gt 0) {
            $linebreaksPresent = $true
            $newlineType = $crlfCount -ge $lfCount ? "\r\n" : "\n"
            $newlineLabel = $newlineType -eq "\r\n" ? "CRLF" : "LF"
            $newlineCount = $newlineType -eq "\r\n" ? $crlfCount : $lfCount
            if (!$delimiterFound){
                $delimiterFound = $true
                $bestDelimiter = $newlineLabel
                $bestDelimiterRegex = $newlineType
                $bestDelimiterValue = $newlineType
                $bestGuess = $bestDelimiter
            }else{

                $delimiterNewlineCount = ([regex]::Matches($InputText, "$bestDelimiterRegex$newlineType")).Count
                $delimCount = $maxCount - 1

                if ($delimCount -ne $newlineCount) {
                    $delimiterFound = $false
                    $linebreaksMalformed = $true
                    $bestDelimiter = $null
                    $bestDelimiterValue = $null
                    $bestDelimiterRegex = $null
                } else {
                    $delimiterFound = $true
                    $bestDelimiter = "${bestDelimiter}+${newlineLabel}"
                    $bestDelimiterValue = "${bestDelimiterValue}${newlineType}"
                    $bestDelimiterRegex = "${bestDelimiterRegex}${newlineType}"
                    $bestGuess = $bestDelimiter
                }
            }
        }

        [PSCustomObject]@{
            DelimiterFound      =  $delimiterFound
            DelimiterName       =  $bestDelimiter
            Delimiter           =  $bestDelimiterValue
            DelimiterRegEx      =  $bestDelimiterRegex
            BestGuess           =  $bestGuess
            LinebreaksPresent   =  $linebreaksPresent
            LinebreaksMalformed =  $linebreaksMalformed
        }
    }
}
