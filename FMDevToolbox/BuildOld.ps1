#Requires -modules PwshSpectreConsole

using namespace System.Collections.Generic

$script:ModuleRoot             = $PSScriptRoot
$script:ModuleName             = $script:ModuleRoot.Split('\')[-1]
$script:ModulePublic           = "$script:ModuleRoot\Public"
$script:ModuleLib              = "$script:ModuleRoot\Lib"
$script:ModPublicFunctions     = "$script:ModuleRoot\Public\*.ps1"
$script:ModPrivateFunctions    = "$script:ModuleRoot\Private\*.ps1"
$script:ModuleManifest         = "$script:ModuleRoot\$script:ModuleName.psd1"
$script:RepoRoot               = (Resolve-Path -Path "$PSScriptRoot/..").Path
$script:DocsRoot               = (Resolve-Path -Path "$script:RepoRoot/$script:ModuleName.Docs").Path
$script:TestsRoot              = (Resolve-Path -Path "$script:RepoRoot/$script:ModuleName.Tests").Path
$script:ChangelogPath          = "$script:RepoRoot/CHANGELOG.md"
$script:ReadmePath             = "$script:RepoRoot/README.md"
$script:LicensePath            = "$script:RepoRoot/LICENSE.md"

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
            [Parameter(Mandatory, Position=0)]
            [string] $PackageName,
            [string] $InstallPath,
            [string] $SourcePath,
            [string] $TargetFramework = 'net6.0',
            [string] $AssemblyName,
            [int32] $DotnetVersion
        )

        if(-not($DotnetVersion)){ $DotnetVersion = 8 }
        if(-not($AssemblyName)){ $AssemblyName = "$PackageName.dll" }
        if(-not($InstallPath)){ $InstallPath = [System.IO.Path]::Combine($script:ModuleLib, $PackageName, $TargetFramework) }
        if(-not($SourcePath)){ $SourcePath = [System.IO.Path]::Combine($script:ModuleRoot, 'Src', $PackageName) }

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
        [OutputType([String])]
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
    param (
        [Switch] $Public,
        [Switch] $Private,
        [Switch] $Silent
    )

    [PSCustomObject[]] $PublicAliases = @()
    [PSCustomObject[]] $PublicFunctions = @()
    [PSCustomObject[]] $PrivateAliases = @()
    [PSCustomObject[]] $PrivateFunctions = @()

    # Accumulate file path globs to functions based on switches that were set.
    # Only Public and Private for now.
    [string[]] $functionsRootPath = @()
    if($Public -or $Private){
        if($Public){
            $functionsRootPath += $script:ModPublicFunctions
        }
        elseif($Private){
            $functionsRootPath += $script:ModPrivateFunctions
        }
    }
    else {
        Write-Verbose "Neither Public or Private was specified. Defaulting to both."
        $functionsRootPath += $script:ModPublicFunctions
        $functionsRootPath += $script:ModPrivateFunctions
    }

    foreach ($curRoot in $functionsRootPath) {
        Get-ChildItem -Path $curRoot -Recurse -Force -EA 0 | % {
            $obj = [PSCustomObject]@{
                BaseName = $_.BaseName
                FullPath = $_.FullName
                Category = $_.DirectoryName
            }

            $Functions.Value += $obj
            $Alias = Get-Alias -Definition $_.BaseName -EA 0

            Write-Verbose "`$Alias.Name: $Alias.Name"
            Write-Verbose "`$Alias.ResolvedCommand:" $Alias.ResolvedCommand

            if ($Alias) { $Aliases.Value += $Alias.Name }
        }
    }


    # Helper function to process files and collect functions and aliases
    $AccumulateMembers = {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory,Position=0)]
            [string] $FunctionsRoot,
            [ref] $Functions,
            [ref] $Aliases,
            [switch] $Public
        )

        Get-ChildItem -Path $FunctionsRoot -Recurse -Force -EA 0 | % {

            $obj = [PSCustomObject]@{
                BaseName = $_.BaseName
                FullPath = $_.FullName
                Category = $_.DirectoryName
            }

            $Functions.Value += $obj
            $Alias = Get-Alias -Definition $_.BaseName -EA 0

            Write-Verbose "`$Alias.Name: $Alias.Name"
            Write-Verbose "`$Alias.ResolvedCommand:" $Alias.ResolvedCommand

            if ($Alias) { $Aliases.Value += $Alias.Name }
        }
    }



    & $AccumulateMembers -Public
    & $AccumulateMembers -Private

    & $AccumulateMembers "$ModuleRoot\Public\*.ps1" -Functions ([ref]$PublicFunctions) -Aliases ([ref]$PublicAliases)
    $PublicFunctions = $PublicFunctions | Sort-Object
    $PublicAliases   = $PublicAliases   | Sort-Object
    & $AccumulateMembers "$ModuleRoot\Private\*.ps1" -Functions ([ref]$PrivateFunctions) -Aliases ([ref]$PrivateAliases)
    $PrivateFunctions = $PrivateFunctions | Sort-Object
    $PrivateAliases   = $PrivateAliases   | Sort-Object

    if(-not$Silent){
        foreach ($pf in $PublicFunctions)   { Write-SpectreHost "[#697582]Public function added:   [/][#FFFFFF]$pf[/]" }
        foreach ($pa in $PublicAliases)     { Write-SpectreHost "[#697582]Public alias added:      [/][#FFFFFF]$pa[/]" }
        foreach ($prf in $PrivateFunctions) { Write-SpectreHost "[#697582]Private function added:  [/][#FFFFFF]$prf[/]" }
        foreach ($pra in $PrivateAliases)   { Write-SpectreHost "[#697582]Private alias added:     [/][#FFFFFF]$pra[/]" }
    }

    $Export = [PSCustomObject]@{
        AllFunctions     = $PublicFunctions + $PrivateFunctions
        AllAliases       = $PublicAliases + $PrivateAliases
        PublicFunctions  = $PublicFunctions
        PrivateFunctions = $PrivateFunctions
        PublicAliases    = $PublicAliases
        PrivateAliases   = $PrivateAliases
    }
    $Export
}
function Update-FMModule {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [String] $SetPrerelease,
        [Switch] $RemovePrerelease,
        [Version] $SetVersion,
        [String] $ProjectURI  = "https://github.com/futuremotiondev/$script:ModuleName",
        [String] $LicenseURI  = "https://github.com/futuremotiondev/$script:ModuleName/blob/main/LICENSE",
        [String] $IconURI     = "https://github.com/futuremotiondev/$script:ModuleName/blob/main/Assets/Images/ModuleIcon.png",
        [String] $HelpInfoURI = "https://github.com/futuremotiondev/$script:ModuleName/blob/main/README.md",
        [Switch] $RebuildAssemblies,
        [Switch] $UpdateFunctionsAndAliases,
        [Switch] $GenerateFunctionListInDocs,
        [Switch] $Silent
    )

    # Rebuild Assemblies if required
    if($RebuildAssemblies){
        $InternalPackages = @{
            'Futuremotion.FMDevToolbox' = @{
                InstallPath = "Futuremotion.FMDevToolbox\net6.0"
                SourcePath = "$script:ModuleRoot\Src\FMDevToolbox"
                DotnetVersion = 8
            }
        }
        $NuGetPackages = @{
            'Microsoft.Toolkit.Uwp.Notifications' = @{ Version = '7.1.3'; Framework = 'net5.0-windows10.0.17763'; DLLName = $null; }
            'Microsoft.Windows.SDK.NET.Ref' = @{ Version = '10.0.26100.34'; Framework = 'net6.0'; DLLName = 'Microsoft.Windows.SDK.NET.dll'; }
            'Ookii.Dialogs.WinForms' = @{ Version = '4.0.0'; Framework = 'net6.0-windows7.0'; DLLName = $null; }
            'SixLabors.ImageSharp' = @{ Version = '3.1.6'; Framework = 'net6.0'; DLLName = $null; }
        }
        $RequiredAssemblies = Install-ModuleDependencies -NuGet $NuGetPackages -Internal $InternalPackages | Out-Null
        $UpdateSplat['RequiredAssemblies'] = $RequiredAssemblies
    }

    $Manifest = Import-PowerShellDataFile -Path $script:ModuleManifest
    [version] $ExistingVersion = $Manifest.ModuleVersion
    [string] $ExistingPrerelease = $Manifest.PrivateData['PSData'].Prerelease

    if($SetPrerelease -and $RemovePrerelease){
        Write-Error "-SetPrerelease and -RemovePrerelease cannot be used together."
        return
    }

    # Handle Prerelease value
    $RemoveKeyword = '%%%REMOVE%%%%'
    if($SetPrerelease) { $PrereleaseTag = $SetPrerelease }
    elseif($ExistingPrerelease) { $PrereleaseTag = $ExistingPrerelease }
    elseif($RemovePrerelease){ $PrereleaseTag = $RemoveKeyword }
    if([String]::IsNullOrWhiteSpace($PrereleaseTag)){ $PrereleaseTag = $RemoveKeyword }

    # Handle Module Version
    if($SetVersion){ $ModuleVersion = $SetVersion.ToString() }
    elseif($ExistingVersion){ $ModuleVersion = $ExistingVersion.ToString() }
    else{ $ModuleVersion = '1.0.0' }

    if($UpdateFunctionsAndAliases){
        if($Silent){
            $ExportedMembers = Update-ModuleFunctionsAndAliases -Silent
        }
        else {
            $ExportedMembers = Update-ModuleFunctionsAndAliases
        }
        $FunctionsToExport = $ExportedMembers.AllFunctions
        $AliasesToExport = $ExportedMembers.AllAliases
    }

    $UpdateSplat = @{
        Path              = $script:ModuleManifest
        FunctionsToExport = $FunctionsToExport
        AliasesToExport   = $AliasesToExport
        ModuleVersion     = $ModuleVersion
        ProjectUri        = $ProjectURI
        LicenseUri        = $LicenseURI
        IconUri           = $IconURI
        HelpInfoUri       = $HelpInfoURI
        Prerelease        = $PrereleaseTag
    }

    Update-PSModuleManifest @UpdateSplat -Verbose | Out-Null

    if($PrereleaseTag -eq '%%%REMOVE%%%%'){
        $lines = Get-Content -Path $script:ModuleManifest -Raw
        $rePrerelease = "(?m)^(\s*)(Prerelease\s*=\s*)'.*'"
        $updatedLines = $lines -replace $rePrerelease, '${1}# ${2}'''''
        $Encoding = New-Object System.Text.UTF8Encoding $False
        [IO.File]::WriteAllText($script:ModuleManifest, $updatedLines, $Encoding)
    }

    Test-ModuleManifest -Path $script:ModuleManifest
}


Update-FMModule -UpdateFunctionsAndAliases

