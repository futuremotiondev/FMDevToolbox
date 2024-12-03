function Add-NumericSuffixToFile {
    [OutputType([string])]
    [CmdletBinding()]

    param (

        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [String[]] $Path,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [Int32] $Number,

        [Parameter(ValueFromPipelineByPropertyName)]
        [String] $PreSuffix,

        [Parameter(ValueFromPipelineByPropertyName)]
        [String] $Separator = " ",

        [Parameter(ValueFromPipelineByPropertyName)]
        [Int32] $ZeroPadding = 1
    )

    process {

        [Array] $Output = foreach ($String in $Path) {

            $Directory = [System.IO.Path]::GetDirectoryName($String)
            $FileName = [System.IO.Path]::GetFileNameWithoutExtension($String)
            $Extension = [System.IO.Path]::GetExtension($String)

            $FormattedNumber = $Number.ToString("D$ZeroPadding")
            $NewFileName = "$FileName$Separator$PreSuffix$FormattedNumber$Extension"

            if ($Directory) {
                $NewPath = Join-Path -Path $Directory -ChildPath $NewFileName
            } else {
                $NewPath = $NewFileName
            }

            $NewPath
        }

        $Output
    }
}