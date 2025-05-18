function Get-WindowsDefaultBrowser {
    try {
        $BrowserRegPath     = 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice'
        $DBrowserProgID     = (Get-Item $BrowserRegPath | Get-ItemProperty).ProgId
        $DBrowserCommand    = (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$DBrowserProgID\shell\open\command").'(default)'
        $DBrowserImagePath  = (([regex]::Match($DBrowserCommand,'\".+?\"')).Value).Trim('"')
        $DBrowserImage      = [System.IO.Path]::GetFileName($DBrowserImagePath)
    }
    catch {
        throw "Couldn't determine default browser. $_"
    }
    switch ($DBrowserProgID) {
        'IE.HTTP' {
            $DBrowserName = "Internet Explorer"
        }
        'ChromeHTML' {
            $DBrowserName = "Chrome"
        }
        'MSEdgeHTM' {
            $DBrowserName = "Microsoft Edge"
        }
        'FirefoxURL-308046B0AF4A39CB' {
            $DBrowserName = "Firefox"
        }
        'FirefoxURL-E7CF176E110C211B' {
            $DBrowserName = "Firefox"
        }
        'AppXq0fevzme2pys62n3e0fbqa7peapykr8v' {
            $DBrowserName = "Microsoft Edge"
        }
        'OperaStable' {
            $DBrowserName = "Opera"
        }
        default{
            $DBrowserName = "Unknown Browser"
        }
    }
    [PSCustomObject]@{
        Name           = $DBrowserName
        ProgID	       = $DBrowserProgID
        Image	       = $DBrowserImage
        ImagePath      = $DBrowserImagePath
        DefaultCommand = $DBrowserCommand
    }
}