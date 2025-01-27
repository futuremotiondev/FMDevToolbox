function Invoke-OokiiTaskDialog {
    [CmdletBinding()]
    param (

        [String] $MainInstruction="Please select an option",
        [String] $MainContent = "Laboris labore magna amet irure deserunt dolore non dolore duis.",

        [ValidateSet('Standard','CommandLinks','CommandLinksNoIcon')]
        [String] $MainButtonStyle = "CommandLinks",

        [Collections.ArrayList] $MainButtons,

        [ValidateSet('Warning','Error','Information', 'Shield')]
        [String] $MainIcon = "Information",

        [String] $WindowTitle = "Please select an option",
        [String] $FooterText = "This is predefined footer text. <a href=`"https://www.stackoverflow.com`">stackoverflow.com</a>",

        [ValidateSet('Warning','Error','Information', "Shield")]
        [String] $FooterIcon = "Information",

        [String] $CustomFooterIcon,
        [String] $ExpandedInfo = "Additional related or expanded information goes here.",

        [ValidateSet('Top','Bottom')]
        [String] $ExpandedInfoPosition = "Bottom",

        [String] $ExpandedText = "Hide additional information",
        [String] $CollapsedText = "Show additional information",

        [Int32] $DialogWidth=0,
        [String] $CustomWindowIcon,
        [switch] $ShowMinimize,
        [switch] $AllowCancel,
        [switch] $ExpandedInfoOpenByDefault,
        [switch] $Modal,
        [switch] $DisableLinksInFooter

    )

    Add-GUIAssembliesAndEnableVisualStyles

    $CheckValidICO = {
        param (
            [Parameter(Mandatory)]
            [String] $IcoPath
        )
        if (Test-Path -LiteralPath $IcoPath -PathType Leaf){
            if([IO.Path]::GetExtension($IcoPath) -eq '.ico'){
                return $true
            }
        }
        return $false
    }

    $MainDialog = New-Object Ookii.Dialogs.WinForms.TaskDialog
    if($MainButtons) { $MainButtons = $MainButtons.Clone() }
    if(($MainButtons).Length -eq 0){
        $ContinueBtn = [Ookii.Dialogs.WinForms.TaskDialogButton]::New("Continue")
        $ContinueBtn.CommandLinkNote = "Proceed with new changes"
        $ContinueBtn.ElevationRequired = $true
        $CancelButton = [Ookii.Dialogs.WinForms.TaskDialogButton]::New("Cancel")
        $CancelButton.CommandLinkNote = "Cancel all current changes"
        $CancelButton.Default = $true
        $MainDialog.Buttons.Add($ContinueBtn)
        $MainDialog.Buttons.Add($CancelButton)
    }else{
        foreach ($Btn in $MainButtons) {
            $MainDialog.Buttons.Add($Btn)
        }
    }

    $MainDialog.MainInstruction         = $MainInstruction
    $MainDialog.Content                 = $MainContent
    $MainDialog.ButtonStyle             = $MainButtonStyle
    $MainDialog.ExpandedInformation     = $ExpandedInfo
    $MainDialog.ExpandedByDefault       = $ExpandedInfoOpenByDefault
    $MainDialog.CollapsedControlText    = $CollapsedText
    $MainDialog.ExpandedControlText     = $ExpandedText
    $MainDialog.MinimizeBox             = $ShowMinimize
    $MainDialog.Width                   = $DialogWidth
    $MainDialog.AllowDialogCancellation = $AllowCancel
    $MainDialog.WindowTitle             = $WindowTitle

    $MainDialog.ExpandFooterArea = if($ExpandedInfoPosition -eq 'Top') { $false } else { $true }
    $MainDialog.MainIcon = $MainIcon

    if($FooterText) { $MainDialog.Footer = $FooterText}

    if($DisableLinksInFooter) {
        $MainDialog.EnableHyperlinks = $false
    }else{
        $MainDialog.EnableHyperlinks = $true
        $MainDialog.add_HyperlinkClicked({
            Start-Process $_.href
        })
    }

    if($CustomFooterIcon) {
        $IsValidFooterIco = & $CheckValidICO $CustomFooterIcon
        if($IsValidFooterIco){
            $MainDialog.FooterIcon = ""
            $MainDialog.FooterIcon = $CustomFooterIcon
            Write-Verbose "Custom footer icon was supplied and valid ($CustomFooterIcon)."
        } else {
            Write-Verbose "Custom footer Icon is not valid. Reverting to icon specified by -FooterIcon ($FooterIcon)"
            $MainDialog.FooterIcon = $FooterIcon
        }
    }

    $DefaultWindowIconB64 = 'AAABAAEAEBAAAAEAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAQAAMMOAADDDgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAISEhpyEhIb8hISG/ISEhvyEhIb8hISG/ISEhvyEhIb8hISG/ISEhvyEhIb8hISG/ISEhvyEhIb8hISG/ISEhpyEhIb8hISH/ISEh/yEhIf8hISH/ISEh/yEhIf8hISH/ISEh/yEhIf8hISH/ISEh/yEhIf8hISH/ISEh/yEhIb8hISG/ISEh/x4eHhkeHh4ZHh4eGR4eHhkhISH/Hh4eGR4eHhkeHh4ZHh4eGR4eHhkeHh4ZHh4eGSEhIf8hISG/ISEhvyEhIf8eHh4ZHh4eGR4eHhkeHh4ZISEh/x4eHhkeHh4ZHh4eGR4eHhkeHh4ZHh4eGR4eHhkhISH/ISEhvyEhIb8hISH/Hh4eGR4eHhkeHh4ZHh4eGSEhIf8eHh4ZHh4eGR4eHhkeHh4ZHh4eGR4eHhkeHh4ZISEh/yEhIb8hISG/ISEh/x4eHhkeHh4ZHh4eGR4eHhkhISH/Hh4eGR4eHhkeHh4ZHh4eGR4eHhkeHh4ZHh4eGSEhIf8hISG/ISEhvyEhIf8eHh4ZHh4eGR4eHhkeHh4ZISEh/x4eHhkeHh4ZHh4eGR4eHhkeHh4ZHh4eGR4eHhkhISH/ISEhvyEhIb8hISH/Hh4eGR4eHhkeHh4ZHh4eGSEhIf8eHh4ZHh4eGR4eHhkeHh4ZHh4eGR4eHhkeHh4ZISEh/yEhIb8hISG/ISEh/x4eHhkeHh4ZHh4eGR4eHhkhISH/Hh4eGR4eHhkeHh4ZHh4eGR4eHhkeHh4ZHh4eGSEhIf8hISG/ISEhvyEhIf8hISH/ISEh/yEhIf8hISH/ISEh/yEhIf8hISH/ISEh/yEhIf8hISH/ISEh/yEhIf8hISH/ISEhvyEhIb8hISH/Hh4eGR4eHhkeHh4ZHh4eGR4eHhkeHh4ZHh4eGR4eHhkeHh4ZHh4eGR4eHhkeHh4ZISEh/yEhIb8hISG/ISEh/x4eHhkeHh4ZHh4eGR4eHhkeHh4ZHh4eGR4eHhkeHh4ZHh4eGR4eHhkeHh4ZHh4eGSEhIf8hISG/ISEhvyEhIf8hISH/ISEh/yEhIf8hISH/ISEh/yEhIf8hISH/ISEh/yEhIf8hISH/ISEh/yEhIf8hISH/ISEhvyEhIachISG/ISEhvyEhIb8hISG/ISEhvyEhIb8hISG/ISEhvyEhIb8hISG/ISEhvyEhIb8hISG/ISEhvyEhIacAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//8AAA=='
    $DefaultWindowIconMemoryStream = [System.IO.MemoryStream]::New([System.Convert]::FromBase64String($DefaultWindowIconB64))
    $DefaultWindowIcon = [System.Drawing.Icon]::New($DefaultWindowIconMemoryStream)

    if($Modal) {
        $Result = $MainDialog.ShowDialog()
    }else{
        if($CustomWindowIcon){
            $IsValidFormIco = & $CheckValidICO $CustomWindowIcon
            if($IsValidFormIco){
                Write-Verbose "Custom window icon was supplied and valid ($CustomWindowIcon)."
                $MainDialog.WindowIcon = $CustomWindowIcon
            }
            else {
                Write-Verbose "Custom window Icon is not valid. Reverting to default window icon."
                $MainDialog.WindowIcon = $DefaultWindowIcon
            }
        }
        else {
            Write-Verbose "No custom window icon supplied. Using default window icon."
            $MainDialog.WindowIcon = $DefaultWindowIcon
        }
        $Result = $MainDialog.Show()
    }
    $Result
}