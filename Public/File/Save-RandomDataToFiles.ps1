function Save-RandomDataToFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]
        $OutputPath,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [decimal]
        $FilesizeMin,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [decimal]
        $FilesizeMax,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateSet('Bytes','KB','MB','GB','TB', IgnoreCase = $true)]
        [string]
        $Unit,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName)]
        [Int32]
        $NumberOfFiles = 20,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName)]
        [Int32]
        $FilenameLengthMin = 10,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName)]
        [Int32]
        $FilenameLengthMax = 25,

        [Parameter(Mandatory = $false,ValueFromPipelineByPropertyName)]
        [String[]]
        $FileExtensions = @('exe','jpg','png','dll','gif','ttf','doc','otf','txt'),

        [Parameter(Mandatory = $false,ValueFromPipelineByPropertyName)]
        [Switch]
        $RandomFileExtensions,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName)]
        [Int32]
        $MaxThreads = 16
    )

    begin {
        $List = @()
    }

    process {
        foreach ($P in $OutputPath) {
            if     ($P -is [String]) { $List += $P }
            elseif ($P.Path)         { $List += $P.Path }
            elseif ($P.FullName)     { $List += $P.FullName }
            elseif ($P.PSPath)       { $List += $P.PSPath }
            else                     { Write-Warning "$P is an unsupported type." }
        }
    }

    end {

        $List | ForEach-Object -Parallel {

            $DestPath           = $_
            $FExtensions        = $Using:FileExtensions
            $FExtensionsNum     = $FExtensions.Count
            $FExtensionsRnd     = $Using:RandomFileExtensions
            $NumFilesToGenerate = $Using:NumberOfFiles
            $FSizeMin           = $Using:FilesizeMin
            $FSizeMax           = $Using:FilesizeMax
            $FnLengthMin        = $Using:FilenameLengthMin
            $FnLengthMax        = $Using:FilenameLengthMax
            $FnUnit             = $Using:Unit

            for ($i = 0; $i -lt $NumFilesToGenerate; $i++) {

                $CalculatedFilesize = Get-Random -Minimum $FSizeMin -Maximum $FSizeMax

                if($FExtensionsRnd){
                    $FinalExtension = Get-RandomAlphanumericString -Length 3
                }else{
                    $FinalExtension = $FExtensions[(Get-Random -Minimum 0 -Maximum $FExtensionsNum)]
                }

                if($FnLengthMin -gt $FnLengthMax){
                    throw [System.Exception] "Minimum file length is greater than Maximum. Aborting."
                }

                if($FnLengthMin -eq $FnLengthMax){
                    $FinalFnLength = $FnLengthMin
                }else{
                    $FinalFnLength = Get-Random -Minimum $FnLengthMin -Maximum $FnLengthMax
                }

                $RandomData = @{
                    OutputPath     = $DestPath
                    Filesize       = $CalculatedFilesize
                    Unit           = $FnUnit
                    FileExtension  = $FinalExtension
                    FilenameLength = $FinalFnLength
                }

                Save-RandomDataToFile @RandomData
            }
        } -ThrottleLimit $MaxThreads
    }
}