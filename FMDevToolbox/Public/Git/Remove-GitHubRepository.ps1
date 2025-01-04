function Remove-GitHubRepository {
    <#
    .SYNOPSIS
    Removes a GitHub repository using the GitHub CLI.

    .DESCRIPTION
    The `Remove-GitHubRepository` function deletes a specified GitHub repository by navigating to its local directory and executing the `gh repo delete` command. It supports both path and literal path inputs, allowing for flexible input methods. The function checks for required tools (`gh.exe` and `git.exe`) and ensures that the specified directories are valid Git repositories before attempting deletion.

    .PARAMETER Path
    Specifies the path to one or more locations of GitHub repositories. Supports wildcards.

    .PARAMETER LiteralPath
    Specifies the literal path to one or more locations of GitHub repositories. Does not support wildcards and requires absolute paths.

    .PARAMETER Force
    If specified, the function will bypass confirmation prompts when deleting repositories.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to remove a GitHub repository using a wildcard path.
    Remove-GitHubRepository -Path "C:\Projects\*" -Force

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to remove a specific GitHub repository using a literal path.
    Remove-GitHubRepository -LiteralPath "C:\Projects\MyRepo" -Force

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to remove a GitHub repository interactively without forcing.
    Remove-GitHubRepository -Path "C:\Projects\AnotherRepo"

    .OUTPUTS
    Outputs a custom object containing the folder path, repository name, success status, and any error messages.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 12-05-2024
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName='Path')]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
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
            ValueFromPipeline,
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
        [Switch] $Force
    )

    begin {
        $GHCmd = Get-Command gh.exe -CommandType Application -ErrorAction SilentlyContinue
        if(-not$GHCmd){ Write-Error "gh.exe (GitHub CLI) isn't available in PATH. Aborting."; return }

        $GitCmd = Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue
        if(-not$GitCmd){ Write-Error "git.exe (Git) isn't available in PATH. Aborting."; return }
    }

    process {
        [Object[]] $Resolved = ($PSCmdlet.ParameterSetName -eq 'Path') ?
            ($Path | Get-Item -Force) : ($LiteralPath | Get-Item -Force)

        function Assert-Error {
            param (
                [String] $Message,
                [ref] $Return
            )
            Pop-Location -StackName GithubCLI
            Write-Error $Message
            $Return.Value.Error = $Message
            Write-Output $Return.Value
        }

        foreach ($GHFolder in $Resolved) {
            $Folder = $GHFolder.FullName
            $ReturnObject = [PSCustomObject]@{
                RepoFolder = $Folder
                RepoName = ""
                Success = $false
                Error = ""
            }
            Push-Location -Path $Folder -StackName GithubCLI
            if(-not($GHFolder.PSIsContainer)){
                Assert-Error "Passed folder ($Folder) is not a directory." -Return ([ref]$ReturnObject)
                continue
            }
            $GitDir = [System.IO.Path]::Combine($Folder, '.git')
            if (-not(Test-Path -LiteralPath $GitDir -PathType Container)) {
                Assert-Error "Passed folder is not a Git repository." -Return ([ref]$ReturnObject)
                continue
            }
            $GitConfigPath = [System.IO.Path]::Combine($Folder, '.git', 'config')
            if(-not(Test-Path -LiteralPath $GitConfigPath -PathType Leaf)){
                Assert-Error "Passed git repository lacks a config file." -Return ([ref]$ReturnObject)
                continue
            }
            $ConfigFileContent = Get-Content $GitConfigPath
            if(-not($ConfigFileContent)){
                Assert-Error "Unable to retrieve git config contents. ($GitConfigPath)" -Return ([ref]$ReturnObject)
                continue
            }
            if(-not($ConfigFileContent -match 'url = (git@|https:\/\/)github.com\/(.*).git')){
                Assert-Error "Repo is not a github repo. ($Folder)" -Return ([ref]$ReturnObject)
                continue
            }
            try {
                $GitOriginParams = '-C', $Folder, 'remote', 'get-url', 'origin'
                $RepoOriginURL = & $GitCmd $GitOriginParams
            }
            catch {
                Assert-Error "An error occurred retrieving Origin URL." -Return ([ref]$ReturnObject)
                continue
            }
            if(-not$RepoOriginURL){
                Assert-Error "Returned Origin URL is empty." -Return $ReturnObject
                continue
            }
            $RepoName = $RepoOriginURL -replace '^.+\/(.+?)(\.git)?$','$1'
            if(-not$RepoName){
                Assert-Error "Failed to get GitHub repository name. ($Folder)" -Return ([ref]$ReturnObject)
                continue
            }
            else {
                $ReturnObject.RepoName = $RepoName
            }

            try {
                if ($PSCmdlet.ShouldProcess($GHFolder, "Delete GitHub Origin (gh repo delete)")) {
                    Write-Verbose "Calling 'gh.exe repo delete'"
                    $GHParams = @('repo', 'delete', "$RepoName")
                    if($Force) { $GHParams += '--yes'}
                    & $GHCmd $GHParams | Out-Null
                }
                Write-Verbose "Last exit code: $LASTEXITCODE"
            }
            catch {
                Assert-Error "Unknown error deleting $RepoName with gh.exe. Details: $_" -Return ([ref]$ReturnObject)
                continue
            }

            Pop-Location -StackName GithubCLI
            [PSCustomObject]@{
                RepoFolder = $Folder
                RepoName = $RepoName
                Success = $true
                Error = ""
            } | Write-Output
        }
    }
    end {}
}
