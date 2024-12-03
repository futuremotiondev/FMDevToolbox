function Test-ValidWildcardPath {
    [CmdletBinding()]
    param (
        [parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Path,
        [Switch] $OutputObject
    )

    begin {
        $re = '^[a-z]:[/\\][^{0}]*$' -f [regex]::Escape(([IO.Path]::InvalidPathChars -join ''))
    }

    process {
        $Results = @()
        foreach ($Item in $Path) {

            $isValid = $true
            if ($OutputObject) {
                $Obj = [PSCustomObject]@{ Path = $Item; Valid = $null; }
            }
            if ($Item -notmatch $re) {
                Write-Verbose "Path is not valid"
                $isValid = $false
            }
            if ($OutputObject) {
                $Obj.Valid = $isValid
                $Results += $Obj
            } else {
                $Results += $isValid
            }
        }

        $Results
    }
}