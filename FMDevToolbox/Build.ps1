[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

$script:ModuleRoot = $PSScriptRoot
$script:ModuleName = $script:ModuleRoot.Split('\')[-1]
$script:ModulePublic = "$script:ModuleRoot\Public"
$script:ModuleLib = "$script:ModuleRoot\Lib"
$script:ModuleClasses = "$script:ModuleRoot\Private\Classes"
$script:ModuleManifest = "$script:ModuleRoot\$script:ModuleName.psd1"
$script:DocsRoot = (Resolve-Path -Path "$PSScriptRoot/../$script:ModuleName.Docs").Path
$script:TestsRoot = (Resolve-Path -Path "$PSScriptRoot/../$script:ModuleName.Tests").Path
$script:OutputDir = (Resolve-Path -Path "$PSScriptRoot/../../../Modules").Path

function Install-ModuleDependencies {
    [CmdletBinding()]
    param (
        [String] $InstallPath = "$script:ModuleLib",
        [Hashtable] $NuGet,
        [Hashtable] $Internal
    )

    if(($NuGet.Count -eq 0) -and ($Internal.Count -eq 0)){
        Write-Warning "No packages to install."
        return
    }

    New-Item $InstallPath -ItemType Directory -Force | Out-Null
    $RequiredAssemblies = @()

    function InstallInternalPackage {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory, Position=0)] $PackageName,
            [string] $InstallPath,
            [string] $SourcePath,
            [string] $TargetFramework = 'net6.0',
            [string] $AssemblyName,
            [int32] $DotnetVersion
        )

        if(-not($DotnetVersion)){ $DotnetVersion = 8 }
        if(-not($AssemblyName)){ $AssemblyName = "$PackageName.dll" }
        if(-not($InstallPath)){ $InstallPath = (Join-Path $script:ModuleLib $PackageName $TargetFramework) }
        if(-not($SourcePath)){ $SourcePath = (Join-Path $script:ModuleClasses $PackageName) }

        $PreviousPath = Join-Path $script:ModuleLib $PackageName
        Remove-Item $PreviousPath -Recurse -Force -EA SilentlyContinue

        # Ensure directories exist
        foreach ($Path in @($InstallPath, $SourcePath)) {
            $null = New-Item -Path $Path -ItemType Directory -Force -EA SilentlyContinue
        }

        # Check for dotnet SDK
        if (-not (Get-Command dotnet -EA SilentlyContinue) -or
            -not (dotnet --list-sdks | Select-String "^$DotnetVersion\.")) {
            Write-Host "dotnet SDK $DotnetVersion wasn't found. Please install it."
            Write-Host "Run 'winget install Microsoft.DotNet.SDK.$DotnetVersion' in an admin console."
            return
        }

        try {
            Push-Location -Path $SourcePath
            $null = & dotnet build -c Release -o $InstallPath
            return [System.IO.Path]::Combine($InstallPath, $AssemblyName)
        }
        catch {
            Write-Error "A problem occurred building $PackageName. ($_)"
        }
        finally {
            Remove-Item "$SourcePath\obj" -Recurse -Force -ea SilentlyContinue
            Pop-Location
        }
    }

    function InstallNugetPackage {
        [CmdletBinding()]
        param (
            [string] $InstallPath,
            [string] $PackageName,
            [string] $Version,
            [string] $Framework,
            [string] $DLLName
        )

        if(-not$DLLName){ $DLLName = "$PackageName.dll" }

        $InstallPath = Join-Path $InstallPath -ChildPath "$PackageName.$Version"
        Remove-Item $InstallPath -Recurse -Force -EA SilentlyContinue | Out-Null
        New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null

        $TempDir = [System.IO.Directory]::CreateTempSubdirectory().FullName
        $DownloadPath = Join-Path $TempDir "download.zip"

        try {
            Invoke-WebRequest "https://www.nuget.org/api/v2/package/$PackageName/$Version" -OutFile $DownloadPath -UseBasicParsing
            Expand-Archive $DownloadPath -DestinationPath $TempDir -Force
            Remove-Item $DownloadPath
            $Dir = Get-ChildItem -LiteralPath $TempDir -Include $Framework -Directory -Recurse | % { $_.FullName }
            Move-Item -LiteralPath $Dir -Destination $InstallPath -Force
            return [System.IO.Path]::Combine($InstallPath, $Framework, $DLLName)
        }
        catch {
            Write-Error "An error occurred retrieving $PackageName v$Version. Details: $_"
        }
        finally {
            Remove-Item -LiteralPath $TempDir -Recurse -Force -EA SilentlyContinue
        }
    }

    if($NuGet.Count -gt 0){
        foreach ($Package in $NuGet.GetEnumerator()) {
            $Params = @{
                InstallPath = $InstallPath
                PackageName = $Package.Key
                Version     = $Package.Value.Version
                Framework   = $Package.Value.Framework
                DLLName     = $Package.Value.DLLName
            }

            $RequiredAssemblies += InstallNugetPackage @Params
        }
    }

    if($Internal.Count -gt 0){
        foreach ($Library in $Internal.GetEnumerator()) {
            $Params = @{
                PackageName   = $Library.Key
                InstallPath   = Join-Path $InstallPath -ChildPath ($Library.Value.InstallPath)
                SourcePath    = $Library.Value.SourcePath
                DotnetVersion = $Library.DotnetVersion
                AssemblyName  = $Library.AssemblyName
            }
            $RequiredAssemblies += InstallInternalPackage @Params
        }
    }

    # Create Relative Paths
    $RequiredAssemblies = $RequiredAssemblies | % {
        $_.Replace($script:ModuleRoot, '.')
    }
    return $RequiredAssemblies | Sort-Object

}

