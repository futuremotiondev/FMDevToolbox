[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

$script:ModuleRoot = $PSScriptRoot
$script:ModuleName = $script:ModuleRoot.Split('\')[-1]
$script:ModuleManifest = "$script:ModuleRoot\$script:ModuleName.psd1"

# TODO
# cmd.exe /c 'dir /b /ad /o-n %systemroot%\Microsoft.NET\Framework\v?.*'
# dotnet --list-sdks
# Install-AndBuildCustomLibrary
# function Install-AndBuildCustomLibrary {
#     param (
#         [String] $BuildPath = "D:\Dev\Powershell\FMModulesWorking\FMDevToolbox",
#         [String] $InstallPath,
#         [Int32] $DotnetCLIVersion = 8
#     )
#
#     [Object[]] $CSProjItemCollector = Get-ChildItem -LiteralPath $BuildPath -File -Recurse -Force -Filter "*.csproj"
#     if($CSProjItemCollector.Count -gt 1){
#         Write-Error "Multiple projects are located within the build path. This isn't supported yet."
#     }
#     $CSProjFile = $CSProjItemCollector[0] | Select-Object -ExpandProperty FullName
#     $CSProjFilename = [System.IO.Path]::GetFileName($CSProjFile)
#
#     [xml] $CSProjContents = Get-Content -Path $CSProjFile
#     [String[]] $TargetFrameworks = $CSProjContents.Project.PropertyGroup.TargetFrameworks
#     foreach ($TargetFramework in $TargetFrameworks) {
#     }
# }

function Update-ModuleFunctionsAndAliases {
    [CmdletBinding()]
    param (
        [String] $Manifest = "$script:ModuleManifest",
        [String] $ModuleRoot = "$script:ModuleRoot"
    )

    [String[]] $AliasesToExport = @()
    [String[]] $FunctionsToExport = @()

    $ModuleFunctions = Get-ChildItem -Path "$ModuleRoot\Public\*.ps1" -Recurse
    $ModuleFunctions | % {
        $Alias = Get-Alias -Definition $_.BaseName -ErrorAction SilentlyContinue
        if ($Alias) { $AliasesToExport += $Alias }
        $FunctionsToExport += $_.BaseName
    }
    $MembersToExport = [PSCustomObject][ordered]@{}
    if($FunctionsToExport.Count){
        $FunctionsToExport = $FunctionsToExport | Sort-Object
        $MembersToExport | Add-Member -NotePropertyName 'Functions' -NotePropertyValue $FunctionsToExport
    }
    if($AliasesToExport.Count){
        $AliasesToExport = $AliasesToExport | Sort-Object
        $MembersToExport | Add-Member -NotePropertyName 'Aliases' -NotePropertyValue $AliasesToExport
    }
    if($MembersToExport){
        return $MembersToExport
    }
    else{
        return $null
    }
}

function Install-ModuleDependencies {
    [CmdletBinding()]
    param (
        [String] $InstallPath = "$script:ModuleRoot\Lib"
    )
    begin {
        if(-not(Test-Path -LiteralPath $InstallPath -PathType Container)){
            New-Item $InstallPath -ItemType Directory | Out-Null
        }
        Get-ChildItem -LiteralPath "$script:ModuleRoot\Lib" |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        $RequiredAssemblies = @()
    }
    process {
        function Install-ModulePyVenvPackage {

            $BuildPath = "$script:ModuleRoot\Private\Classes\PythonVenvObject"
            $InstallPath = "$script:ModuleRoot\Lib\FMDevToolbox.PythonVenvObject\net6.0"
            $DotnetVersion = 8

            if(Test-Path $InstallPath -PathType Container){
                Remove-Item -LiteralPath $InstallPath -Recurse -Force -Verbose | Out-Null
            }
            New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
            New-Item -Path $BuildPath -ItemType Directory -Force | Out-Null
            if (-not (Get-Command dotnet -ErrorAction SilentlyContinue) -or
            -not (dotnet --list-sdks | Select-String "^$DotnetVersion.+")) {
                Write-Host "dotnet SDK $DotnetVersion wasn't found. Please install it."
                Write-Host "Run 'winget install Microsoft.DotNet.SDK.$DotnetVersion' in an admin console."
                return
            }
            try {
                Push-Location -Path $BuildPath
                & dotnet build -c Release -o $InstallPath | Out-Null
            }
            catch {
                Remove-Item -LiteralPath "$BuildPath\obj" -Recurse -Force | Out-Null
                Pop-Location
                Write-Error "A problem occurred installing PythonVenvObject. ($_)"
            }
            Remove-Item -LiteralPath "$BuildPath\obj" -Recurse -Force | Out-Null
            Pop-Location
            return [System.IO.Path]::Combine($InstallPath, 'FMDevToolbox.PythonVenvObject.dll')
        }

        function Install-ModuleNugetPackage {
            param (
                [string] $InstallPath,
                [string] $PackageName,
                [string] $Version,
                [string] $Framework,
                [string] $DLLName
            )

            $LibPath = Join-Path $InstallPath "$PackageName.$Version"
            New-Item -Path $LibPath -ItemType Directory -Force | Out-Null

            $TempDir = [System.IO.Directory]::CreateTempSubdirectory()
            $DownloadPath = Join-Path $TempDir "download.zip"

            try {
                Invoke-WebRequest "https://www.nuget.org/api/v2/package/$PackageName/$Version" -OutFile $DownloadPath -UseBasicParsing
                Expand-Archive $DownloadPath $TempDir -Force
                Remove-Item $DownloadPath

                $Dir = Get-ChildItem -LiteralPath $TempDir -Include $Framework -Directory -Recurse |
                    Select-Object -ExpandProperty FullName
                Move-Item -Path $Dir -Destination $LibPath -Force
                Remove-Item -LiteralPath $TempDir -Recurse -Force | Out-Null
                if($DLLName){ return [System.IO.Path]::Combine($LibPath, $Framework, $DLLName) }
                else{ return [System.IO.Path]::Combine($LibPath, $Framework, "$PackageName.dll") }
            }
            finally {
                Remove-Item -LiteralPath $TempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        $Packages = @{
            'Microsoft.Toolkit.Uwp.Notifications' = @{ Version = '7.1.3'; Framework = 'net5.0-windows10.0.17763'; DLLName = $null; }
            'Microsoft.Windows.SDK.NET.Ref' = @{ Version = '10.0.26100.34'; Framework = 'net6.0'; DLLName = 'Microsoft.Windows.SDK.NET.dll'; }
            'Ookii.Dialogs.WinForms' = @{ Version = '4.0.0'; Framework = 'net6.0-windows7.0'; DLLName = $null; }
        }
        # Install each package
        foreach ($package in $packages.GetEnumerator()) {
            $params = @{
                InstallPath = $InstallPath
                PackageName = $package.Key
                Version     = $package.Value.Version
                Framework   = $package.Value.Framework
                DLLName     = $package.Value.DLLName
            }
            $RequiredAssemblies += Install-ModuleNugetPackage @params
        }

        $RequiredAssemblies += Install-ModulePyVenvPackage
        $RequiredAssemblies = $RequiredAssemblies | Sort-Object

        # Create relative paths
        $RequiredAssemblies = $RequiredAssemblies | % {
            $_.Replace($script:ModuleRoot, '.')
        }
        return $RequiredAssemblies
    }
}

$ToExport = Update-ModuleFunctionsAndAliases
$FunctionsToExport = $ToExport.Functions
$AliasesToExport = $ToExport.Aliases
$RequiredAssemblies = Install-ModuleDependencies
$ModuleVersion = "1.0.2"
$ReleaseNotes = '# 1.0.2 (11-18-2024)

* Fix: Wrong assemblies being loaded breaking toast notifications.
* More to author.

# 1.0.1 (11-14-2024)

Fixed errors in module packaging and pruned obsolete functions.

# 1.0.0 (11-10-2024)

Created Module.
'

$UpdateSplat = @{
    Path = $script:ModuleManifest
    FunctionsToExport = $FunctionsToExport
    AliasesToExport = $AliasesToExport
    ModuleVersion = $ModuleVersion
    RequiredAssemblies = $RequiredAssemblies
    ReleaseNotes = $ReleaseNotes
}
Update-PSModuleManifest @UpdateSplat -Verbose
Test-ModuleManifest -Path $script:ModuleManifest