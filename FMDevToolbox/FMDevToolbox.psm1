foreach ($Directory in @('Private', 'Public')) {
    Get-ChildItem -Path "$PSScriptRoot\$Directory\*.ps1" -Recurse | ForEach-Object {
        try { . $_.FullName }
        catch { Write-Error -Message "Failed to import Private function from $($Import.FullName): $_" }
    }
}
if(-not$script:ModuleRoot){
    $script:ModuleRoot = $PSScriptRoot
}
if (-not $script:InstalledPythonVersions) {
    $script:InstalledPythonVersions = Get-PythonInstallations -SuppressFreeThreaded
}
if(-not $script:PrettierConfig) {
    $script:PrettierConfig = "$PSScriptRoot\Data\Prettier\prettierrc.json"
}