function Update-ModuleFunctionsAndAliases {
    [CmdletBinding()]

    $Manifest = Import-PowerShellDataFile -Path $script:ModuleManifest
    $ExistingFunctions = $Manifest.FunctionsToExport -as [System.Collections.Generic.List[String]]
    $ExistingAliases = $Manifest.AliasesToExport -as [System.Collections.Generic.List[String]]

    # Retrieve module functions
    $RetrievedAliases = [System.Collections.Generic.List[String]]@()
    $RetrievedFunctions = [System.Collections.Generic.List[String]]@()
    Get-ChildItem -Path "$ModuleRoot\Public\*.ps1" -Recurse | % {
        $RetrievedFunctions.Add($_.BaseName) | Out-Null
        $Alias = Get-Alias -Definition $_.BaseName -ErrorAction SilentlyContinue
        if ($Alias) { $RetrievedAliases.Add($Alias.Name) | Out-Null }
    }

    # Determine new functions and aliases
    $NewFunctions = $RetrievedFunctions | % { if( $_ -notin $ExistingFunctions ){ $_ } }
    $NewAliases = $RetrievedAliases | % { if( $_ -notin $ExistingAliases ){ $_ } }

    # Create a hashtable for members to export
    $Export = @{}

    if ($RetrievedFunctions.Count -gt 0) {
        $Export['Functions'] = $RetrievedFunctions -as [Array] | Sort-Object
    }
    if ($RetrievedAliases.Count -gt 0) {
        $Export['Aliases'] = $RetrievedAliases -as [Array] | Sort-Object
    }
    if ($NewFunctions.Count -gt 0) {
        $Export['NewFunctions'] = $NewFunctions | Sort-Object
    }
    if ($NewAliases.Count -gt 0) {
        $Export['NewAliases'] = $NewAliases | Sort-Object
    }
    return [PSCustomObject] $Export
}
function Initialize-ModuleManifest {
    $ExportedMembers = Update-ModuleFunctionsAndAliases
    [String] $GUID = 'ee9012b6-e539-593b-852b-1c68e2f9af70'
    [Version] $ModuleVersion = '1.0.0'
    [Version] $PowershellVersion = "7.1"
    [String] $Path = $script:ModuleManifest
    [String] $RootModule = $script:ModuleName
    [String] $Author = "Futuremotion"
    [String] $CompanyName = "Futuremotion"
    [String] $Copyright = '© Futuremotion. All rights reserved.'
    [String] $Description = ""
    [String[]] $Tags = @()
    [String] $LicenseUri = "https://github.com/futuremotiondev/$script:ModuleName/blob/main/LICENSE"
    [String] $ProjectUri = "https://github.com/futuremotiondev/$script:ModuleName"
    [String] $IconUri = "https://github.com/futuremotiondev/$script:ModuleName/blob/main/Assets/Images/ModuleIcon.png"
    [String] $ReleaseNotes = "1.0.0: (11-14-2024) - Created Module."
    [String[]] $CmdletsToExport = @()
    [String[]] $VariablesToExport = @('*')
    [Object[]] $RequiredModules = @(
        @{
            ModuleName='PwshSpectreConsole'
            ModuleVersion='2.1.1'
        }
    )
    [String[]] $RequiredAssemblies = @()
    [String[]] $CompatiblePSEditions = @("Core")
    [String[]] $ScriptsToProcess = @()
    [String[]] $TypesToProcess = @()
    [String[]] $FormatsToProcess = @()
    [String[]] $FunctionsToExport = $ExportedMembers.Functions
    [String[]] $AliasesToExport = $ExportedMembers.Aliases

    $newModuleManifestSplat = @{
        Path                 = $Path
        Guid                 = $GUID
        ModuleVersion        = $ModuleVersion
        PowerShellVersion    = $PowershellVersion
        RootModule           = $RootModule
        Author               = $Author
        CompanyName          = $CompanyName
        Copyright            = $Copyright
        Description          = $Description
        Tags                 = $Tags
        LicenseUri           = $LicenseUri
        ProjectUri           = $ProjectUri
        IconUri              = $IconUri
        ReleaseNotes         = $ReleaseNotes
        CmdletsToExport      = $CmdletsToExport
        VariablesToExport    = $VariablesToExport
        RequiredModules      = $RequiredModules
        RequiredAssemblies   = $RequiredAssemblies
        CompatiblePSEditions = $CompatiblePSEditions
        ScriptsToProcess     = $ScriptsToProcess
        TypesToProcess       = $TypesToProcess
        FormatsToProcess     = $FormatsToProcess
        FunctionsToExport    = $FunctionsToExport
        AliasesToExport      = $AliasesToExport
        Verbose              = $true
    }

    New-ModuleManifest @newModuleManifestSplat
}
function Save-FunctionMarkdownList {
    $OutputFile = "$script:DocsRoot\Generated\FunctionList.md"
    Remove-Item -LiteralPath $OutputFile -Force -ErrorAction SilentlyContinue | Out-Null
    New-Item -Path $OutputFile -ItemType File -Force | Out-Null

    $Directories = Get-ChildItem -Path "$script:ModulePublic\*" -Directory | % { $_.FullName }
    foreach ($Dir in $Directories) {
        $Dirname = [System.IO.Path]::GetFileName($Dir)
        Add-Content -Path $OutputFile -Value "#### $Dirname"
        Add-Content -Path $OutputFile -Value "`n``````"

        Get-ChildItem -Path "$Dir\*.ps1" -Recurse | % { $_.BaseName } |
            Sort-Object | % { Add-Content -Path $OutputFile -Value $_ }

        Add-Content -Path $OutputFile -Value "```````n"
    }
}
function BuildToOutput {
    $Built = Join-Path $script:OutputDir -ChildPath $script:ModuleName
    Remove-Item -LiteralPath $Built -Force -Recurse -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath $script:ModuleRoot -Destination $script:OutputDir -Exclude "Build.ps1" -Force -Recurse
}

