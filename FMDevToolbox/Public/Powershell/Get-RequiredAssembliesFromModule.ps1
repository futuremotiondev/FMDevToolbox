function Get-RequiredAssembliesFromModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [String[]] $ModuleName
    )
    begin{}
    process {
        foreach ($name in $ModuleName) {
            $module = Get-Module -ListAvailable $name
            if ($module) {
                $moduleBase = $module.ModuleBase
                $manifestFilename = "$($module.Name).psd1"
                $manifestPath = [System.IO.Path]::Combine($moduleBase, $manifestFilename)
                $manifestData = Import-PowerShellDataFile -Path $manifestPath
                $requiredAssemblies = $manifestData.RequiredAssemblies
                if ($requiredAssemblies) {
                    foreach ($assembly in $requiredAssemblies) {
                        $assemblyFullname = Resolve-Path ([System.IO.Path]::Combine($moduleBase, $assembly))
                        $assemblyLeaf = Split-Path $assemblyFullname -Leaf
                        $assemblyFolder = Split-Path $assemblyFullname
                        [PSCustomObject]@{
                            Module = $module.Name
                            Name = $assemblyLeaf
                            FullName = $assemblyFullname
                            Directory = $assemblyFolder
                        }
                    }
                } else {
                    Write-Host "No required assemblies found for $($module.Name)."
                }
            } else {
                Write-Host "Module '$name' not found."
            }
        }
    }
}