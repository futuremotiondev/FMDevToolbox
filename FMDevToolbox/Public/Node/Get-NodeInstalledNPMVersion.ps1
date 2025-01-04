using module "..\..\Private\Completions\Completers.psm1"

function Get-NodeInstalledNPMVersion {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    param (
        [CompletionsNodeVersions()]
        [String] $NodeVersion = 'All'
    )

    function Needs-Upgrade {
        param ([version] $curVersion, [version] $latestVersion)
        ($curVersion -lt $latestVersion) ? $true : $false
    }

    try {
        $cmd = Get-Command node.exe -CommandType Application
    }
    catch {
        Write-Error "node.exe can't be located in PATH."
        return $null
    }

    $npmUrl = "https://registry.npmjs.org/npm/latest"
    try{
        $latestVersion = (Invoke-RestMethod -Uri $npmUrl -Method Get -ErrorAction SilentlyContinue -Verbose:$false).version
    }
    catch {
        $latestVersion = "Unable to Determine"
    }

    if(Test-NVMForWindowsInstalled){
        Write-Verbose "NVM for Windows is installed. Getting versions specified."
        if($NodeVersion -eq 'All'){
            [Object[]] $nodeVersions = Get-NodeInstalledVersions
        }
        else{
            [Object[]] $nodeVersions = Get-NodeInstalledVersions |
                Where-Object { $_.Version -eq $NodeVersion }
        }
        foreach ($version in $nodeVersions) {
            $npmRoot = Join-Path -Path ($version.ModulesFolder) -ChildPath "npm\bin"
            $npmScript = Join-Path $npmRoot -ChildPath "npm-cli.js"
            $npmVersion = & $cmd @($npmScript, '--version')
            $needsUpgrade = Needs-Upgrade -curVersion $npmVersion -latestVersion $latestVersion
            [PSCustomObject]@{
                NodeVersion = $version.Version
                NPMVersion = $npmVersion
                NPMLatestVersion = $latestVersion
                NeedsUpgrade = $needsUpgrade
            }
        }
    }
    else {
        Write-Verbose "NVM for Windows is not installed. Getting version directly."
        $nVersion = & $cmd '--version'
        $nodeRoot = "$([System.IO.Directory]::GetParent($cmd.Path).FullName)\node_modules\npm\bin"
        $npmScript = Join-Path $nodeRoot -ChildPath "npm-cli.js"
        $npmVersion = & $cmd @($npmScript, '--version')
        $needsUpgrade = Needs-Upgrade -curVersion $npmVersion -latestVersion $latestVersion
        [PSCustomObject]@{
            NodeVersion = $nVersion
            NPMVersion = $npmVersion
            NPMLatestVersion = $latestVersion
            NeedsUpgrade = $needsUpgrade
        }
    }
}

