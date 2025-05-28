using namespace System.Management.Automation
using namespace System.Collections.Concurrent

function Expand-ObjectPropertiesAndTypeInfo {
    [CmdletBinding()]
    param (
        [Parameter( Mandatory,
                    Position=0,
                    ValueFromPipeline,
                    ValueFromPipelineByPropertyName,
                    ValueFromRemainingArguments
        )]
        [ValidateNotNullOrEmpty()]
        [Object[]] $InputObjects
    )
    process {
        foreach ($arg in $InputObjects) {
            Write-SpectreHost "`n[#C5C8D2]Inspecting [#FFFFFF]$(Get-SpectreEscapedText -Text $arg)[/][/]`n"
            Show-TypeHierarchy $arg
            Write-SpectreHost "[#9AA0B1]$(Get-SpectreEscapedText -Text "`nInspecting Properties of '$arg':")[/]"
            $arg | Select-Object -Property *
        }
    }
}

New-Alias -Name Inspect-Object -Value Expand-ObjectPropertiesAndTypeInfo