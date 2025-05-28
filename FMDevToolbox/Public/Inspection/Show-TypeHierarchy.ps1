using namespace System.Text.RegularExpressions
using namespace System.Collections.Concurrent

function Show-TypeHierarchy {
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [object[]] $Objects
    )

    begin {
        $objectsToInspect = @()
    }

    process {
        foreach ($obj in $Objects) {
            if($obj){
                $null = $objectsToInspect += $obj
            }
        }
    }

    end {

        foreach ($obj in $objectsToInspect) {

            # Start with the object's type
            $currentType = $obj.GetType()
            $hierarchy = @()

            # Traverse up the inheritance chain
            while ($currentType) {
                # Use UnderlyingSystemType for a cleaner representation of generic types
                $typeName = $currentType.UnderlyingSystemType.ToString()
                $hierarchy += $typeName
                $currentType = $currentType.BaseType
            }

            $finOutput = [System.Text.StringBuilder]::new()

            for ($ndx = 0; $ndx -lt $hierarchy.Count; $ndx++) {
                $typedef = $hierarchy[$ndx]
                if ($ndx -eq 0) {
                    if($typedef -like "System.Collections.Concurrent.ConcurrentDictionary*"){
                        $typedef = Format-TypeConcurrentDictionary -InputString $typedef -FormatStyle FullSimplified
                    }
                    $null = $finOutput.AppendLine(" `n[#D0D4DF] ➔ $(Get-SpectreEscapedText -Text $typedef)[/]")
                    continue
                } else {
                    $lSpaces = "   " * ($ndx - 1)
                    if($ndx -eq 1){
                        $str = "{0}{1}{2}" -f $lSpaces, "  └─ ", $typedef
                    }
                    else {
                        $str = "{0}{1}{2}" -f $lSpaces, " └─ ", $typedef
                    }

                    $str = Get-SpectreEscapedText -Text $str
                    $null = $finOutput.Append(" [#9CA6AF]$str[/]`n")
                }
            }

            Write-SpectreHost "[#B1BAC8]↪️  Type inspection:[/]"
            Format-SpectrePanel -Data ($finOutput.ToString()) -Expand -Border Rounded -Color "#495361" -Header "Type Inspection"
        }
    }
}

