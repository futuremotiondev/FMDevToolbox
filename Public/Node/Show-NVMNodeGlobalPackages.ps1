using module "..\..\Private\Completions\Completers.psm1"
function Show-NVMNodeGlobalPackages {
    [CmdletBinding()]
    param (
        [CompletionsNodeVersions()]
        [String[]] $Versions = 'All',
        [ValidateSet('TableCombined','TableSeparated','SpectreTable','JSON','List','Object')]
        [String] $OutputFormat='SpectreTable',
        [Int32] $TableWidth = $Host.UI.RawUI.WindowSize.Width - 1,
        [Switch] $ShowHeader = $false,
        [Switch] $ClearScreen,
        [String] $PackageTextColor = "#75B5AA",
        [String] $TableBorderColor = "#63636a",
        [String] $HeaderColor = "#FFFFFF"
    )

    begin {

        if ($ClearScreen) { Clear-Host }
        $NodeVersionsObject = Get-NodeInstalledVersionsNVM
        $ModuleCollection = [System.Collections.Generic.List[PSCustomObject]]@()
        $VersionObj = [PSCustomObject]@{}
        $ListString = ""
    }

    process {

        foreach ($VersionObject in $NodeVersionsObject) {

            if ($Versions -ne 'All' -and $Versions -notcontains $VersionObject.Version) {
                continue
            }

            $NodeVersion = $VersionObject.Version
            $GlobalModules = $VersionObject.GlobalModules

            switch ($OutputFormat) {

                'SpectreTable' {
                    $SpectreTablePackagesArray = $GlobalModules | ForEach-Object {
                        "[$PackageTextColor]$($_.ModuleID)[/]`n"
                    }
                    $SpectreTablePackagesString = -join $SpectreTablePackagesArray
                    $VersionObj | Add-Member -NotePropertyName $NodeVersion -NotePropertyValue $SpectreTablePackagesString.TrimEnd("`r", "`n") | Out-Null
                }
                {$_ -in "TableCombined", "TableSeparated", "Object"} {
                    $GlobalModules | ForEach-Object {
                        $ModuleCollection.Add([PSCustomObject]@{
                            NodeVersion = $NodeVersion
                            ModuleID = $_.ModuleID
                            ModuleName = $_.ModuleName
                            ModuleVersion = $_.ModuleVersion
                            ModuleLink = $_.ModuleLink
                        })
                    }
                }
                'JSON' {
                    $JSONPackagesArray = $GlobalModules | ForEach-Object { $_.ModuleID }
                    $VersionObj | Add-Member -NotePropertyName $NodeVersion -NotePropertyValue $JSONPackagesArray | Out-Null
                }
                'List' {

                    $ListPackagesArray = $GlobalModules | ForEach-Object {
                        "$($_.ModuleID)`n"
                    }
                    $ListPackagesString = -join $ListPackagesArray
                    $ListString += "`nNode Version: $NodeVersion`n─────────────────────────────`n$ListPackagesString`n"
                }
            }
        }

        # Output the data based on the output format.
        switch ($OutputFormat) {
            'List' {
                $ListString.TrimEnd("`r", "`n")
            }
            'SpectreTable' {
                if ($ShowHeader) {
                    Write-Host ''
                    Write-SpectreHost -Message "[$HeaderColor]Currently installed global packages:[/]"
                }
                Format-SpectreTable -Data $VersionObj -Border Rounded -Color $TableBorderColor -AllowMarkup -Width $TableWidth
            }
            'TableCombined' {
                if ($ShowHeader) {
                    Write-Host ''
                    Write-SpectreHost -Message "[$HeaderColor]Currently installed global packages:[/]"
                    Show-HorizontalLineInConsole -ForeColor "#676767"
                }
                $ModuleCollection | Format-Table -Property NodeVersion, ModuleName, ModuleVersion, ModuleID
            }
            'TableSeparated' {
                $ModuleCollection | Group-Object -Property NodeVersion | ForEach-Object {
                    Write-SpectreHost "`n[white]Node [/][Green]v$($_.Name)[/]"
                    $_.Group | Format-Table -Property ModuleName, ModuleVersion, ModuleID
                }
            }
            'JSON' {
                $VersionObj | ConvertTo-Json
            }
            'Object' {
                $ModuleCollection
            }
        }
    }
}

