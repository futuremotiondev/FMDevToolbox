function Get-EnumsInCurrentDomain {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [String] $Filter,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({
            if(-not([System.IO.Path]::IsPathRooted($_))){
                throw "The assembly must be a rooted filepath."
            }
            if($_ -match '[\?\*]'){
                throw "Wildcards are not permitted."
            }
            if(-not(Test-Path -LiteralPath $_ -PathType Leaf)){
                throw "The provided assembly path doesn't exist on disk."
            }
        })]
        [String[]] $PreloadAssembly
    )

    begin {
        if($PreloadAssembly){
            foreach ($assembly in $PreloadAssembly) {
                try {
                    [AppDomain]::CurrentDomain.Load($assembly)
                }
                catch {
                    Write-Error "Assembly '$assembly' could not be loaded into the current domain."
                    continue
                }
            }
        }
        $currentDomainAssemblies = [AppDomain]::CurrentDomain.GetAssemblies()
    }
    process {
        foreach ($assembly in $currentDomainAssemblies) {
            try {
                $assembly.GetTypes() | Where-Object {
                    if($Filter){
                        ($_.IsEnum -and $_.IsPublic -and ($_ -like $Filter))
                    }
                    else {
                        ($_.IsEnum -and $_.IsPublic)
                    }
                } | % {
                    $_.ToString()
                }
            }
            catch [System.Management.Automation.MethodInvocationException]{
                Write-Verbose "Caught MethodInvocationException. Details: $_"
                continue
            }
        }
    }
}