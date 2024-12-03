using module "..\..\Private\Completions\Completers.psm1"

using namespace Microsoft.Toolkit.Uwp.Notifications
using namespace System.Management.Automation

function Show-UWPToastNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $Title,

        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateCount(1,3)]
        [string[]] $Description,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Logo,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName)]
        [ValidateSet([ValidateUWPAdaptiveImageCrop],ErrorMessage = "Value '{0}' is invalid. Try one of: {1}")]
        [string] $LogoCrop = [AdaptiveImageCrop]::Circle,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName)]
        [string] $LogoAlternateText,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $InlineImage,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName)]
        [Switch] $AddDismissButton

    )

    begin {
        $ContentBuilder = [Microsoft.Toolkit.Uwp.Notifications.ToastContentBuilder]::new()
    }

    process {

        $ContentBuilder.AddText($Title, $null, $null, $null, $null, $null) | Out-Null

        if($Description){
            foreach ($Line in $Description) {
                $ContentBuilder.AddText($Line, $null, $null, $null, $null, $null) | Out-Null
            }
        }

        if($Logo) {
            if($Logo | Test-Path){
                if ($LogoAlternateText) {
                    $ContentBuilder.AddAppLogoOverride($Logo, $LogoCrop, $LogoAlternateText) | Out-Null
                } else {
                    $ContentBuilder.AddAppLogoOverride($Logo, $LogoCrop) | Out-Null
                }
            } else {
                Write-Warning "Supplied Toast Logo does not exist."
            }
        }

        if($InlineImage -and ($InlineImage | Test-Path)){
            $ContentBuilder.AddInlineImage($InlineImage) | Out-Null
        }

        if($AddDismissButton){
            $DismissButton = [ToastButtonDismiss]::new("Dismiss")
            $ContentBuilder.AddButton($DismissButton) | Out-Null
        }

        $ContentBuilder.Show()
    }
}