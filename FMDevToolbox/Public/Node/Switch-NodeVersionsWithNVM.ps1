﻿using module "..\..\Private\Completions\Completers.psm1"
function Switch-NodeVersionsWithNVM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [CompletionsNodeVersions()]
        [ValidateNotNullOrEmpty()]
        [String] $Version,
        [Switch] $ShowNVMOutput
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
    Write-SpectreHost "[#9fa3a6]Switching your active NodeJS version to[/] [#73e7a5]v$ActiveVersion[/]"
    if($ShowNVMOutput){
        & $NVMCmd use $Version
    }
    else {
        $null = & $NVMCmd use $Version 2>&1
    }

    while (-not(Test-Path -LiteralPath "$env:NVM_SYMLINK")) {}

}