function Get-WindowsCurrentUserSID {
    [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
}