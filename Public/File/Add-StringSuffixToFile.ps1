function Add-StringSuffixToFile {

    [OutputType([string])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [String[]] $Path,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [String] $Suffix,
        [String] $SuffixSeparator = " "
    )

    process {

        [Array] $Output = foreach ($String in $Path) {

            $Directory = [System.IO.Path]::GetDirectoryName($String)
            $FileName = [System.IO.Path]::GetFileNameWithoutExtension($String)
            $Extension = [System.IO.Path]::GetExtension($String)

            $NewFileName = "$FileName$SuffixSeparator$Suffix$Extension"

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