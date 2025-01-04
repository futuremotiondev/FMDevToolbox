using namespace System.Security.Principal
function Test-IsAdmin {
    ([WindowsPrincipal]::new([WindowsIdentity]::GetCurrent())
    ).IsInRole([WindowsBuiltInRole]::Administrator)
}