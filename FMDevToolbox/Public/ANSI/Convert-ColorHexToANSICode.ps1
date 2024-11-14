function Convert-ColorHexToANSICode {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage="Specify an HTML hex color code like #FFFFFF")]
        [ValidatePattern('^#[A-Fa-f0-9]{6}$')]
        [string] $HTMLHex
    )
    process {
        $Code = [System.Drawing.ColorTranslator]::FromHtml($HTMLHex)
        $ANSI = '38;2;{0};{1};{2}' -f $Code.R, $Code.G, $Code.B
        return $ANSI
    }
}
