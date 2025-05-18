using namespace System.Collections.Generic
using namespace System.IO

function Expand-ArchiveFilesToFolder {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "Path",
            HelpMessage="Path to one or more locations."
        )]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [String[]] $Path,

        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "LiteralPath",
            HelpMessage="Literal path to one or more locations."
        )]
        [ValidateScript({$_ -notmatch '[\?\*]'},
            ErrorMessage = "Wildcard characters *, ? are not acceptable with -LiteralPath")]
        [ValidateScript({[System.IO.Path]::IsPathRooted($_)},
            ErrorMessage = "Relative paths are not allowed in -LiteralPath.")]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [String[]] $LiteralPath,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            $invalidFileNameChars = [System.IO.Path]::GetInvalidFileNameChars()
            $invalidPathChars = [System.IO.Path]::GetInvalidPathChars()
            if ($_.IndexOfAny($invalidFileNameChars) -ne -1 -or $_.IndexOfAny($invalidPathChars) -ne -1) {
                throw "The passed filetype extension '$_' contains invalid characters."
            }
        })]
        [String] $OutputDirectory,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({
            $invalidFileNameChars = [System.IO.Path]::GetInvalidFileNameChars()
            $invalidPathChars = [System.IO.Path]::GetInvalidPathChars()
            if ($_.IndexOfAny($invalidFileNameChars) -ne -1 -or $_.IndexOfAny($invalidPathChars) -ne -1) {
                throw "The passed filetype extension '$_' contains invalid characters."
            }
        })]
        [ValidateNotNullOrEmpty()]
        [string[]] $FilterFiletypesByExtension,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Rename','Overwrite')]
        [String] $DuplicateFileStrategy = "Rename",

        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch] $DeleteArchiveAfterExtraction

    )

    begin {
        $cmd7z = Get-Command 7z.exe -CommandType Application -ErrorAction Ignore
        $cmdPa = Get-Command print_argv.exe -CommandType Application -ErrorAction Ignore
        if(-not($cmd7z)){
            throw "7z.exe cannot be found in PATH."
        }

        [string[]] $fileFilterArr = @()
        if(-not $FilterFiletypesByExtension){
            $fileFilterArr += "*.*"
        }
        else{
            foreach ($fileFilter in $FilterFiletypesByExtension) {
                $fileFilterArr += "*.$($fileFilter.TrimStart('.'))"
            }
        }

        if($OutputDirectory){
            if(-not([Path]::IsPathRooted($OutputDirectory))){
                $outputDir = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($OutputDirectory)
            }
            else {
                $outputDir = $OutputDirectory
            }
        }
        else {
            $outputDir = $null
        }
        $archiveList = [List[String]]@()
        $validExtensions = @('.zip','.rar','.7z','.tar','.gz','.gzip','.tgz','.dmg')
    }

    process {

        # Resolve paths based on provided parameters
        $resolvedArchives = if ($PSBoundParameters['Path']) {
            Get-Item -Path $Path -Force
        } elseif ($PSBoundParameters['LiteralPath']) {
            Get-Item -LiteralPath $LiteralPath -Force
        }

        # Filter and add valid archives to the list
        $resolvedArchives | Where-Object { $_.Extension -in $validExtensions }
            | % { $archiveList.Add($_.FullName) }

        # Return if no valid archives were passed to the function
        if($archiveList.Count -eq 0){
            Write-Warning "No valid archives were passed."
            return
        }
    }

    end {
        foreach ($curArchive in $archiveList) {
            if(-not $outputDir){
                $outputDir = [Directory]::GetParent($curArchive).FullName
            }
            $7zparams = 'e', $curArchive, "-o`"$outputDir`""
            $filetypeFilterArr | % {
                $7zparams += $_
            }
            $7zparams += '-r'
            if($DuplicateFileStrategy -eq 'Rename'){
                $7zparams += '-aot'
            }
            else {
                $7zparams += '-y'
            }
            # 7z.exe e "C:\Test\250515170RMNZXQ8.zip" -o"C:\Test" *.* -r -aot
            #& $cmd7z $7zparams | Out-Null
            & $cmdPa $7zparams | Out-Null
        }


    }
}