﻿using namespace System.Text.RegularExpressions
function Split-StringByDelimiter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [string] $InputString,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string[]] $Delimiters,

        [ValidateSet('Array', 'String', 'Object')]
        [string] $OutputType = 'Array',

        [ValidateSet('None', 'Leading', 'Trailing', 'Both', 'All', 'ReduceLeading', 'ReduceTrailing', 'ReduceAll')]
        [string] $WhitespaceTrimming = 'Both',

        [switch] $IncludeEmptyStrings,
        [switch] $IncludeNewlines,
        [switch] $Regex,
        [switch] $CaseSensitive,
        [switch] $IncludeDelimitersInOutput,
        [string] $NewDelimiter = "\r\n", # Custom output delimiter
        [int] $MaxSplit = [int]::MaxValue
    )

    process {

        $Delimiters = $Delimiters | ForEach-Object {
            $_ -replace '\\r', "`r" -replace '\\n', "`n"
        }

        $NewDelimiter = $NewDelimiter -replace '\\r', "`r" -replace '\\n', "`n"
        $NewDelimiterArr = $NewDelimiter -replace "`r", '' -replace "`n", ''


        # Add newline characters to delimiters if IncludeNewlines is specified
        if ($IncludeNewlines) {
            $Delimiters += "`r`n", "`n"
        }

        # Prepare delimiters for regex split
        $DelimRegexPattern = if ($Regex) {
            ($Delimiters -join '|')
        } else {
            ($Delimiters | ForEach-Object { [regex]::Escape($_) }) -join '|'
        }

        # Handle case sensitivity
        $regexOptions = if ($CaseSensitive) {
            [RegexOptions]::None -bor [RegexOptions]::Compiled
        }
        else {
            [RegexOptions]::IgnoreCase -bor [RegexOptions]::Compiled
        }

        $inputMatches = [regex]::Matches($InputString, $DelimRegexPattern, $regexOptions)

        [Array] $splits = @()
        [int] $prevIndex = 0
        [int] $count = 0
        foreach ($match in $inputMatches) {
            if ($count -ge $MaxSplit - 1) { break }
            $splits += ($InputString.Substring($prevIndex, $match.Index - $prevIndex))
            $prevIndex = $match.Index + $match.Length
            $count++
        }
        $splits += $InputString.Substring($prevIndex) # Add the remaining part of the string

        $splitStrings = $splits
        $splitArray = $splits

        $TrimWhitespace = {
            param (
                [Parameter(Mandatory)]
                [array] $Arr
            )

            $NewArr = @()
            # Trim whitespace if requested
            if ($WhitespaceTrimming -ne 'None') {
                $NewArr = $Arr | ForEach-Object {
                    $OrigStr = $_
                    switch ($WhitespaceTrimming) {
                        'Both' {
                            $OrigStr.Trim()
                        }
                        'Leading' {
                            $OrigStr.TrimStart()
                        }
                        'Trailing' {
                            $OrigStr.TrimEnd()
                        }
                        'All' {
                            $ReplaceResult = [regex]::Replace($OrigStr, '\s', '')
                            $ReplaceResult
                        }
                        'ReduceLeading' {
                            $ReplaceResult = [regex]::Replace($OrigStr, '^(\s+)(\S*)', ' $2')
                            $ReplaceResult
                        }
                        'ReduceTrailing' {
                            $ReplaceResult = [regex]::Replace($OrigStr, '^(\s*)(\S+)(\s+)', '$1$2 ')
                            $ReplaceResult
                        }
                        'ReduceAll' {
                            $ReplaceResult = [regex]::Replace($OrigStr, '^(\s+)', ' ')
                            $ReplaceResult = [regex]::Replace($ReplaceResult, '(\s+)$', ' ')
                            $ReplaceResult
                        }
                        default {
                            $OrigStr
                        }
                    }
                }
            } else {
                $NewArr = $Arr
            }
            return $NewArr
        }

        $splitStrings = & $TrimWhitespace -Arr $splitStrings
        $splitArray = & $TrimWhitespace -Arr $splitArray

        # Filter out empty strings if not included
        if (-not $IncludeEmptyStrings) {
            $splitStrings = $splitStrings | Where-Object { $_ -ne '' }
            $splitArray = $splitArray | Where-Object { $_ -ne '' }
        }

        $finalReturnStrings = $splitStrings -join $NewDelimiter
        [Array] $finalReturnArray = @()
        if(($OutputType -eq 'Array') -or ($OutputType -eq 'Object')){
            for ($i = 0; $i -lt $splitArray.Count - 1; $i++) {
                $finalReturnArray += $splitArray[$i] + $NewDelimiterArr
            }
            $finalReturnArray += $splitArray[$splitArray.Count -1]
        }

        # Build result based on OutputType
        $resultObj = switch ($OutputType) {
            'String' {
                $finalReturnStrings
            }
            'Array' {
                $finalReturnArray
            }
            'Object' {

                $NewDelimiter = $NewDelimiter -replace "`r", '\r' -replace "`n", '\n'

                [PSCustomObject][Ordered]@{
                    InputString               =  $InputString
                    Delimiters                =  $Delimiters
                    WhitespaceTrimming        =  $WhitespaceTrimming
                    IncludeEmptyStrings       =  $IncludeEmptyStrings.IsPresent
                    IncludeNewlines           =  $IncludeNewlines.IsPresent
                    RegexUsed                 =  $Regex.IsPresent
                    CaseSensitive             =  $CaseSensitive.IsPresent
                    IncludeDelimitersInOutput =  $IncludeDelimitersInOutput.IsPresent
                    NewDelimiter              =  $NewDelimiter
                    MaxSplit                  =  $MaxSplit
                    ResultArray               =  $finalReturnArray
                    ResultString              =  $finalReturnStrings
                }
            }
        }

        return $resultObj
    }
}