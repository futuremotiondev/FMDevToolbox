using module "..\..\Private\Completions\FMCompleters.psm1"
function Switch-NodeVersionsWithNVM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [CompletionsNodeVersions()]
        [ValidateNotNullOrEmpty()]
        [String] $Version,
        [Switch] $HideNVMOutput
    )

    [String[]] $NodeVersions = Get-NVMNodeVersions
    if($NodeVersions.Count -eq 0){
        Write-Error "No NodeJS versions are installed with NVM."
        return
    }

    if(-not$env:NVM_SYMLINK){
        Write-Error "NVM Symlink directory (NVM_SYMLINK) isn't set. Make sure NVM for Windows is installed."
        return
    }

    $NVMCmd = Get-CommandNVM -ErrorAction Stop
    Write-SpectreHost "[#9fa3a6]Switching your active NodeJS version to[/] [#73e7a5]v$Version[/]"
    if($HideNVMOutput){
        $null = & $NVMCmd use $Version 2>&1
    }
    else {
        & $NVMCmd use $Version
    }
    while (-not(Test-Path -LiteralPath "$env:NVM_SYMLINK")) {}
}