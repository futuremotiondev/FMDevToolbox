using namespace System.Security.Principal
function Test-IsElevated {
    [WindowsIdentity]::GetCurrent().Owner.IsWellKnown(
        [WellKnownSidType]::BuiltinAdministratorsSid
    )
}