function Add-UWPNotificationsAssembly {
    [CmdletBinding()]
    param()
    Add-Type -LiteralPath "$script:LibRoot\Microsoft.Toolkit.Uwp.Notifications.7.1.3\net5.0-windows10.0.17763\Microsoft.Toolkit.Uwp.Notifications.dll" -ErrorAction Continue
    Add-Type -LiteralPath "$script:LibRoot\Microsoft.Windows.SDK.NET.Ref.10.0.26100.34\net6.0\Microsoft.Windows.SDK.NET.dll" -ErrorAction Continue
}