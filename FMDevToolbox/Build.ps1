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
$script:RepoRoot = (Resolve-Path -Path "$PSScriptRoot/..").Path
$script:DocsRoot = (Resolve-Path -Path "$script:RepoRoot/$script:ModuleName.Docs").Path
$script:TestsRoot = (Resolve-Path -Path "$script:RepoRoot/$script:ModuleName.Tests").Path
$script:ChangelogPath = "$script:RepoRoot/CHANGELOG.md"

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
    param(
        [Switch] $UpdateMarkdownList,
        [Switch] $ClearListBeforeUpdate
    )
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
function Save-FunctionMarkdownList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Version
    )
    $OutputFile = "$script:DocsRoot\Generated\FunctionList.md"
    Remove-Item -LiteralPath $OutputFile -Force -ErrorAction SilentlyContinue | Out-Null
    New-Item -Path $OutputFile -ItemType File -Force | Out-Null

    $Header = "# $script:ModuleName ($Version) Complete Function List`r`n`r`n"
    $Header = $Header -replace "\s{2,}", " "
    Add-Content -Path $OutputFile -Value $Header

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
function Step-Version {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [Version] $Version,
        [Parameter(Position=1)]
        [ValidateSet("Major", "Minor", "Build")]
        [String] $By = "Build"
    )
    process {
        if(-not[String]::IsNullOrEmpty($Version)){
            $major = $Version.Major; $minor = $Version.Minor; $build = $Version.Build;
            switch ($By) {
                "Major" { $major++; $minor = 0; $build = 0; break; }
                "Minor" { $minor++; $build = 0; break; }
                default { $build++; break; }
            }
            return [Version]::new($major, $minor, $build).ToString()
        }
    }
}

function Step-Prerelease {
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [String] $Version,
        [Switch] $Reset,
        [Switch] $Remove
    )

    process {
        if($Reset){ return "prerelease-001" }
        if($Remove) { return $null }
        $reMatch = ([regex]'^(?<tag>prerelease\-)(?<version>\d+)$').Match($Version)
        if($reMatch.Success){
            $Prefix = $reMatch.Groups['tag'].Value
            $Version = $reMatch.Groups['version'].Value
            $VersionLength = $Version.Length
            $VersionInt = $Version -as [Int32]
            $NewString = "{0}{1:D$VersionLength}" -f $Prefix, ($VersionInt + 1)
            return $NewString
        }
        else {
            Write-Error "Unable to step prerelease. ($Version)"
            return $Version
        }
    }
}

function Update-Module {
    param (
        [Switch] $UpdateFunctionsAndAliases,
        [Switch] $StepPrerelease,
        [String] $SetPrerelease,
        [ValidateSet("None", "Major", "Minor", "Build")]
        [String] $StepVersion = "None",
        [Switch] $RemovePrerelease,
        [String] $ProjectURI  = "https://github.com/futuremotiondev/$script:ModuleName",
        [String] $LicenseURI  = "https://github.com/futuremotiondev/$script:ModuleName/blob/main/LICENSE",
        [String] $IconURI     = "https://github.com/futuremotiondev/$script:ModuleName/blob/main/Assets/Images/ModuleIcon.png",
        [String] $HelpInfoURI = "https://github.com/futuremotiondev/$script:ModuleName/blob/main/README.md",
        [Hashtable[]] $ChangelogData,
        [Switch] $RebuildAssemblies
    )

    $Manifest = Import-PowerShellDataFile -Path $script:ModuleManifest
    $ExistingVersion = $Manifest.ModuleVersion
    $ExistingPrerelease = $Manifest.PrivateData['PSData'].Prerelease

    if($UpdateFunctionsAndAliases){

        $ExportedMembers = Update-ModuleFunctionsAndAliases
        $FunctionsToExport = $ExportedMembers.Functions
        $AliasesToExport = $ExportedMembers.Aliases
        $NewFunctions = $ExportedMembers.Functions
        $NewAliases = $ExportedMembers.Aliases
    }


    if($ExistingPrerelease){
        $PrereleaseTag = $ExistingPrerelease
    }
    if($StepVersion -ne "None"){
        $ModuleVersion = Step-Version -Version $ExistingVersion -By $StepVersion
        $PrereleaseTag = '%%%REMOVE%%%%'
    }
    if($StepPrerelease){
        $PrereleaseTag = Step-Prerelease -Version $ExistingPrerelease
    }
    if($RemovePrerelease){
        $PrereleaseTag = '%%%REMOVE%%%%'
    }
    if($SetPrerelease){
        $PrereleaseTag = $SetPrerelease
    }

    # Update Module Manifest
    $UpdateSplat = @{
        Path = $script:ModuleManifest
        FunctionsToExport = $FunctionsToExport
        AliasesToExport = $AliasesToExport
        ModuleVersion = $ModuleVersion
        ProjectUri = $ProjectURI
        LicenseUri = $LicenseURI
        IconUri = $IconURI
        HelpInfoUri = $HelpInfoURI
    }

    if(-not[String]::IsNullOrWhiteSpace($PrereleaseTag)){
        $UpdateSplat['Prerelease'] = $PrereleaseTag
    }

    # Rebuild Assemblies if required
    if($RebuildAssemblies){
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
        $RequiredAssemblies = Install-ModuleDependencies -NuGet $NuGetPackages -Internal $InternalPackages | Out-Null
        $UpdateSplat['RequiredAssemblies'] = $RequiredAssemblies
    }


    Update-PSModuleManifest @UpdateSplat -Verbose | Out-Null

    if($PrereleaseTag -eq '%%%REMOVE%%%%'){
        $lines = Get-Content -Path $script:ModuleManifest -Raw
        $rePrerelease = "(?m)^(\s*)(Prerelease\s*=\s*)'.*'"
        $updatedLines = $lines -replace $rePrerelease, '${1}# ${2}'''''
        # Set-Content -LiteralPath $script:ModuleManifest
        $Encoding = New-Object System.Text.UTF8Encoding $False
        [IO.File]::WriteAllText($script:ModuleManifest, $updatedLines, $Encoding)
    }

    Test-ModuleManifest -Path $script:ModuleManifest
    Save-FunctionMarkdownList -Version "$ModuleVersion $PrereleaseTag"
}

Update-Module -UpdateFunctionsAndAliases -SetPrerelease "prerelease-006"

