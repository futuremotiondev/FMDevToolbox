using module ".\private\Completions\FMCompleters.psm1"

# Get all private and public functions, and assemblies
$Private    = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Recurse -Force -ErrorAction Continue )
$Public     = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1  -Recurse -Force -ErrorAction Continue )
$Assemblies = @( Get-ChildItem -Path $PSScriptRoot\Lib\*.dll     -Recurse -Force -ErrorAction Continue )

[String] $script:ModuleRoot         = $PSScriptRoot
[String] $script:ModulePublicRoot   = "$PSScriptRoot\Public"
[String] $script:ModulePrivateRoot  = "$PSScriptRoot\Private"
[String] $script:ModuleAssemblyRoot = "$PSScriptRoot\Lib"
[String] $script:ModuleCompletions  = "$PSScriptRoot\Private\Completions\FMCompleters.psm1"
[String] $script:GitignoreTemplates = "$PSScriptRoot\Data\GitignoreTemplates"
[String] $script:PrettierConfig     = "$PSScriptRoot\Data\Prettier\prettierrc.json"
[String] $script:ConsoleWidth       = $Host.UI.RawUI.WindowSize.Width
[String] $script:ConsoleWidthSafe   = $Host.UI.RawUI.WindowSize.Width - 1


# Migrate The above settings to a hashtable.
# $FMConfig = [ordered]@{
#     ModuleRoot             = "$PSScriptRoot"
#     ModuleAssemblyRoot     = "$PSScriptRoot\Lib"
#     ModulePrivateFunctions = $Private
#     ModulePublicFunctions  = $Public
#     ModuleAssemblies       = $Assemblies
#     GitignoreTemplates     = $null
#     PrettierConfig         = $null
#     ConsoleWidth           = $null
#     ConsoleWidthSafe       = $null
#     ElapsedTime            = $null
#     LastCommand            = $null
#     LastCommandTime        = $null
#     LastCommandResults     = $null
#     RefreshTime            = $null
# }
# New-Variable -Name FMToolboxConfig -Value $FMConfig -Scope Script -Force


foreach ($assembly in @($Assemblies)) {
    $aName = $assembly.Name
    $aFullName = $assembly.FullName
    try {
        Write-Verbose -Message "Importing assembly $aFullName now."
        Add-Type -LiteralPath $aFullName -Verbose
    }
    catch {
        $eMsg = $_.Exception.Message
        $lExceptions = $_.Exception.LoaderExceptions | Sort-Object -Unique
        Write-Error "Error processing assembly $aName. Exception: $eMsg"
        foreach ($err in $lExceptions) {
            Write-Error "Processing $aName LoaderExceptions: $($err.Message)"
        }
    }
}

foreach ($ps1File in @($Private + $Public)) {
    $ps1FullName = $ps1File.Fullname
    $ps1DirectoryName = $ps1File.DirectoryName
    try {
        Write-Verbose -Message "Importing function $ps1FullName now."
        . $ps1FullName
    }
    catch {
        Write-Error -Message "Failed to import function from '$ps1FullName' in '$ps1DirectoryName'. Details: $_"
    }
}

Export-ModuleMember -Function * -Alias *
