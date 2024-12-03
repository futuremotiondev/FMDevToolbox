function Install-NodeGlobalPackagesInteractive {
    <#
    .SYNOPSIS
    Installs global Node.js packages interactively across selected Node.js versions managed by NVM.

    .DESCRIPTION
    This function allows users to install specified global Node.js packages across multiple Node.js versions managed using NVM (Node Version Manager). It provides an interactive console interface for selecting Node.js versions and specifying packages. The function also supports clearing the console before execution and can loop until explicitly exited.

    .PARAMETER ClearConsole
    Clears the console before executing the package installation process.

    .PARAMETER ContinueUntilExit
    Continues to prompt for package installations until the user chooses to exit.

    .EXAMPLE
    # **Example 1**
    # Install global packages interactively:
    Install-NodeGlobalPackagesInteractive -ClearConsole -ContinueUntilExit

    .OUTPUTS
    None. The function performs actions but does not output objects to the pipeline.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 11-28-2024
    #>

    [CmdletBinding()]
    param (
        [Switch] $NoClearConsole,
        [String] $PackageTextColor = "#75B5AA"
    )

    $NodeVersions = Get-NVMNodeVersions
    if ($NodeVersions.Count -eq 0) {
        Write-Error "No NodeJS versions are installed on this computer with NVM."
        return
    }

    if (-not$NoClearConsole) { Clear-Host }
    $DisplayWidth = $Host.UI.RawUI.WindowSize.Width - 1

    $PreviouslyActiveVersion = Get-NodeActiveVersionInNVM -ErrorAction SilentlyContinue
    if (-not$PreviouslyActiveVersion) {
        $PreviouslyActiveVersion = $NodeVersions[0]
        if ($PreviouslyActiveVersion) {
            Switch-NodeVersionsWithNVM -Version $PreviouslyActiveVersion
        } else {
            Write-SpectreHost "[#999999]Couldn't determine your previously active NodeJS version.[/]"
            Show-HorizontalLineInConsole
            Write-Host "`n"
            $PreviouslyActiveVersion = $null
        }
    }

    # TITLE DISPLAY
    Format-SpectreTable -Data "[#FFFFFF]Node.js NVM Global Package Installer[/]" -Border Rounded -Color "#656565" -AllowMarkup -HideHeaders -Width $DisplayWidth

    # DIRECTIONS DISPLAY
    $Intro = @"
`n[#AAAAAA]This tool will install global packages to[/] [white]all selected versions of Node.js.[/]`n
[#AAAAAA]All packages should be entered in comma delimited format. For example:[/]`n
[$PackageTextColor]svgo, sass, generator-code[/]`n
"@
    Format-SpectreTable -Data ([PSCustomObject]@{ Intro = $Intro }) -Border Rounded -Color "#656565" -AllowMarkup -HideHeaders -Width $DisplayWidth -Wrap

    Show-NVMNodeGlobalPackages -TableWidth $DisplayWidth -PackageTextColor $PackageTextColor

    # GET USER ENTERED DATA
    Write-Host ""
    $NPMString = Read-SpectreText -Question "[#AAAAAA]List the package(s) you want to install:[/]" -DefaultAnswer '' -AnswerColor "#75B5AA"
    if ([String]::IsNullOrEmpty($NPMString)) {
        Write-Host "No Packages Entered. Aborting."
        exit
    }
    $Packages = $NPMString.Split(',').Trim()

    foreach ($Package in $Packages) {
        if (-not(Confirm-NPMPackageExistsInRegistry $Package)) {
            Write-Error "The package $Package does not exist in the NPMjs registry. Aborting."
            return
        }
    }

    $PackageList = $Packages -join ", "
    $SelectedVersions = Read-SpectreMultiSelection -Title "Select versions of Node.js you wish to install to." -Choices $NodeVersions -Color "#75B5AA" -PageSize 6

    $Instruction = if ($Packages.Count -gt 1) {
        "[#AAAAAA]The packages [WHITE]$PackageList[/] will be installed in the following node versions:`n[/]"
    } else {
        "[#AAAAAA]The package [WHITE]$PackageList[/] will be installed in the following node versions:`n[/]"
    }
    $Instruction += $SelectedVersions | ForEach-Object { "`n[#75B5AA]> v$_[/]" }
    Write-SpectreHost ("`n" + $Instruction + "`n")

    $Prompt = if ($Packages.Count -gt 1) {
        "[#AAAAAA]Are you sure you want to install the $($Packages.Count) packages ([white]$PackageList[/]) globally?`n[/]"
    } else {
        "[#AAAAAA]Are you sure you want to install the package ([white]$PackageList[/]) globally?`n`n[/]"
    }
    $Success = "[#AAAAAA]`nInstalling package(s) [white]$PackageList[/] now.`n[/]"

    if (Read-SpectreConfirm -Prompt $Prompt -ConfirmSuccess $Success -ne "Y") {
        exit
    }

    foreach ($Version in $SelectedVersions) {
        Install-NVMNodeGlobalPackages -Version $Version -Packages $Packages
    }

    if (-not [String]::IsNullOrEmpty($PreviouslyActiveVersion)) {
        Switch-NodeVersionsWithNVM -Version $PreviouslyActiveVersion
    }

    Install-NodeGlobalPackagesInteractive

}


#New-Alias -Name nodei -Value Install-NodeGlobalPackagesInteractive

#Install-NodeGlobalPackagesInteractive