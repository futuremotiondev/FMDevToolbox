function Confirm-NodeInstallationType {
[CmdletBinding()]
    [OutputType([String])]
    param()

    $nvmObject = Confirm-NVMForWindowsIsInstalled -AsObject
    $nodeObject = Confirm-NodeJSNormalInstall -AsObject

    if($nvmObject.Installed -eq $true -and $nvmObject.Valid -eq $true){
        return "NVMForWindows"
    }
    elseif(($nodeObject.Installed -eq $true) -and ($nodeObject.Valid -eq $true)) {
        return "NormalInstall"
    }
    else {
        return "NoValidInstallations"
    }
}