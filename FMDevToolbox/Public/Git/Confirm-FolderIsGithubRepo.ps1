function Confirm-FolderIsGithubRepo {
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [string[]] $Folder
    )

    process {
        foreach ($F in $Folder) {
            $gitConfigPath = Join-Path $F -ChildPath '.git\config'
            if(-not($gitConfigPath | Test-Path)){
                return $false
            } else {
                $gitConfig = Get-Content $gitConfigPath
            }
            if($gitConfig -match 'url = (git@|https:\/\/)github.com\/(.*).git'){
                return $true
            }
            $false
        }
    }
}