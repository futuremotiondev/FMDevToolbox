using module "..\..\Private\Completions\FMCompleters.psm1"
function Get-ModulePrivateFunctions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [AvailableModulesCompleter()]
        [string[]] $Name
    )
    process {
        foreach ($Module in $Name) {

            if(-not(Test-ModuleIsLoaded -Name $Module)){
                try {
                    Import-Module -Name $Module -Force
                }
                catch {
                    Write-Error "Unable to import module $Module. Aborting."
                    continue
                }
            }

            $ModuleInstance = Get-Module -Name $Module -ErrorAction SilentlyContinue
            if (-not $ModuleInstance) {
                Write-Error "Module '$Module' not found. Aborting."
                continue
            }

            $ScriptBlock = { $ExecutionContext.InvokeCommand.GetCommands('*', 'Function', $true) }
            $PublicFunctions = $ModuleInstance.ExportedCommands.GetEnumerator() |
                Select-Object -ExpandProperty Value | Select-Object -ExpandProperty Name

            $PrivateFunctionsObject = & $ModuleInstance $ScriptBlock | Where-Object {$_.Source -eq $Module -and $_.Name -notin $PublicFunctions}
            $PrivateFunctionsObject
        }
    }
}