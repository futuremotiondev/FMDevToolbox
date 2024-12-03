function New-TempDirectory {
    [CmdletBinding()]
    Param (
        [ValidateRange(0, 30)]
        [Parameter(Mandatory = $false)]
        [Int32]$Length = 13,

        [Parameter(Mandatory = $false)]
        [Switch]$GUID
    )

    $TempPath = [System.IO.Path]::GetTempPath()

    if ($guid) {
        $NewGUID = New-Guid
        $Output = (New-Item -ItemType Directory -Path (Join-Path $TempPath $NewGUID))
    } else {
        $RndName = Get-RandomAlphanumericString -Length $Length
        $Output = (New-Item -ItemType Directory -Path (Join-Path $TempPath $RndName))
    }

    if (Test-Path -LiteralPath $Output.FullName) { return $Output }
}