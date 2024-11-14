[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
param()
function Install-FMDevToolboxPythonVenvObject {
    [CmdletBinding()]
    param (
        [int] $DotnetMajorVersion = 8,
        [String] $BuildPath,
        [String] $InstallLocation
    )

    if(Test-Path $InstallLocation -PathType Container){
        Remove-Item -LiteralPath $InstallLocation -Recurse -Force -Verbose
        New-Item -Path $InstallLocation -ItemType Directory -Force | Out-Null
    }

    $CMD = Get-Command dotnet -ErrorAction SilentlyContinue
    if ((-not$CMD) -or (-not(dotnet --list-sdks | Select-String "^$DotnetMajorVersion.+"))) {
        Write-Host "dotnet SDK $DotnetMajorVersion wasn't found. Please install dotnet SDK $DotnetMajorVersion."
        Write-Host "You can install the dotnet SDK $DotnetMajorVersion by running 'winget install Microsoft.DotNet.SDK.$DotnetSdkMajorVersion' in an administrator console."
    }
    try {
        Push-Location
        Set-Location -Path $BuildPath
        & dotnet build -c Release -o $InstallLocation | Out-Null
        Remove-Item -LiteralPath "$BuildPath\obj" -Recurse -Force | Out-Null
    } finally {
        Pop-Location
    }
}

function Install-MicrosoftToolkitUwpNotifications {
    param (
        [string] $InstallLocation,
        [string] $Version = "7.1.3"
    )
    New-Item -Path $InstallLocation -ItemType "Directory" -Force | Out-Null
    $libPath = Join-Path $InstallLocation "Microsoft.Toolkit.Uwp.Notifications.7.1.3"
    New-Item -Path $libPath -ItemType Directory -Force -Verbose | Out-Null
    $TempDir = [System.IO.Directory]::CreateTempSubdirectory()
    $downloadLocation = Join-Path $TempDir "download.zip"
    Invoke-WebRequest "https://www.nuget.org/api/v2/package/Microsoft.Toolkit.Uwp.Notifications/$Version" -OutFile $downloadLocation -UseBasicParsing
    Expand-Archive $downloadLocation $TempDir -Force
    Remove-Item $downloadLocation
    $Dir = Get-ChildItem -LiteralPath $TempDir -Include 'net5.0' -Directory -Recurse | % {$_.FullName}
    $Dir | Move-Item -Destination $libPath -Force
    Remove-Item -LiteralPath $TempDir -Recurse -Force | Out-Null
}

function Install-MicrosoftWindowsSDKNet {
    param (
        [string] $InstallLocation,
        [string] $Version = "10.0.19041.31"
    )
    New-Item -Path $InstallLocation -ItemType "Directory" -Force | Out-Null
    $libPath = Join-Path $InstallLocation "Microsoft.Windows.SDK.NET.10.0.19041.31"
    New-Item -Path $libPath -ItemType Directory -Force -Verbose | Out-Null
    $TempDir = [System.IO.Directory]::CreateTempSubdirectory()
    $downloadLocation = Join-Path $TempDir "download.zip"
    Invoke-WebRequest "https://www.nuget.org/api/v2/package/Microsoft.Windows.SDK.NET.Ref/$Version" -OutFile $downloadLocation -UseBasicParsing
    Expand-Archive $downloadLocation $TempDir -Force
    Remove-Item $downloadLocation
    $Dir = Get-ChildItem -LiteralPath $TempDir -Include 'net6.0' -Directory -Recurse | % {$_.FullName}
    $Dir | Move-Item -Destination $libPath -Force
    Remove-Item -LiteralPath $TempDir -Recurse -Force | Out-Null
}

function Install-OokiiDialogsWinForms {
    param (
        [string] $InstallLocation,
        [string] $Version = "4.0.0"
    )
    New-Item -Path $InstallLocation -ItemType "Directory" -Force | Out-Null
    $libPath = Join-Path $InstallLocation "Ookii.Dialogs.WinForms.4.0.0"
    New-Item -Path $libPath -ItemType Directory -Force -Verbose | Out-Null
    $TempDir = [System.IO.Directory]::CreateTempSubdirectory()
    $downloadLocation = Join-Path $TempDir "download.zip"
    Invoke-WebRequest "https://www.nuget.org/api/v2/package/Ookii.Dialogs.WinForms/$Version" -OutFile $downloadLocation -UseBasicParsing
    Expand-Archive $downloadLocation $TempDir -Force
    Remove-Item $downloadLocation
    $Dir = Get-ChildItem -LiteralPath $TempDir -Include 'net6.0-windows7.0' -Directory -Recurse | % {$_.FullName}
    $Dir | Move-Item -Destination $libPath -Force
    Remove-Item -LiteralPath $TempDir -Recurse -Force | Out-Null
}

$PyVenvObjectBuildPath = [System.IO.Path]::Combine($PSScriptRoot, "Private", "Classes", "PythonVenvObject")
$PyVenvObjectInstall = [System.IO.Path]::Combine($PSScriptRoot, "Lib", "FMDevToolbox.PythonVenvObject", "net6.0")
Install-FMDevToolboxPythonVenvObject -BuildPath $PyVenvObjectBuildPath -InstallLocation $PyVenvObjectInstall
Install-MicrosoftToolkitUwpNotifications -InstallLocation "$PSScriptRoot\Lib"
Install-MicrosoftWindowsSDKNet -InstallLocation "$PSScriptRoot\Lib"
Install-OokiiDialogsWinForms -InstallLocation "$PSScriptRoot\Lib"
