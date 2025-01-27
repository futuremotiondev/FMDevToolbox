function Show-HorizontalLineInConsole {
    param (
        [string] $RuleCharacter = "─",
        [String] $ForeColor="#4B5056",
        [Int32] $Width = $Host.UI.RawUI.WindowSize.Width,
        [Switch] $ShortenLineByOneCharacter
    )

    if(-not$ShortenLineByOneCharacter){
        $OutputWidth = (-not($Width)) ? '80' : ($Width - 1)
        Write-SpectreHost "[$ForeColor]$($RuleCharacter * $OutputWidth)[/]"
    }
    else {
        $OutputWidth = (-not($Width)) ? '80' : ($Width - 3)
        Write-SpectreHost " [$ForeColor]$($RuleCharacter * $OutputWidth)[/]"
    }

}