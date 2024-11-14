function Show-HorizontalLineInConsole {
    param (
        [string] $RuleCharacter = "─",
        [String] $ForeColor="#828282",
        [Int32] $Width = $Host.UI.RawUI.WindowSize.Width
    )

    $OutputWidth = (-not($Width)) ? '80' : ($Width - 1)
    Write-SpectreHost "[$ForeColor]$($RuleCharacter * $OutputWidth)[/]"
}

Register-ArgumentCompleter -CommandName Show-HorizontalLineInConsole -ParameterName ForeColor -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $options = [Spectre.Console.Color] | Get-Member -Static -Type Properties | Select-Object -ExpandProperty Name
    return $options | Where-Object { $_ -like "$wordToComplete*" }
}