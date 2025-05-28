using namespace System.IO
using namespace System.Text.RegularExpressions

function Convert-JSXBINDecode {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Path to input js/jsx files to convert."
        )]
        [ValidateScript({$_ -notmatch '[\?\*]'},
            ErrorMessage = "Wildcard characters *, ? are not acceptable.")]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $InputFile,

        [Parameter(ValueFromPipelineByPropertyName, HelpMessage="Try renaming symbols which are obfuscated by 'JsxBlind' (experimental)")]
        [Switch] $UnBlind,

        [Parameter(ValueFromPipelineByPropertyName, HelpMessage="The file suffix to insert for decoded files.")]
        [ValidateScript({
            $invalidFileNameChars = [Path]::GetInvalidFileNameChars()
            $invalidPathChars = [Path]::GetInvalidPathChars()
            if ($_.IndexOfAny($invalidFileNameChars) -ne -1 -or $_.IndexOfAny($invalidPathChars) -ne -1) {
                throw "The provided output file suffix ($_) contains illegal characters."
            }
            $true
        })]
        [ValidateNotNullOrEmpty()]
        [String] $DecodedFileSuffix = "_decoded"
    )

    begin {
        $cmdJsxer = Get-Command jsxer.exe -CommandType Application -ErrorAction 0
        if(-not $cmdJsxer){
            throw "Can't find jsxer.exe in PATH."
        }
        $filesToProcess = @()
    }

    process {
        foreach ($file in $InputFile) {
            $filePath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($file).Trim().TrimEnd('\')
            if(-not (Test-Path $filePath -PathType Leaf)){
                continue
            }
            elseif(([System.IO.Path]::GetExtension($filePath)) -notin @('.js','.jsx')){
                Write-Warning "Non javascript file was passed ($file). Skipping."
                continue
            }
            else {
                $filesToProcess += $filePath
            }
        }
    }

    end {

        Write-Verbose "Final list of files to process: $filesToProcess"
        Write-Verbose "Number of files to process: $($filesToProcess.Count)"

        foreach ($file in $filesToProcess) {

            # Create output filename
            $fileObj = Get-Item -LiteralPath $file -Force -ErrorAction 0
            $fileOut = $file.Substring(0, $file.LastIndexOf('.'))
            $fileOut = "{0}{1}{2}" -f $fileOut, $DecodedFileSuffix, $fileObj.Extension
            $fileOut = Get-UniqueNameIfDuplicate -LiteralPath $fileOut

            # Populate parameters for JSXER
            $Params = '-o', $fileOut
            if($UnBlind){ $Params += '-b' }
            $Params += $file

            $ParamsVerbose = $Params -join ' '
            Write-Verbose "Calling JSXER (jsxer.exe $ParamsVerbose)"
            & $cmdJsxer $Params

        }
    }
}