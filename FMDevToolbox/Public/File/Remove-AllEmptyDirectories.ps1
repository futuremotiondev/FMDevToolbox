using namespace System.Management.Automation
using namespace System.Collections.Generic
using namespace System.IO

function Remove-AllEmptyDirectories {
    [CmdletBinding(DefaultParameterSetName="Path")]
    param (

        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "Path",
            HelpMessage="Path to one or more directories."
        )]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [String[]] $Path,

        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "LiteralPath",
            HelpMessage="Literal path to one or more directories."
        )]
        [ValidateScript({
            if ($_ -match '[\?\*]') { throw "Wildcard chars are not acceptable." }
            if (-not [Path]::IsPathRooted($_)) { throw "Relative paths are not allowed." }
            $true
        })]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $DeleteFoldersWithEmptyFiles,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $DeleteFoldersWithMacOSJunkFiles


    )

    begin {
        $emptyFolderList = [List[String]]@()
    }

    process {
        $resolvedPaths = Get-Item -LiteralPath $LiteralPath -Force
        foreach ($resolvedItem in $resolvedPaths) {
            if($resolvedItem.PSIsContainer){
                if(((gci -LP $resolvedItem.FullName -File -Force -Recurse).Count) -gt 0){
                    Write-Verbose "$($resolvedItem.FullName) is not empty. Skipping."
                    continue
                }
                else {
                    $null = $emptyFolderList.Add($resolvedItem.FullName)
                }
            }
            else {
                Write-Warning "A file was passed instead of a folder ($resolvedItem). Skipping."
            }
        }
    }
    end {
        $emptyFolderList | % {
            try {
                rmdir -LP $_ -Force -Recurse
                New-Log -Message "Deleted empty folder $($_.FullName)." -Level SUCCESS
            }
            catch {
                New-Log -Message "Failed to delete empty folder $($_.FullName)." -Level ERROR
                $deleteFailureErrorRecord = [ErrorRecord]::New(
                    [System.Exception]::New("An error occurred deleting $($_.FullName)."),
                    'FileDeleteOperationFailed',
                    [ErrorCategory]::WriteError,
                    $_.FullName
                )
                $PSCmdlet.WriteError($deleteFailureErrorRecord)
            }
        }
    }
}