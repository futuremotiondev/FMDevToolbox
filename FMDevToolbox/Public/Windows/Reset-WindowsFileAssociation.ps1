function Reset-WindowsFileAssociation {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            Position=0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "The file type extension that you would like to reset."
        )]
        [String[]] $Extension
    )

    begin {
        $cmd = Get-Command cmd.exe -CommandType Application -ErrorAction Stop
    }
    process {
        $Extension | % {
            $ext = ".{0}" -f ($_.TrimStart('.'))
            $assocParams = "/c", "assoc", "$ext="
            & $cmd $assocParams | Out-Null
            $RegKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$ext"
            try {
                Write-Verbose "Removing registry value '$RegKey'"
                Remove-Item -LiteralPath $RegKey -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
            }
            catch {
                throw "A problem occurred removing the registry key for .$ext. ($RegKey) Details: $_ "
            }
        }
    }
}