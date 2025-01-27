function Save-Base64StringToFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [String] $Base64Input,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName="FileSpecified")]
        [String] $DestinationFile,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName,ParameterSetName="FileSpecified")]
        [String] $OverwriteExistingFile,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName="UseDialog")]
        [Switch] $UseDialog
    )

    begin {}

    process {

        try {
            $Base64Input = $Base64Input.Trim()
            $ContentBytes = [Convert]::FromBase64String($Base64Input)
        } catch {
            throw "Couldn't decode -Base64Input string."
        }

        if($PSCmdlet.ParameterSetName -eq 'UseDialog'){

            $FormFilterStringArray = [System.Collections.Generic.List[String]]@()
            $FormFilterStringArray.Add("All files (*.*)|*.*")
            $FormFilterStringArray.Add("SVG (*.SVG;)|*.SVG")
            $FormFilterStringArray.Add("ICO (*.ICO;)|*.ICO")
            $FormFilterStringArray.Add("JPG (*.JPG;)|*.JPG")
            $FormFilterStringArray.Add("JPEG (*.JPEG;)|*.JPEG")
            $FormFilterStringArray.Add("PNG (*.PNG;)|*.PNG")
            $FormFilterStringArray.Add("TIFF (*.TIFF;)|*.TIFF")
            $FormFilterStringArray.Add("TIF (*.TIF;)|*.TIF")
            $FormFilterStringArray.Add("BMP (*.BMP;)|*.BMP")
            $FormFilterStringArray.Add("EPS (*.EPS;)|*.EPS")
            $FormFilterStringArray.Add("PDF (*.PDF;)|*.PDF")
            $FormFilterString = $FormFilterStringArray -join "|"

            $FileSaveResult = Invoke-SaveFileDialog -SpecialPath Desktop -Title "Save Decoded File..." -FilterString $FormFilterString
            if($FileSaveResult.Result -eq 'OK'){
                $FileSaveDestination = $FileSaveResult.Filepath
            }
            else{
                Write-Error "User cancelled the file save operation."
                return
            }
        }
        else{
            if($OverwriteExistingFile){
                $FileSaveDestination = $DestinationFile
            }
            else{
                $FileSaveDestination = Get-UniqueNameIfDuplicate -LiteralPath $DestinationFile
            }
        }

        try {
            [IO.File]::WriteAllBytes($FileSaveDestination, $ContentBytes)
            Request-ExplorerRefreshV3
        } catch {
            throw "Failed to write content to file '$FileSaveDestination': $_"
        }

        [PSCustomObject]@{
            SavedFilePath = $FileSaveDestination
            FileSizeBytes = $ContentBytes.Length
        }
    }

    end {}

}