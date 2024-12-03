using module "..\..\Private\Completions\Completers.psm1"
function Get-PrivateModuleFunctions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [CompletionsModuleEnumeration()]
        [string[]] $Module
    )
    foreach ($Name in $Module) {
        $mod = $null
        Write-Verbose "Processing Module '$Name'"
        $mod = Get-Module -Name $Name -ErrorAction SilentlyContinue
        if (-not $mod) {
            Write-Error "Module '$Name' not found"
            continue
        }
        $ScriptBlock = {
            $ExecutionContext.InvokeCommand.GetCommands('*', 'Function', $true)
        }
        $PublicFunctions = $mod.ExportedCommands.GetEnumerator() |
            Select-Object -ExpandProperty Value |
            Select-Object -ExpandProperty Name
        & $mod $ScriptBlock | Where-Object {$_.Source -eq $Name -and $_.Name -notin $PublicFunctions}
    }
}