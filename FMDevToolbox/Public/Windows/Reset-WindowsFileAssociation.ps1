function Reset-WindowsFileAssociation {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName,
            HelpMessage = "The file type extension that you would like to reset."
        )]
        [String[]] $Extension
    )

    begin {
        $cmd = Get-Command cmd.exe -CommandType Application -ErrorAction Stop
        Remove-PSDrive -PSProvider Registry -Name HKCR -Force -ErrorAction 0
        New-PSDrive -PSProvider Registry -Name HKCR -Root "HKEY_CLASSES_ROOT" | Out-Null
    }
    process {
        $Extension | % {
            $ext = ".{0}" -f ($_.TrimStart('.'))
            $assocParams = "/c", "ASSOC", "${ext}="

            Write-SpectreHost "`r`n[#B6BCC2]Running ASSOC ${ext}= [/]`r`n"
            & $cmd $assocParams

            $HKCUExt = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$ext"
            $HKCRExtension = "HKCR:\$ext"

            if (Test-Path -Path $HKCUExt) {
                New-Log "'$HKCUExt' exists." -Level SUCCESS
                $HKCUExtExists = $true
            } else {
                New-Log "'$HKCUExt' does not exist." -Level WARNING
                $HKCUExtExists = $false
            }

            if (Test-Path -Path $HKCRExtension) {
                New-Log "'$HKCRExtension' exists." -Level SUCCESS
                $HKCRExtensionExists = $true
            } else {
                New-Log "'$HKCRExtension' does not exist." -Level WARNING
                $HKCRExtensionExists = $false
            }

            if($HKCRExtensionExists){
                $HKCRExtensionDefaultValue = (Get-ItemProperty -Path $HKCRExtension -ErrorAction 0).'(default)'
                if(-not[String]::IsNullOrEmpty($HKCRExtensionDefaultValue)){
                    New-Log "'$HKCRExtension' has a default value of '$HKCRExtensionDefaultValue'." -Level SUCCESS
                    $HKCRExtensionDefaultValueExists = $true
                    $HKCRExtensionDefaultValueKey = "HKCR:\$HKCRExtensionDefaultValue"
                }
                else {
                    New-Log "'$HKCRExtension' does not have a default value." -Level WARNING
                    $HKCRExtensionDefaultValueExists = $false
                    $HKCRExtensionDefaultValueKey = $null
                }
            }

            if($HKCUExtExists){
                New-Log "[01] Removing registry value '${HKCUExt}'" -Level INFO
                Remove-Item -LiteralPath $HKCUExt -Force -Recurse
            }
            else {
                New-Log "[01] Skipping the removal of registry value '${HKCUExt}' as it does not exist" -Level INFO
            }

            if($HKCRExtensionDefaultValueExists){
                New-Log "[02] Removing registry value '${HKCRExtensionDefaultValueKey}'" -Level INFO
                Remove-Item -LiteralPath $HKCRExtensionDefaultValueKey -Force -Recurse
            }
            else {
                New-Log "[02] Skipping the removal of the default value key from '${$HKCRExtension}' as it does not exist." -Level INFO
            }

            if($HKCRExtensionExists){
                New-Log "[03] Removing registry value '${HKCRExtension}'" -Level INFO
                Remove-Item -LiteralPath $HKCRExtension -Force -Recurse
            }
            else {
                New-Log "[03] Skipping the removal of registry value '${HKCRExtension}' as it does not exist." -Level INFO
            }

            New-Log "File associations for '$ext' have been reset. Please restart explorer.exe to finalize the update." -Level SUCCESS
        }
    }
}