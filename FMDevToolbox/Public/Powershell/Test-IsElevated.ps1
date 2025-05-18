using namespace System.Security.Principal
function Test-IsElevated {
    param (
        [ValidateSet(1,2,3)]
        [Int32] $Method = 1
    )
    if($Method -eq 1){
        [WindowsIdentity]::GetCurrent().Owner.IsWellKnown(
            [WellKnownSidType]::BuiltinAdministratorsSid
        )
    }
    elseif($Method -eq 2){
        [bool](([WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
    }
}