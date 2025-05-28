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


Import-Module -Name $script:ModuleManifest -Force

function Update-ModuleFunctionsAndAliases {
    [CmdletBinding()]
    param (
        [Switch] $Public,
        [Switch] $Private,
        [Switch] $Silent
    )

    [string[]] $functionsToAdd = @()
    $NothingPassed = (-not $Public -and -not $Private)
    if($NothingPassed) {
        Write-Verbose "Neither Public or Private was specified. Defaulting to both."
    }
    if($Public -or $NothingPassed){
        $functionsToAdd += "$script:ModuleRoot\Public\*.ps1"
    }
    if($Private -or $NothingPassed){
        $functionsToAdd += "$script:ModuleRoot\Private\*.ps1"
    }

    [Object[]] $PublicAliases = @()
    [String[]] $PublicAliasNames = @()
    [Object[]] $PrivateAliases = @()
    [String[]] $PrivateAliasNames = @()
    [Object[]] $PublicFunctions = @()
    [String[]] $PublicFunctionNames = @()
    [Object[]] $PrivateFunctions = @()
    [String[]] $PrivateFunctionNames = @()

    :PathLoop foreach ($rootPath in $functionsToAdd) {
        $rootFiles = Get-ChildItem -Path $rootPath -Recurse -File -Force -EA 0
        foreach ($rootFile in $rootFiles) {
            if($rootPath -eq "$script:ModuleRoot\Public\*.ps1"){
                $isPublic = $true
            }
            else {
                $isPublic = $false
            }

            $curFileBase = $rootFile.BaseName
            $curFileFull = $rootFile.FullName
            $curFileDir  = $rootFile.DirectoryName

            if($curFileBase -and $curFileFull -and $curFileDir){
                $fObj = [PSCustomObject]@{
                    BaseName = $curFileBase
                    FullPath = $curFileFull
                    Category = $curFileDir
                }
                if($isPublic){
                    $PublicFunctionNames += $curFileBase
                    $PublicFunctions += $fObj
                }
                else {
                    $PrivateFunctionNames += $curFileBase
                    $PrivateFunctions += $fObj
                }
            }

            $aliasObj = Get-Alias -Definition $curFileBase -EA 0
            $aliasCmd = $aliasObj.ResolvedCommandName
            if(-not $aliasCmd){
                $aliasCmd = $aliasObj.ReferencedCommand.Name
                if(-not $aliasCmd){
                    $aliasCmd = $aliasObj.ResolvedCommand.Name
                }
            }
            if($aliasObj){
                $aObj = [PSCustomObject]@{
                    AliasName = $aliasObj.Name
                    AliasCommand = $aliasCmd
                }
                if($isPublic){
                    $PublicAliasNames += $aliasObj.Name
                    $PublicAliases += $aObj
                }
                else {
                    $PrivateAliasesNames += $aliasObj.Name
                    $PrivateAliases += $aObj
                }
            }
        }
    }

    $PublicFunctionNames   = $PublicFunctionNames   | Sort-Object
    $PrivateFunctionNames  = $PrivateFunctionNames  | Sort-Object
    $PublicAliasNames      = $PublicAliasNames      | Sort-Object
    $PrivateAliasNames     = $PrivateAliasNames     | Sort-Object
    $PublicFunctions       = $PublicFunctions       | Sort-Object -Property BaseName
    $PrivateFunctions      = $PrivateFunctions      | Sort-Object -Property BaseName
    $PublicAliases         = $PublicAliases         | Sort-Object -Property AliasName
    $PrivateAliases        = $PrivateAliases        | Sort-Object -Property AliasName

    if(-not$Silent){
        foreach ($pf in $PublicFunctionNames)   {
            # Write-SpectreHost "[#7A8085]Public function added:   [/][#FFFFFF]$($pf)[/]"
        }
        foreach ($pa in $PublicAliasNames)     {
            Write-SpectreHost "[#7A8085]Public alias added:      [/][#FFFFFF]$($pa)[/]"
        }
        foreach ($prf in $PrivateFunctionNames) {
            # Write-SpectreHost "[#7A8085]Private function added:  [/][#FFFFFF]$($prf)[/]"
        }
        foreach ($pra in $PrivateAliasNames)   {
            Write-SpectreHost "[#7A8085]Private alias added:     [/][#FFFFFF]$($pra)[/]"
        }
    }

    $Export = [PSCustomObject]@{
        AllFunctions        = $PublicFunctionNames + $PrivateFunctionNames
        AllAliases          = $PublicAliasNames + $PrivateAliasNames
        PublicFunctions     = $PublicFunctionNames
        PrivateFunctions    = $PrivateFunctionNames
        PublicAliases       = $PublicAliasNames
        PrivateAliases      = $PrivateAliasNames
        AllFunctionsObj     = $PublicFunctions + $PrivateFunctions
        AllAliasesObj       = $PublicAliases + $PrivateAliases
        PublicFunctionsObj  = $PublicFunctions
        PrivateFunctionsObj = $PrivateFunctions
        PublicAliasesObj    = $PublicAliases
        PrivateAliasesObj   = $PrivateAliases
    }
    $Export
}

function Update-FMModule {
    [CmdletBinding()]
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

Update-FMModule -UpdateFunctionsAndAliases -Verbose

