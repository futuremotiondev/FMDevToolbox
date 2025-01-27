function Invoke-OpenFileDialog {

    param(

        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path -LiteralPath $_})]
        [string]
        $Path = [Environment]::GetFolderPath("Desktop").TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar,

        [System.Environment+SpecialFolder]
        [Parameter(Mandatory=$false)]
        [string]
        $SpecialPath,

        [Parameter(Mandatory=$false)]
        [switch]
        $MultiSelect = $false,

        [Parameter(Mandatory=$false)]
        [string]
        $FilterString = 'All files (*.*)|*.*',

        [Parameter(Mandatory=$false)]
        [string]
        $Title = 'Select a file',

        [Parameter(Mandatory=$false)]
        [string]
        $DefaultExt

    )

    Add-GUIAssembliesAndEnableVisualStyles

    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog

    $FinalPath = $null
    if($SpecialPath){
        $FinalPath = [Environment]::GetFolderPath($SpecialPath)
    }else{
        $FinalPath = $Path
    }

    $FinalPath = $FinalPath.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    $FileBrowser.initialDirectory = $FinalPath
    $FileBrowser.filter = $FilterString
    $FileBrowser.MultiSelect = $MultiSelect
    if ($Title) { $FileBrowser.Title = $Title }
    if ($DefaultExt) { $FileBrowser.DefaultExt = $DefaultExt }

    $Result = $FileBrowser.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))

    if ($Result -eq 'OK') {
        if ($MultiSelect) {
            [array] $ReturnArray = $FileBrowser.FileNames
            return ($ReturnArray)
        } else {
            [array] $ReturnArray = $FileBrowser.FileName
            return ($ReturnArray)
        }
    }
}