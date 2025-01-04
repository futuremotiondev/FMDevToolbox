function Get-NodeGlobalModules {
    [CmdletBinding()]
    param(
        [String] $GlobalModuleDirectory
    )
    if(-not(Test-Path -LiteralPath $GlobalModuleDirectory -PathType Container)){
        Write-Error "Global module directory doesn't exist. ($GlobalModuleDirectory)"
        return
    }

    $globalModuleDirectoryFolders = Get-ChildItem -LiteralPath $GlobalModuleDirectory -Directory -Recurse -Depth 0 -Force |
        Select-Object -ExpandProperty FullName

    foreach ($moduleDir in $globalModuleDirectoryFolders) {
        $moduleDirBase = [System.IO.Path]::GetFileName($moduleDir)
        Write-Verbose "Found installed global module: $moduleDirBase"
        $moduleIsScoped = $false
        if($moduleDirBase.StartsWith('@')){
            $moduleIsScoped = $true
            $scopedModuleDir = Get-ChildItem -LiteralPath $moduleDir -Directory -Depth 0 | % {$_.FullName}
            Write-Verbose "Module ($moduleDirBase) is @scoped. Root module directory is $scopedModuleDir"
        }
        if($moduleIsScoped){
            $jsonFilePath = Get-ChildItem -LiteralPath $scopedModuleDir -Include 'package.json' | % {$_.FullName}
        }
        else {
            $jsonFilePath = Get-ChildItem -LiteralPath $moduleDir -Include 'package.json' | % {$_.FullName}
        }
        Write-Verbose "Global Module $moduleDirBase package.json found at $jsonFilePath"
        $jsonData = Get-Content $jsonFilePath | ConvertFrom-Json
        $globalModuleName = $jsonData.name
        $globalModuleVersion = $jsonData.version
        $globalModuleFormattedString = "$globalModuleName@$globalModuleVersion"
        $globalModuleURL = "https://www.npmjs.com/package/$globalModuleName"
        [PSCustomObject]@{
            ModuleName    = $globalModuleName
            ModuleVersion = $globalModuleVersion
            ModuleID      = $globalModuleFormattedString
            ModuleLink    = $globalModuleURL
        }
    }
}