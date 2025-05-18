function Convert-FontWOFFDecompress {
    [CmdletBinding(DefaultParameterSetName="FontTools")]
    param (
        [Parameter(Mandatory,Position=0,ParameterSetName="FontTools",ValueFromPipeline)]
        [Parameter(Mandatory,Position=0,ParameterSetName="Google",ValueFromPipeline)]
        [ValidateScript({
            if($_ -match '[\?\*]'){
                throw "Wildcard characters *, ? are not acceptable with -LiteralPath"
            }
            if(-not [System.IO.Path]::IsPathRooted($_)){
                throw "Relative paths are not allowed in -LiteralPath."
            }
            if((Get-Item -LiteralPath $_).PSIsContainer){
                throw "-LiteralPath for this function only accepts files."
            }
            $true
        })]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,

        [Parameter(Mandatory=$false,Position=1,ParameterSetName="FontTools")]
        [Switch] $FontTools,

        [Parameter(Mandatory,Position=1,ParameterSetName="Google")]
        [Switch] $Google,

        [Parameter(ParameterSetName="FontTools")]
        [String] $CustomFontToolsPath,

        [Int32] $MaxThreads = 24

    )

    begin {

        if($PSCmdlet.ParameterSetName -eq 'FontTools'){
            if(-not $CustomFontToolsPath){
                $FontToolsVenvPath = [System.IO.Path]::Combine($env:FM_PY_VENV, "FontTools")
            }
            else {
                $FontToolsVenvPath = $CustomFontToolsPath
            }
            if(-not(Test-Path -LiteralPath $FontToolsVenvPath)){
                throw "FontTools VENV is missing or not installed. ($FontToolsVenvPath)"
            }
            $ftActivate = [System.IO.Path]::Combine($FontToolsVenvPath, "Scripts", "Activate.ps1")
            if(-not(Test-Path -LiteralPath $ftActivate)){
                throw "FontTools VENV activation script is missing. ($ftActivate)"
            }
            & $ftActivate
            try {
                $cmdFtcli = Get-Command ftcli.exe -CommandType Application
            }
            catch {
                throw "ftcli.exe cannot be located in your FontTools VENV Install it and try again."
            }
        }
        else {
            try {
                $cmdGoogleWoff2 = Get-Command woff2_decompress.exe -CommandType Application
            }
            catch {
                throw "woff2_decompress.exe cannot be located in PATH."
            }
        }
        $woffList = [HashSet[String]]@()
    }

    process {
        $resolvedPaths = Get-Item -LiteralPath $LiteralPath -Force
        $resolvedPaths | % {
            if(Test-Path -LiteralPath $_.FullName -PathType Leaf){
                if($_.Extension -in @('.woff','.woff2')){
                    $null = $woffList.Add($_.FullName)
                }
            }
        }
    }

    end {
        if($PSCmdlet.ParameterSetName -eq 'Google'){
            $woffList | % -Parallel {
                $CurrentFont = $_
                $cmdGoogleWoff2 = $Using:cmdGoogleWoff2
                & $cmdGoogleWoff2 $CurrentFont | Out-Null
            } -ThrottleLimit $MaxThreads
        }
        elseif($PSCmdlet.ParameterSetName -eq 'FontTools'){
            $woffList | % -Parallel {
                $curFont = $_
                $cmdFtcli = $Using:cmdFtcli
                $FtcliParams = "converter", "wf2ft", "--no-overwrite", $curFont
                & $cmdFtcli $FtcliParams
            } -ThrottleLimit $MaxThreads
            & deactivate
        }
    }
}