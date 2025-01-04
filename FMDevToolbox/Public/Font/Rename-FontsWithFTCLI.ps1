function Rename-FontsWithFTCLI {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias("PSPath, Files")]
        [String[]] $LiteralPath,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('FamilyNameStyleName','PostScriptName','FullFontName','1','2','3', IgnoreCase = $true)]
        [String] $Method = '3',

        [Switch] $Overwrite,
        [Switch] $RecurseFolders,
        [Int32] $MaxThreads = 16
    )

    begin {


        #  BEGIN CHECK FOR FONTTOOLS INSTALLTION  //////////////////////////////////////////////////////#
        #///////////////////////////////////////////////////////////////////////////////////////////////#

        $FontToolsActivationScript = "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1"

        if(-not(Test-Path -LiteralPath $FontToolsActivationScript -PathType Leaf)){
            throw "An existing installtion of FontTools was not found. Please install FontTools into a virtual environment in the '$env:FM_PY_VENV\FontTools' directory."
        }

        Write-Verbose -Message "FontTools activation script has been located. Activating the venv now."

        #  ACTIVATE FONTTOOLS VENV  ////////////////////////////////////////////////////////////////////#
        #///////////////////////////////////////////////////////////////////////////////////////////////#

        try {
            & $FontToolsActivationScript
        }
        catch {
            throw "There was an error activating the FontTools virtual environment ($VENVLocation\Scripts\Activate.ps1). Make sure the VENV is properly configured."
        }

        Write-Verbose -Message "The FontTools Virtual Environment has been Activated."


        #  BEGIN CHECK FOR FTCLI.EXE  //////////////////////////////////////////////////////////////#
        #///////////////////////////////////////////////////////////////////////////////////////////#

        Write-Verbose -Message "Geting the ftcli.exe command (Font Tools)"
        $CMDFTCLI = Get-Command -Name "$env:FM_PY_VENV\FontTools\Scripts\ftcli.exe" -CommandType Application -ErrorAction SilentlyContinue
        if(-not($CMDFTCLI)){
            throw "Can't find ftcli.exe in the FontTools VENV. Make sure FontTools is installed correctly."
        }

        Write-Verbose -Message "SUCCESS: ftcli.exe was found in the FontTools VENV"

        if($Method -eq '1' -or "FamilyNameStyleName"){ $MethodNum = 1 }
        if($Method -eq '2' -or "PostScriptName"){ $MethodNum = 2 }
        if($Method -eq '3' -or "FullFontName"){ $MethodNum = 3 }

        [Array] $ValidFontArray = '.ttf','.otf','.ttc','.woff','.woff2'

    }

    process {

        $LiteralPath | ForEach-Object -Parallel {

            $Obj = $_

            $RecurseFolders = $Using:RecurseFolders
            $Overwrite = $Using:Overwrite
            $Method = $Using:Method
            $MethodNum = $Using:MethodNum
            $ValidFontArray = $Using:ValidFontArray
            $CMDFTCLI = $Using:CMDFTCLI

            $CurParams = [System.Collections.ArrayList]@('utils', 'font-renamer')

            $ItemType = (Test-Path -LiteralPath $Obj -PathType Container) ? 'Folder' : 'File'
            if(($ItemType -eq 'Folder') -and $RecurseFolders) {
                $CurParams.Add('-r')
            }
            if($Overwrite) { $CurParams.Add('-o') }
            $CurParams.AddRange(@('-s', $MethodNum, $Obj))

            if($ItemType -eq 'Folder') {

                $FolderContents = Get-ChildItem -Depth 20 -Force -LiteralPath $Obj |
                    Where-Object { $_.Extension -in $ValidFontArray } | ForEach-Object {$_.FullName}

                if($FolderContents.Count -eq 0){
                    Write-Warning "Passed folder ($Obj) doesn't contain any valid font files to rename."
                    continue
                }
                try {
                    Write-Warning -Message "Renaming the folder ($Obj) now with ftcli.exe"
                    & $CMDFTCLI @($CurParams) | Out-Null
                }
                catch {
                    Write-Error "Renaming the folder ($Obj) failed." -ErrorAction Continue
                    continue
                }
            }
            else {
                try {
                    Write-Verbose -Message "Renaming the file ($Obj) now with ftcli.exe"
                    & $CMDFTCLI @($CurParams) | Out-Null
                }
                catch {
                    Write-Error "Renaming the file ($Obj) failed. Details: $_" -ErrorAction Continue
                    continue
                }
            }
        }
    }

    end {
        & deactivate
    }
}