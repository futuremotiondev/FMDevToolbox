function Add-GUIAssembliesAndEnableVisualStyles {
    [CmdletBinding()]
    param()

    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Continue
    Add-Type -LiteralPath "$script:ModuleAssemblyRoot\Ookii.Dialogs.WinForms.4.0.0\net6.0-windows7.0\Ookii.Dialogs.WinForms.dll" -ErrorAction Continue
    $DPICode =
@"
    [System.Runtime.InteropServices.DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
"@
    $Win32Helpers = Add-Type -MemberDefinition $DPICode -Name "Win32Helpers" -PassThru -ErrorAction Continue
    $null = $Win32Helpers::SetProcessDPIAware()
    [System.Windows.Forms.Application]::EnableVisualStyles()
}