function UpdateModule {
    $InternalPackages = @{
        'Futuremotion.FMDevToolbox' = @{
            InstallPath = "Futuremotion.FMDevToolbox\net6.0"
            SourcePath = "$script:ModuleRoot\Private\Classes\Futuremotion.FMDevToolbox"
            DotnetVersion = 8
        }
    }
    $NuGetPackages = @{
        'Microsoft.Toolkit.Uwp.Notifications' = @{ Version = '7.1.3'; Framework = 'net5.0-windows10.0.17763'; DLLName = $null; }
        'Microsoft.Windows.SDK.NET.Ref' = @{ Version = '10.0.26100.34'; Framework = 'net6.0'; DLLName = 'Microsoft.Windows.SDK.NET.dll'; }
        'Ookii.Dialogs.WinForms' = @{ Version = '4.0.0'; Framework = 'net6.0-windows7.0'; DLLName = $null; }
    }

    $RequiredAssemblies = Install-ModuleDependencies -NuGet $NuGetPackages -Internal $InternalPackages
    $ExportedMembers = Update-ModuleFunctionsAndAliases
    $FunctionsToExport = $ExportedMembers.Functions
    $AliasesToExport = $ExportedMembers.Aliases
    $ModuleVersion = "1.0.2"
    $PrereleaseTag = 'prerelease-001'

    $UpdateSplat = @{
        Path = $script:ModuleManifest
        FunctionsToExport = $FunctionsToExport
        AliasesToExport = $AliasesToExport
        ModuleVersion = $ModuleVersion
        Prerelease = $PrereleaseTag
        RequiredAssemblies = $RequiredAssemblies
    }
    Update-PSModuleManifest @UpdateSplat -Verbose
    Test-ModuleManifest -Path $script:ModuleManifest
    Save-FunctionMarkdownList
    BuildToOutput
}

UpdateModule