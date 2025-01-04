using module ".\private\Completions\Completers.psm1"

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
param()

[String] $script:ModuleRoot      = $PSScriptRoot
[String] $script:LibRoot         = "$PSScriptRoot\Lib"
[String] $script:PrettierConfig  = "$script:ModuleRoot\Data\Prettier\prettierrc.json"
[String] $script:FMUserConfigDir = "$env:HOMEPATH\.fmotiondev"
[String] $script:FMUserLogDir    = "$script:FMUserConfigDir\logs"

$script:FMExceptionStyle = @{
    Message = "#DF779F"; Exception = "#FFFFFF"; Method = "#8CDAAD";
    ParameterType = "#5297E4"; ParameterName = "silver"; Parenthesis = "silver";
    Path = "Yellow"; LineNumber = "blue"; Dimmed = "#A3ACB8"; NonEmphasized = "#BBC2CC";
}

if(-not(Test-Path $script:FMUserConfigDir -PathType Container)){
    New-Item -Path $script:FMUserConfigDir -ItemType Directory -Force
}
if(-not(Test-Path $script:FMUserLogDir -PathType Container)){
    New-Item -Path $script:FMUserLogDir -ItemType Directory -Force
}

foreach ($Directory in @('Private', 'Public')) {
    Get-ChildItem -Path "$PSScriptRoot\$Directory\*.ps1" -Recurse | ForEach-Object {
        $ImportFunc = $_.FullName
        $ImportFuncName = $_.Name
        $ImportFuncDir = $_.DirectoryName
        try {
            . $ImportFunc
        }
        catch {
            Write-Error -Message "Failed to import function '$ImportFuncName' from '$ImportFuncDir'. Details: $_"
        }
    }
}

Add-Type -LiteralPath "$script:LibRoot\Futuremotion.FMDevToolbox\net6.0\Futuremotion.FMDevToolbox.dll" -ErrorAction SilentlyContinue
Add-Type -LiteralPath "$script:LibRoot\Microsoft.Toolkit.Uwp.Notifications.7.1.3\net5.0-windows10.0.17763\Microsoft.Toolkit.Uwp.Notifications.dll" -ErrorAction SilentlyContinue
Add-Type -LiteralPath "$script:LibRoot\Microsoft.Windows.SDK.NET.Ref.10.0.26100.34\net6.0\Microsoft.Windows.SDK.NET.dll" -ErrorAction SilentlyContinue
Add-Type -LiteralPath "$script:LibRoot\Ookii.Dialogs.WinForms.4.0.0\net6.0-windows7.0\Ookii.Dialogs.WinForms.dll" -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
[System.Windows.Forms.Application]::EnableVisualStyles()


