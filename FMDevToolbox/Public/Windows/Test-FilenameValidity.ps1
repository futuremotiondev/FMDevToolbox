using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.IO

function Test-FilenameValidity {
    [OutputType([Boolean],[PSCustomObject])]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage="The filenames to check for validity."
        )]
        [Alias('target','file','filename','t')]
        [ValidateNotNullOrEmpty()]
        [String[]] $TargetFilename,

        [Parameter(Position=1,ValueFromPipelineByPropertyName,HelpMessage="The return type." )]
        [ValidateSet('object','boolean')]
        [String] $OutputType = 'boolean'
    )

    begin {
        $invalidChars = [Path]::GetInvalidFileNameChars()
        $reservedNames = @( "CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5",
        "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7",
        "LPT8", "LPT9")
    }

    process {
        foreach ($fileName in $TargetFilename) {
            # Check for path-like characters or invalid characters
            if ([Path]::IsPathRooted($fileName)) {
                if($OutputType -eq 'object'){
                    [PSCustomObject]@{
                        PassedValue = $fileName
                        ValidFilename = $false
                        Description = "The passed value is a path, not a filename."
                    }
                }
                else { $false }
                continue
            }

            # Check for path-like characters or invalid characters
            if ($fileName.IndexOfAny($invalidChars) -ne -1) {
                if($OutputType -eq 'object'){
                    [PSCustomObject]@{
                        PassedValue = $Filename
                        ValidFilename = $false
                        Description = "The filename contains invalid characters."
                    }
                }
                else { $false }
                continue
            }

            # Check for reserved names
            $baseName = [Path]::GetFileNameWithoutExtension($fileName).ToUpperInvariant()
            if ($reservedNames -contains $baseName) {
                if($OutputType -eq 'object'){
                    [PSCustomObject]@{
                        PassedValue   = $fileName
                        ValidFilename = $false
                        Description = "The filename is a reserved windows name."
                    }
                }
                else { $false }
                continue
            }

            if($OutputType -eq 'object'){
                [PSCustomObject]@{
                    PassedValue = $fileName
                    ValidFilename = $true
                    Description = "Filename is valid."
                }
            }
            else { $true }
            continue
        }
    }
}