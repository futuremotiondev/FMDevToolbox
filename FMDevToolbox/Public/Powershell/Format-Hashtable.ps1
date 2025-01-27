function Format-Hashtable {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    param (
        [Parameter(
            Mandatory,
            Position=0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "A single or array of hashtables to format into a string."
        )]
        [Alias('Hash',"h")]
        [ValidateNotNullOrEmpty()]
        [Hashtable[]] $Hashtable,

        [Parameter(
            Position=1,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Whether to format the hashtable as a single-line string, or multi-line string."
        )]
        [ValidateSet('SingleLine','MultiLine')]
        [Alias('Output',"Format","o")]
        [ValidateNotNullOrEmpty()]
        [String] $OutputFormat = 'SingleLine',

        [Parameter(HelpMessage = "Whether to use PwshSpectreConsole to colorize the output. Requires PwshSpectreConsole to be installed.")]
        [Switch] $UseSpectreColoring,

        [Parameter(HelpMessage = "Defines the colors to use for each part when -UseSpectreColoring is set.")]
        [Hashtable] $SpectreColorTheme = @{
            Brackets         = "#666B74"
            Keys             = "#FFFFFF"
            Values           = "#7EA5FF"
            EqualsSign       = "#9097A3"
            SingleLineColons = "#9097A3"
        }
    )

    begin {
        function Validate-ColorTheme {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory,Position=0)]
                [Alias("t")] [Hashtable] $Theme
            )
            $Theme.Keys | % { if(-not($Theme[$_] -match '^#[0-9A-Fa-f]{6}$')){return $false} }
            return $true
        }
        if(-not(Validate-ColorTheme -t $SpectreColorTheme)){
            throw "Invalid color format in -SpectreColorTheme: Colors must be in the format '#RRGGBB'."
        }
    }

    process {

        function SEscape {
            param (
                [Parameter(Mandatory,Position=0)]
                [String] $Text
            )
            $Text | Get-SpectreEscapedText
        }

        if($UseSpectreColoring){
            if(Confirm-ModuleIsAvailable -Name PwshSpectreConsole){
                Import-Module -Name PwshSpectreConsole -Force
                $BColor = $SpectreColorTheme.Brackets
                $KColor = $SpectreColorTheme.Keys
                $VColor = $SpectreColorTheme.Values
                $EColor = $SpectreColorTheme.EqualsSign
                $CColor = $SpectreColorTheme.SingleLineColons
            }
            else {
                Write-Warning "PwshSpectreConsole is not available to import. Ensure it's installed. Falling back to non-colored output."
                $UseSpectreColoring = $false
            }
        }

        $Hashtable | % {
            $enum = $_.GetEnumerator()
            if($OutputFormat -eq 'SingleLine'){
                if($UseSpectreColoring){
                    $OpenBracket = "[$BColor]@{ [/]"
                    $EqualsSign = "[$EColor]=[/]"
                    $CloseBracket = " [$BColor]}[/]"
                    $spectreString = $OpenBracket + (@($enum | % {(
                        "{0} $EqualsSign '{1}'" -f
                            ("[$KColor]$(SEscape $_.Key)[/]"),
                            ("[$VColor]$(SEscape $_.Value)[/]")
                    )}) -join "; ") + $CloseBracket
                    Write-SpectreHost -Message $spectreString
                }
                else {
                    $outputString = "@{ " + (@($enum | % {
                        ('{0} = ''{1}''' -f $_.Key, $_.Value)
                    }) -join '; ') + " }"
                    $outputString
                }
            }
            else {
                if($UseSpectreColoring){
                    $spectreString = "[$BColor]@{[/]`n" + (@($enum | % {
                        ("    [$KColor]{0}[/] [$EColor]=[/] [$VColor]'{1}'[/]" -f
                        $($_.Key | Escape), $($_.Value | Escape) )
                    }) -join "`n") + "`n[$BColor]}[/]"
                    Write-SpectreHost -Message $spectreString
                }
                else {
                    $outputString = "@{`n" + (@($enum | % {
                        ('    {0} = ''{1}''' -f $_.Key, $_.Value)
                    }) -join "`n") + "`n}"
                    $outputString
                }
            }
        }
    }
    end {}
}