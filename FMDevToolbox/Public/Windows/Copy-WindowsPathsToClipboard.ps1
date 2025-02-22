﻿
function Copy-WindowsPathsToClipboard {

    param(
        [Parameter(Mandatory,Position=0)]
        [string[]] $LiteralPath,
        [switch] $FilenamesOnly,
        [switch] $NoQuotes,
        [ValidateSet('Default','DoubleBackslash','ForwardSlash','DoubleForwardSlash')]
        [string] $SlashFormat = 'Default',
        [switch] $NoExtension,
        [string] $AsPowershellArray,
        [Int32] $MaxThreads = 14
    )

    begin {

        if ((-not[String]::IsNullOrEmpty($AsPowershellArray)) -and $NoQuotes) { throw "-AsPowershellArray and -NoQuotes cannot be used together." }
        if ((-not[String]::IsNullOrEmpty($AsPowershellArray)) -and ($SlashFormat -ne 'Default')){ throw "-AsPowershellArray and -SlashFormat cannot be used together." }
        if (($SlashFormat -ne 'Default') -and $FilenamesOnly) { throw "-SlashFormat and -FilenamesOnly cannot be used together." }

        $FileList = [System.Collections.Generic.List[String]]@()
        $ListFile = [System.Collections.Generic.List[String]]@()
    }

    process {
        foreach ($Path in $LiteralPath) {
            if (Test-Path -LiteralPath $Path) {
                $null = $FileList.Add($Path)
            }
            else{
                Write-Warning -Message "Passed path or file does not exist on disk. ($Path)" -WarningAction Continue
            }
        }
    }

    end {

            $ReplaceSlashes = {
                param (
                    [Parameter(Mandatory)]
                    [String[]] $LiteralPath,
                    [Parameter(Mandatory)]
                    [ValidateSet('DoubleBackslash','ForwardSlash','DoubleForwardSlash')]
                    [String] $SlashFormat
                )

                $LiteralPath | ForEach-Object {
                    $BackslashEscaped = [regex]::Escape('\')
                    if($SlashFormat -eq 'DoubleBackslash'){ $Result = $_ -replace $BackslashEscaped,'\\' }
                    elseif($SlashFormat -eq 'ForwardSlash'){ $Result = $_ -replace $BackslashEscaped,'/' }
                    elseif($SlashFormat -eq 'DoubleForwardSlash'){ $Result = $_ -replace $BackslashEscaped,'//' }
                    $Result
                }
            }


            $FileList | ForEach-Object -Parallel {

                $ListFile      = $Using:ListFile
                $NoQuotes      = $Using:NoQuotes
                $FilenamesOnly = $Using:FilenamesOnly
                $NoExtension   = $Using:NoExtension
                $FinalPath     = ""


                if ($FilenamesOnly) {
                    if($NoExtension) { $FinalPath = [System.IO.Path]::GetFileNameWithoutExtension($_) }
                    else{
                        $FinalPath = [System.IO.Path]::GetFileName($_)
                    }
                }
                else {
                    if($NoExtension) { $FinalPath = $_.Substring(0, $_.LastIndexOf('.')) }
                    else{ $FinalPath = $_ }
                }
                if(!$NoQuotes){ $FinalPath = "`"$FinalPath`"" }
                $null = $ListFile.Add($FinalPath)

            } -ThrottleLimit $MaxThreads

            $SortedFiles = $ListFile | Format-ObjectSortNumerical

            if(($SlashFormat -ne 'Default') -and (!$FilenamesOnly)){
                $SortedFiles = & $ReplaceSlashes -LiteralPath $SortedFiles -SlashFormat $SlashFormat
            }
            if(-not[String]::IsNullOrEmpty($AsPowershellArray)){
                $SortedFiles = Convert-PlaintextListToPowershellArray -ListItems $SortedFiles -ArrayName $AsPowershellArray -StripQuotes
            }

            $SortedFiles | Set-Clipboard

    }
}

