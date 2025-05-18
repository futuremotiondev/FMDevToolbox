using namespace Microsoft.Win32

function Get-WindowsLicensingInformation {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    function GetProductKey {
        $map = "BCDFGHJKMPQRTVWXY2346789"
        try {
            $remoteReg = [RegistryKey]::OpenRemoteBaseKey([RegistryHive]::LocalMachine, $env:COMPUTERNAME)
            $PKeyVal = $remoteReg.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue('DigitalProductId')[0x34..0x42]
            $isWin8OrNewer = [math]::Floor(($PKeyVal[14] / 6)) -band 1
            $PKeyVal[14] = ($PKeyVal[14] -band 0xF7) -bor (($isWin8OrNewer -band 2) * 4)
            $PKey = ""
            for ($i = 24; $i -ge 0; $i--) {
                $r = 0
                for ($j = 14; $j -ge 0; $j--) {
                    $r = ($r * 256) -bxor $PKeyVal[$j]
                    $PKeyVal[$j] = [math]::Floor([double]($r / 24))
                    $r = $r % 24
                }
                $PKey = $map[$r] + $PKey
            }
        }
        catch {
            Write-Error "Error finding the product key. $_"
            $PKey = $_.Exception.Message
        }
        if ($isWin8OrNewer) {
            $PKey = ($PKey.Remove(0, 1)).Insert($r, 'N')
        }
        for ($i = 5; $i -lt 29; $i = $i + 6) {
            $PKey = $PKey.Insert($i, '-')
        }
        return $PKey
    }

    function GetLicenseExtendedDetails {
        $keys = @(
            'Name','Description','ApplicationId',
            'ProductKeyChannel','UseLicenseURL',
            'ValidationURL','ProductKeyID',
            'LicenseStatus','LicenseFamily'
        )
        $filter = 'PartialProductKey is not null'
        $className = 'SoftwareLicensingProduct'
        $lInfo = Get-CimInstance -ClassName $className -Filter $filter | Select $keys
        [PSCustomObject]@{
            LicenseName        = $lInfo.Name
            LicenseDescription = $lInfo.Description
            LicenseFamily      = $lInfo.LicenseFamily
            ProductKeyChannel  = $lInfo.ProductKeyChannel
            ApplicationID      = $lInfo.ApplicationId
            ProductKeyID       = $lInfo.ProductKeyID
            UseLicenseURL      = $lInfo.UseLicenseURL
            ValidationURL      = $lInfo.ValidationURL
        }
    }

    $productKey = GetProductKey
    $licDetails = GetLicenseExtendedDetails
    $winInfo = Get-WindowsVersionInformation

    [PSCustomObject]@{
        ComputerName         = $env:COMPUTERNAME
        ComputerRole         = $winInfo.ProductType
        WindowsVersion       = $winInfo.WindowsEdition
        WindowsVersionFull   = $winInfo.CompleteWindowsVersion
        ProductKey           = $productKey
        ProductKeyChannel    = $licDetails.ProductKeyChannel
        ProductKeyID         = $licDetails.ProductKeyID
        LicenseName          = $licDetails.LicenseName
        LicenseDescription   = $licDetails.LicenseDescription
        LicenseFamily        = $licDetails.LicenseFamily
        LicenseApplicationID = $licDetails.ApplicationID
        LicenseUseLicenseURL = $licDetails.UseLicenseURL
        LicenseValidationURL = $licDetails.ValidationURL
    }
}