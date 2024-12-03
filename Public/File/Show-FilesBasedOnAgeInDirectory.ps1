using namespace System.IO
using namespace System.Collections.Generic
function Show-FilesBasedOnAgeInDirectory {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [String[]] $Directory,

        [Parameter(Mandatory,ParameterSetName="Older")]
        [Int32] $OlderThan,

        [Parameter(Mandatory,ParameterSetName="Newer")]
        [Int32] $NewerThan,

        [ValidateSet('Descending','Ascending')]
        [String] $SortOrder = "Descending",

        [Parameter(Mandatory=$false)]
        [uint] $RecurseDepth = 4,

        [ValidateSet('FullPath','FileOnly')]
        [String] $FileDisplay = 'FullPath',

        [ValidateSet('LastWrite','Creation')]
        [String] $DateMethod = "LastWrite"
    )

    begin {
        if($NewerThan -and $OlderThan){
            throw "-NewerThanDays and -OlderThanDays cannnot be used together."
        }
        $DateToday = Get-Date
        $DateCutoff = $DateToday.AddDays(($PSCmdlet.ParameterSetName -eq "Older") ? $OlderThan : $NewerThan)
    }

    process {

        foreach ($Dir in $Directory) {
            [double] $TotalSize = 0

            $ListSplatParams = @{
                Path    =  $Dir
                File    =  $true
                Recurse =  $true
                Depth   = $RecurseDepth
            }
            $List = Get-ChildItem @ListSplatParams

            $FilesList = [List[FileInfo]]@()
            foreach ($File in $List) {
                $DateMeasurement = ($DateMethod -eq 'LastWrite') ? $File.LastWriteTime : $File.CreationTime
                if($DateMeasurement -lt $DateCutoff) { $FilesList.Add($File) }
            }

            [Int] $FilesizeMaxLength = 0
            $FilesObjectList = [List[Object]]@()

            foreach ($File in $FilesList) {

                $FormattedSize = $File.Length | Format-FileSizeAuto -DisplayDecimals

                [String] $FormattedSizeNoLabel = ($FormattedSize -replace '\s[a-z]{1,2}$', '').Trim()
                [String] $FormattedSizeLabel = ($FormattedSize -replace '^[\d\.]{1,1026}\s', '').Trim()
                if($FormattedSizeNoLabel.Length -gt $FilesizeMaxLength){
                    $FilesizeMaxLength = $FormattedSizeNoLabel.Length
                }

                $Filename = ($FileDisplay -eq 'FullPath') ? $File.FullName : $File.BaseName
                $DateMeasurement = ($DateMethod -eq 'LastWrite') ? $File.LastWriteTime : $File.CreationTime
                $Age = (New-TimeSpan -Start $DateMeasurement -End $DateToday).Days

                $AgeCondition = ($PSCmdlet.ParameterSetName -eq "Older") ? ($Age -gt $OlderThan) : ($Age -lt $NewerThan)

                if($AgeCondition){
                    $TotalSize += $File.Length
                    $FileObj = [PSCustomObject]@{
                        Size = $FormattedSizeNoLabel
                        SizeLabel = $FormattedSizeLabel
                        Age = ($Age -as [String]) + " Days"
                        Filename = $Filename
                    }
                    $FilesObjectList.Add($FileObj)
                }
            }

            $FinalObjectList = [List[Object]]@()

            foreach ($F in $FilesObjectList) {
                $FinalSize = "{0:D} {1}" -f $F.Size, $F.SizeLabel

                $DateProperty = ($DateMethod -eq 'LastWrite') ? "Date Modified" : "Date Created"
                $Obj = [PSCustomObject]@{
                    $DateProperty = $F.Age
                    "File Size"   = $FinalSize
                    "File Name"   = $F.Filename
                }

                $FinalObjectList.Add($Obj)
            }

            $ReportedSize = Format-FileSizeAuto -Bytes $TotalSize
            '{0} Files, {1} total' -f $FilesObjectList.Count, $ReportedSize

            $SortProperty = ($DateMethod -eq 'LastWrite') ? "Date Modified" : "Date Created"
            if($SortOrder -eq 'Descending'){
                $FinalObjectList | Sort-Object { [regex]::Replace($_.$SortProperty, '\d+', { $args[0].Value.PadLeft(20) }) } -Descending
            }
            else{
                $FinalObjectList | Sort-Object { [regex]::Replace($_.$SortProperty, '\d+', { $args[0].Value.PadLeft(20) }) }
            }

        }
    }
}