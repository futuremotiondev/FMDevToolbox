using module "..\..\Private\Completions\FMCompleters.psm1"
function Confirm-ModuleIsLoaded {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position=0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage="Module name(s) to check loaded status."
        )]
        [ValidateNotNullOrEmpty()]
        [AvailableModulesCompleter()]
        [String[]] $Name,

        [Parameter(
            ValueFromPipelineByPropertyName,
            HelpMessage="Outputs a PSCustomObject with more details about the module if it's loaded."
        )]
        [Switch] $ShowDetails,

        [Parameter(
            ValueFromPipelineByPropertyName,
            HelpMessage="Loads the module if the module isn't already loaded."
        )]
        [Switch] $LoadModuleIfNotLoaded
    )

    process {
        $Name | % {
            $modName = $_
            if(gmo -EA 0 | where -EA 0 {$_.Name -eq $modName}){
                $isLoaded = $true
            }
            else {
                if($PSBoundParameters.ContainsKey('LoadModuleIfNotLoaded')){
                    if($null -ne (Get-Module -ListAvailable -Name $modName)){
                        try { Import-Module -Name $modName -Force | Out-Null }
                        catch { Write-Warning "There was an error loading the module '$modName' Details: $_"; return }
                        $isLoaded = $true
                    }
                }
            }
            if($isLoaded){
                $lModule = (gmo -EA 0 -Name $modName)
                if($PSBoundParameters.ContainsKey('ShowDetails')){
                    [PSCustomObject]@{
                        Name             = $lModule.Name
                        Loaded           = $true
                        Version          = $lModule.Version
                        Path             = $lModule.Path
                        ExportedCommands = $lModule.ExportedCommands
                    }
                }
                else {
                    [PSCustomObject]@{
                        Name = $lModule.Name
                        Loaded = $true
                    }
                }
            }
            else{
                [PSCustomObject]@{
                    Name = $modName
                    Loaded = $false
                }
            }
        }
    }
}