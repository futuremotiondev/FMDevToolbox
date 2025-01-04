function Test-ValidLiteralPath {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "LiteralPath",
            HelpMessage="Literal path to check for validity."
        )]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,
        [Switch] $OutputObject
    )

    begin {
        $InvalidFileChars = [System.IO.Path]::GetInvalidFileNameChars()
        $InvalidPathChars = [System.IO.Path]::GetInvalidPathChars()
        $InvalidChars = $InvalidFileChars + $InvalidPathChars
    }

    process {
        foreach ($Path in $LiteralPath) {
            $isValid = $true
            $reason = ""

            if ($Path -match '[\?\*]') {
                $isValid = $false
                $reason = "Path contains wildcard characters."
            } elseif ($Path -contains $InvalidChars) {
                $isValid = $false
                $reason = "Path contains invalid characters."
            } elseif (-not [System.IO.Path]::IsPathRooted($Path)) {
                $isValid = $false
                $reason = "Path is not rooted."
            }

            if ($OutputObject) {
                [PSCustomObject]@{
                    Path = $Path
                    Valid  = $isValid
                    Reason = $reason
                }
            } else {
                $isValid
            }
        }
    }
}