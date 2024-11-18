using module "..\..\Private\Completions\Completers.psm1"
function Show-HorizontalLineInConsole {
    param (
        [string] $RuleCharacter = "─",
        [CompletionsSpectreColors()]
        [String] $ForeColor="#828282",
        [Int32] $Width = $Host.UI.RawUI.WindowSize.Width
    )

    $OutputWidth = (-not($Width)) ? '80' : ($Width - 1)
    Write-SpectreHost "[$ForeColor]$($RuleCharacter * $OutputWidth)[/]"
}