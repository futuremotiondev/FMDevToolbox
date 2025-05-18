function Expand-EnumDefinition {
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [String[]] $EnumName
    )
    begin {}
    process {
        foreach ($enum in $EnumName) {
            [Enum]::GetValues($enum) | % {
                [PSCustomObject]@{
                    Name = $_
                    Value = $_.value__
                }
            }
        }
    }
}