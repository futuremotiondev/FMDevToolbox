using module ".\private\Completions\FMCompleters.psm1"
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
param()

[String] $script:ModuleRoot       = "$PSScriptRoot"
[String] $script:LibRoot          = "$PSScriptRoot\Lib"
[String] $script:PrettierConfig   = "$PSScriptRoot\Data\Prettier\prettierrc.json"
[String] $script:FMUserConfigDir  = "$env:HOMEPATH\.fmotiondev"
[String] $script:FMUserLogDir     = "$env:HOMEPATH\.fmotiondev\logs"
[String] $script:ConsoleWidth     = $Host.UI.RawUI.WindowSize.Width
[String] $script:ConsoleWidthSafe = $Host.UI.RawUI.WindowSize.Width - 1

if(-not(Test-Path $script:FMUserConfigDir)){
    New-Item -Path $script:FMUserConfigDir -ItemType Directory -Force
}
if(-not(Test-Path $script:FMUserLogDir)){
    New-Item -Path $script:FMUserLogDir -ItemType Directory -Force
}

# Get all private and public functions, and assemblies
$Private    = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Recurse -ErrorAction Continue )
$Public     = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1  -Recurse -ErrorAction Continue )
$Assemblies = @( Get-ChildItem -Path $PSScriptRoot\Lib\*.dll     -Recurse -ErrorAction Continue )

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

Export-ModuleMember -Function '*' -Alias '*'
