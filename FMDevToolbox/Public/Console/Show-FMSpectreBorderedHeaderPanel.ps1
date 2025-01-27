using module "..\..\Private\Completions\FMCompleters.psm1"
using namespace Spectre.Console
function Show-FMSpectreBorderedHeaderPanel {
    [CmdletBinding()]
    param (
        [Parameter( Mandatory, Position=0, HelpMessage = "The message to display within the panel." )]
        [ValidateNotNullOrEmpty()]
        [String] $Message,

		[Parameter( HelpMessage = "If set, all Spectre color markup will be ignored and the message will be displayed as-is." )]
		[Switch] $DisableSpectreMarkup,

        [Parameter( HelpMessage = "The border type of the displayed panel." )]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Square','Rounded','None','Heavy','Double','Ascii')]
        [String] $BorderType = 'Rounded',

        [CompletionsSpectreColors()]
        [String] $BorderColor = '#7D8084',

        [Parameter( HelpMessage = "The width of the displayed panel in the console." )]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('QuarterWidth', 'HalfWidth', 'ThreeQuarterWidth', 'FullWidth')]
        [String] $PanelWidth = 'FullWidth',

        [Parameter( HelpMessage = "The height of the displayed panel in the console." )]
        [ValidateNotNull()]
        [ValidateSet('Small', 'Medium', 'Large', 'ExtraLarge', 'Huge')]
        [String] $PanelHeight = 'Medium',


        [Parameter( HelpMessage = "The header of the displayed panel in the console. If empty, no header is displayed." )]
        [ValidateNotNullOrEmpty()]
        [String] $Header

    )

    if(Confirm-ModuleIsAvailable -Name PwshSpectreConsole){
        Import-Module -Name PwshSpectreConsole -Force
    }

	# Create short labels for height and width to make code more compact.
    $hlbl = switch($PanelHeight) { 'Small' {'sm'}; 'Medium' {'md'}; 'Large' {'lg'}; 'ExtraLarge' {'xl'}; 'Huge' {'xxl'}; }
	$wlbl = switch($PanelWidth)  { 'QuarterWidth' {'qw'}; 'HalfWidth' {'hw'}; 'ThreeQuarterWidth' {'tqw'}; 'FullWidth' {'fw'}; }

	# Escape the message if -DisableSpectreMarkup is set.
	if($PSBoundParameters.ContainsKey('DisableSpectreMarkup')){ $Message = $Message | Get-SpectreEscapedText }

	# Create shortcodes for newline character, space character, and console width.
	[String] $n = "`n"; [String] $s = ' '; [Int32] $c = $Host.UI.RawUI.WindowSize.Width;

	# Calculate final spaces, newlines needed, and panel width.
	$sp  = switch ($hlbl) { 'sm' {''}; 'md' {$s*1}; 'lg' {$s*2}; 'xl' {$s*3}; 'xxl' {$s*7}; }
	$nl  = switch ($hlbl) { 'sm' {''}; 'md' {$n*1}; 'lg' {$n*2}; 'xl' {$n*3}; 'xxl' {$n*4}; }
	$he  = switch ($hlbl) { 'sm' {3};  'md' {5};    'lg' {7};    'xl' {9};    'xxl'{11};    }
    $wd  = switch ($wlbl) { 'qw' {$c / 4}; 'hw' {$c / 2}; 'tqw' {($c / 4)*3}; 'fw' {$c};    }
    $bc = $BorderColor; $bt = $BorderType;

    # Create the splat for the Spectre Panel
    $pSplat = @{ Data = "${nl}${sp}${Message}"; Border = $bt; Color  = $bc; Height = $he }
    if($wlbl -eq 'fw'){ $pSplat['Expand'] = $true }
    else {$pSplat['Width'] = $wd}
    if($PSBoundParameters.ContainsKey('Header')){ $pSplat['Header'] = $Header }
    Format-SpectrePanel @pSplat

}





