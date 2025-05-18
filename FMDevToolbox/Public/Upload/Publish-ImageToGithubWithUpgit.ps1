using namespace System.Collections.Generic
using namespace System.IO

function Publish-ImageToGithubWithUpgit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if(Test-Path $_ -PathType Container){
                throw "Folder was passed. This parameter only accepts files."
            }
            $true
        })]
        [String[]] $File,
        [String] $RemoteDirectory,
        [Switch] $Markdown,
        [Switch] $HTML,
        [String] $ImageWidth,
        [String] $ImageHeight,
        [ArgumentCompletions('{OriginalFilename}', '{RemoteFilename}')]
        [String] $ImageAlt = '{OriginalFilename}',
        [ValidateSet('Default','Left','Center','Right')]
        [String] $ImageAlignment = 'Default',
        [Switch] $OpenInBrowser
    )

    begin {

        $embeddableImageFiles = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg')
        $embeddableVideoFiles = @('.mp4', '.webm', '.ogg')

        $filesToUpload = @()
        [PSCustomObject[]] $finalUrls = @()

        $invalidPathChars = [System.IO.Path]::GetInvalidPathChars()
        if($RemoteDirectory -and ($RemoteDirectory.IndexOfAny($invalidPathChars) -ne -1)){
            throw "Passed remote directory contains invalid characters."
        }

        try { $cmdUpgit = Get-Command upgit.exe -CommandType Application }
        catch { throw "upgit.exe can't be found in PATH." }

        function Get-ImageEmbed {
            param (
                [Parameter(Mandatory,ParameterSetName="Markdown",Position=0)]
                [Parameter(Mandatory,ParameterSetName="HTML",Position=0)]
                [string] $ImageUrl,
                [Parameter(Mandatory,ParameterSetName="Markdown",Position=1)]
                [Switch] $Markdown,
                [Parameter(Mandatory,ParameterSetName="HTML",Position=1)]
                [Switch] $HTML,
                [string] $ImageAlt,
                [String] $ImageWidth,
                [String] $ImageHeight,
                [ValidateSet('Default','Left','Center','Right')]
                [String] $ImageAlign
            )

            begin {
                if($ImageWidth -and ($ImageWidth -notmatch '^\s*$|^\d+(px|%)$')){
                    throw "Image width must be an integer followed by either 'px' or '%'"
                }
                if($ImageHeight -and ($ImageHeight -notmatch '^\s*$|^\d+(px|%)$')){
                    throw "Image height must be an integer followed by either 'px' or '%'"
                }
            }
            process {
                $imageEncoded = [Web.HttpUtility]::HTMLEncode($ImageURL)
                if(-not $ImageAlt){
                    $ImageAlt = [Path]::GetFileNameWithoutExtension((Split-Path $ImageUrl -Leaf))
                }
                if($PSCmdlet.ParameterSetName -eq 'Markdown'){
                    return [string]("![{0}]({1})" -f $ImageAlt, $imageEncoded)
                }
                if($PSCmdlet.ParameterSetName -eq 'HTML'){
                    $htmlGithub = '<img src="{0}" alt="{1}"' -f $imageEncoded, $ImageAlt
                    if($ImageWidth){
                        $htmlGithub = "$htmlGithub width={0}" -f $ImageWidth
                    }
                    if($ImageHeight){
                        $htmlGithub = "$htmlGithub height={0}" -f $ImageHeight
                    }
                    $htmlGithub = "${htmlGithub}>"
                    if($ImageAlign -and ($ImageAlign -ne 'Default')){
                        $htmlGithub = "<p align=`"{0}`">`r`n   {1}`r`n{2}" -f $ImageAlign.ToLower(), $htmlGithub, '</p>'
                    }
                    return $htmlGithub
                }
            }
        }
    }

    process {
        if ($RemoteDirectory) {
            $upgitParams = @('--target-dir', "$RemoteDirectory")
        }
        $upgitParams += '--size-limit', "0", '-r', '-n', '-u', 'github'
        foreach ($curFile in $File) {
            $filesToUpload += [WildcardPattern]::Escape($curFile)
        }
    }

    end {
        foreach ($Item in $filesToUpload) {

            $originalFilename = [System.IO.Path]::GetFileName($Item)
            $returnUrl = & $cmdUpgit $upgitParams $Item

            $tempObject = [PSCustomObject]@{
                RemoteUrl      = $returnUrl
                RemoteFilename = [System.IO.Path]::GetFileName($returnUrl)
                OriginalName   = $originalFilename
                Extension      = [System.IO.Path]::GetExtension($returnUrl)
            }
            $finalUrls += $tempObject
        }

        foreach ($finalUrl in $finalUrls) {
            Write-Host "$($finalUrl.RemoteUrl)"
            $altText = switch($ImageAlt){
                '{OriginalFilename}' { [System.IO.Path]::GetFileNameWithoutExtension(($finalUrl.OriginalName)) }
                '{RemoteFilename}' { [System.IO.Path]::GetFileNameWithoutExtension(($finalUrl.RemoteFilename)) }
                default {
                    if(-not[string]::IsNullOrWhiteSpace($ImageAlt)){ $ImageAlt }
                    else{ $finalUrl.OriginalName }
                }
            }
            if($Markdown){
                $finalUrlMd = Get-ImageEmbed -ImageUrl $finalUrl.RemoteUrl -Markdown -ImageAlt $altText
                Write-Host "── $finalUrlMd"
            }
            if($HTML){
                $getImageEmbedSplat = @{
                    ImageUrl    = $finalUrl.RemoteUrl
                    HTML        = $true
                    ImageAlt    = $altText
                    ImageWidth  = $ImageWidth
                    ImageHeight = $ImageHeight
                    ImageAlign  = $ImageAlignment
                }
                $finalUrlHtml = Get-ImageEmbed @getImageEmbedSplat
                Write-Host "── $finalUrlHtml"
            }
        }

        if($OpenInBrowser){
            foreach ($finalUrl in $finalUrls) {
                explorer.exe $finalUrl
            }
        }
    }
}