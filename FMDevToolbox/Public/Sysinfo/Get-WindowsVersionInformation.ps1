using namespace Microsoft.Win32
using namespace System.Globalization
using namespace System.Security.Principal

function Get-WindowsVersionInformation {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    # TODO:
    # Look in to integrating this cmdlet:
    # Get-ComputerInfo
    # (Get-ComputerInfo -Property OsArchitecture).OsArchitecture

    function GetOSArchitectureAddressWidth {
        <#
        .SYNOPSIS
        Get the operating system architecture address width.

        .DESCRIPTION
        This will return the system architecture address width (probably 32 or
        64 bit). If you pass a comparison, it will return true or false instead
        of {`32`|`64`}.

        .NOTES
        When your installation script has to know what architecture it is run
        on, this simple function comes in handy.

        ARM64 architecture will automatically select 32bit width as
        there is an emulator for 32 bit and there are no current plans by Microsoft to
        ship 64 bit x86 emulation for ARM64. For more details, see
        https://github.com/chocolatey/choco/issues/1800#issuecomment-484293844.
        #>
        $procArch = $env:PROCESSOR_ARCHITECTURE
        $procArchW6432 = $env:PROCESSOR_ARCHITEW6432
        $bits = 64
        [bool] $IntPtrSizeIs4 = ([System.IntPtr]::Size -eq 4)
        if ($IntPtrSizeIs4 -and (Test-Path env:\PROCESSOR_ARCHITEW6432)) { $bits = 64 }
        elseif ($IntPtrSizeIs4) { $bits = 32 }
        if ($procArch -and $procArch -eq 'ARM64') { $bits = 32 }
        if ($procArchW6432 -and $procArchW6432 -eq 'ARM64') { $bits = 32 }
        return $bits
    }

    $regCurVers         = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    $cimToSelect        = 'OSArchitecture', 'Caption', 'ProductType', 'TotalPhysicalMemory', 'InstallDate', 'SerialNumber', 'RegisteredUser'
    $cimWin32           = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object $cimToSelect
    $cimWin32OSA        = $cimWin32.OSArchitecture
    $cimWin32CAP        = $cimWin32.Caption
    $cimWin32PTY        = $cimWin32.ProductType
    $cmdData            = ((& cmd /c ver) -as [String]).Trim()                # Microsoft Windows [Version 10.0.19045.5608]
    $verFull            = $cmdData -replace '^.*\[Version (.*)\]', '$1'       # 10.0.19045.5608
    $verMajor           = $verFull.Split('.')[0]                              # 10
    $verShort           = $verFull -replace '10\.0\.',''                      # 19045.5608
    $archRaw            = $cimWin32OSA                                        # 64-bit
    $arch               = "x$($archRaw.Split('-')[0])"                        # x64
    $displayV           = $regCurVers.DisplayVersion                          # 22H2
    $edition            = $cimWin32CAP                                        # Microsoft Windows 10 Pro
    $editionP           = $cimWin32CAP -replace 'Pro', 'Professional'         # Microsoft Windows 10 Professional
    $editionPA          = $editionP + " $arch"                                # Microsoft Windows 10 Professional x64
    $editionLite        = $edition.Substring(10)                              # Windows 10 Pro
    $editionLiteArch    = $editionLite + " $arch"                             # Windows 10 Pro x64
    $editionId          = ($regCurVers.EditionId).Replace('Server','')        # Professional
    $formattedBuildLite = "$editionLiteArch $displayV (OS Build $verShort)"   # Windows 10 Pro x64 22H2 (OS Build 19045.5608)
    $formattedBuildFull = "$editionLiteArch $displayV (OS Build $verFull)"    # Windows 10 Pro x64 22H2 (OS Build 10.0.19045.5608)

    $productType = switch($cimWin32PTY){
        1 { "Workstation" }; 2 { "Domain Controller" };
        3 { "Server" }; default { "Unknown" };
    }

    $typeName = 'Microsoft.Management.Infrastructure.CimInstance#root/cimv2/win32_operatingsystem'
    Update-TypeData -MemberName OSLanguage -TypeName $typeName -MemberType ScriptProperty -Value {
        [CultureInfo][int]($this.PSBase.CimInstanceProperties['OSLanguage'].Value)
    } -Force
    $winLanguage = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty OSLanguage
    $WindowsLanguageCode = $winLanguage.LCID
    $WindowsLanguageName = $winLanguage.Name
    $WindowsLanguageDisplayName = $winLanguage.DisplayName

    [PSCustomObject]@{
        ComputerName                   = $env:COMPUTERNAME
        UserName                       = $env:USERNAME
        UserSID                        = ([WindowsIdentity]::GetCurrent().User.Value)
        RegisteredUser                 = $cimWin32.RegisteredUser
        InstallDate                    = $cimWin32.InstallDate
        Win32OSSerialNumber            = $cimWin32.SerialNumber
        WindowsEdition                 = $editionPA
        WindowsEditionShort            = $editionLiteArch
        WindowsMajorVersion            = $verMajor
        WindowsEditionID               = $editionId
        OSArchitecture                 = $archRaw
        OSArchitectureAddressWidth     = GetOSArchitectureAddressWidth
        ProductType                    = $productType
        FullBuild                      = $verFull
        ShortBuild                     = $verShort
        DisplayVersion                 = $displayV
        CompleteWindowsVersion         = $formattedBuildLite
        CompleteWindowsVersionExtended = $formattedBuildFull
        OSLanguageCode                 = $WindowsLanguageCode
        OSLanguageName                 = $WindowsLanguageDisplayName
        OSLanguageShortName            = $WindowsLanguageName
    }
}