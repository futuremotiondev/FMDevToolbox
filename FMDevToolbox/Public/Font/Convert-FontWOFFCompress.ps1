using namespace System.Collections.Generic

function Convert-FontWOFFCompress {
    [CmdletBinding(DefaultParameterSetName="FontTools")]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
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

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('woff2','woff','both')]
        [String] $WoffFormat = "woff2",

        [Parameter(ValueFromPipelineByPropertyName)]
        [String] $CustomFontToolsPath,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Int32] $MaxThreads = 12
    )

    begin {
        $WoffFormat = $WoffFormat.ToLower()
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
        $fontList = [HashSet[String]]@()
    }
    process {
        $resolvedPaths = Get-Item -LiteralPath $LiteralPath -Force
        $resolvedPaths | % {
            if(Test-Path -LiteralPath $_.FullName -PathType Leaf){
                if($_.Extension -in @('.ttf','.otf')){
                    $null = $fontList.Add($_.FullName)
                }
            }
        }
    }
    end {
        $fontList | % -Parallel {
            $curFont = $_
            $cmdFtcli = $Using:cmdFtcli
            $WoffFormat = $Using:WoffFormat

            if($WoffFormat -eq 'both'){
                $FtcliParams1 = "converter", "ft2wf", "--flavor", 'woff', "--no-overwrite", $curFont
                $FtcliParams2 = "converter", "ft2wf", "--flavor", 'woff2', "--no-overwrite", $curFont
                & $cmdFtcli $FtcliParams1
                & $cmdFtcli $FtcliParams2
            }
            else {
                $FtcliParams = "converter", "ft2wf", "--flavor", $WoffFormat, "--no-overwrite", "$curFont"
                & $cmdFtcli $FtcliParams
            }
        } -ThrottleLimit $MaxThreads
        & deactivate
    }
}