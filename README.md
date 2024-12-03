<img src="./Assets/Images/ModuleIcon.png" alt="Description" width="140">

# Futuremotion Development Toolbox
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/FMDevToolbox)](https://www.powershellgallery.com/packages/FMDevToolbox/1.0.1)
[![License](https://img.shields.io/badge/license-MIT-green)](./LICENSE)

## Description

Provides a wide range of functions for automating development workflows and CLI tools, managing applications and computer settings, formatting and transforming data, and verifying data formats.


## Installation from the Powershell Gallery

```powershell
Install-Module FMDevToolbox
Import-Module FMDevToolbox
```


## Requirements

Powershell 7.1+


## Changelog

- **1.0.1** - 11-14-2024 - Initial Release. Some functions are incomplete and code quality is not consistent across all functions. Futher updates will come with major improvements.


## Documentation

Full Markdown Documentation Coming Soon.

## Function List

#### ANSI

```
Convert-ColorHexToANSICode
Get-ANSIColorEscapeFromHex
```

#### Color Conversion

```
Convert-ColorHexToRGB
Convert-ColorHSLToRGB
Convert-ColorRGBToHex
Convert-ColorRGBToHSV
```

#### Commands

```
Get-CommandJSXER
Get-CommandNPM
Get-CommandNVM
Get-CommandPrettierNext
```

#### Console

```
Convert-iTermColorsToINI
Show-CountdownTimer
Show-HorizontalLineInConsole
```

#### Duplicate

```
Get-UniqueNameIfDuplicate
```

#### Environment

```
Get-WindowsEnvironmentVariable
Get-WindowsEnvironmentVariables
```

#### File

```
Add-NumericSuffixToFile
Add-StringSuffixToFile
Convert-SymbolicLinksToFiles
ConvertTo-FlatDirectory
Expand-ArchivesInDirectory
Get-FirstUniqueFileByDepth
Get-FullPathWithoutExtension
New-TempDirectory
Out-FileHash
Remove-EmptyDirectories
Rename-ImageDensityMultiplerToActual
Rename-RandomizeFilenames
Resolve-PathType
Resolve-RelativePath
Resolve-SymbolicLinks
Save-Base64StringToFile
Save-FilesToFolderByWord
Save-FolderToSubfolderByWord
Save-RandomDataToFile
Save-RandomDataToFiles
Show-FilesBasedOnAgeInDirectory
Split-DirectoryContentsToSubfolders
Test-DirectoryContainsPwshFiles
Test-DirectoryIsEmpty
Test-ValidLiteralPath
Test-ValidWildcardPath
```

#### Format

```
Format-Bytes
Format-FileSize
Format-FileSizeAuto
Format-Milliseconds
Format-NaturalSort
Format-ObjectSortNumerical
```

#### GUI

```
Invoke-GUIMessageBox
Invoke-OokiiInputDialog
Invoke-OokiiPasswordDialog
Invoke-OokiiTaskDialog
Invoke-OpenFileDialog
Invoke-OpenFolderDialog
Invoke-SaveFileDialog
Invoke-VBMessageBox
Show-UWPToastNotification
```

#### JavaScript

```
ConvertFrom-JSXBINToJSX
```

#### List

```
Convert-CommaSeparatedListToPlaintextTable
Convert-JsonKeysToCommaSeparatedString
Convert-JsonKeysToLines
Convert-PlaintextListToPowershellArray
Find-SeparatorInList
```

#### Logging

```
New-LogANSI
New-LogSpectre
```

#### Math

```
Convert-ToPercentage
```

#### Node

```
Confirm-NPMPackageExistsInRegistry
Get-NodeInstalledVersion
Get-NodeLatestNPMVersion
Get-NodeActiveVersionInNVM
Get-NodeNVMInstallationDirectory
Get-NodeInstalledVersionsNVM
Get-NVMInstalledNPMVersions
Get-NVMLatestNodeVersionInstalled
Get-NVMNodeInstallationDirectory
Get-NVMNodeInstallationExe
Get-NVMNodeNPMVersions
Get-NVMNodeVersions
Get-NVMVersion
Get-NVMVersionDetails
Install-NVMNodeGlobalPackages
Show-NVMNodeGlobalPackages
Uninstall-NVMNodeGlobalPackages
Update-NVMGlobalNodePackagesByVersion
```

#### Other

```
Convert-AudioToStemsWithDEMUCS
Search-GoogleIt
Stop-AdobeBackgroundProcesses
```

#### Process

```
Invoke-AndWaitForProcessOpen
```

#### Python

```
Confirm-PythonFolderIsVENV
Confirm-PythonPyPiPackageExists
Get-MinicondaInstallDetails
Get-PythonInstallations
Get-PythonVENVDetails
Install-PythonGlobalPackages
Update-PythonPackagesInVENV
Update-PythonPIPGlobally
Update-PythonPIPInVENV
Use-PythonActivateVENVInFolder
Use-PythonFreezeVENVToRequirements
Use-PythonInstallRequirementsToVENV
```

#### Registry

```
ConvertTo-RegSZEscaped
ConvertTo-RegSZUnescaped
ConvertTo-UnescapedRegistryStrings
```

#### Scraping

```
Invoke-GalleryDLSaveGallery
```

#### String

```
Format-String
Format-StringRemoveUnusualSymbols
Format-StringReplaceDiacritics
Join-StringByNewlinesWithDelimiter
Remove-ANSICodesFromString
Split-StringByDelimiter
Split-StringByDelimiterAndCombineLines
```

#### System

```
Get-AllDriveInfo
Get-NumberOfProcessorCoresAndThreads
Invoke-Ngen
Show-SystemOSClockResolution
```

#### Templating

```
Save-PowershellGalleryNupkg
```

#### Utility

```
ConvertFrom-HashtableToPSObject
Get-Enum
Get-ModulePrivateFunctions
Get-RandomAlphanumericString
```

#### ValidateScriptHelpers

```
Confirm-PathIsAFile
Confirm-PathIsIllegal
Confirm-PathIsSingleFile
```

#### Validation

```
Test-DirectoryIsProtected
Test-FileIsLocked
Test-IsValidGUID
Test-PathContainsWildcards
Test-PathIsLikelyDirectory
Test-PathIsLikelyFile
Test-PathIsValid
Test-URLIsValid
```

#### Windows

```
Confirm-WindowsPathIsProtected
Convert-WindowsGUIDToPID
Copy-WindowsDirectoryStructure
Copy-WindowsPathsToClipboard
Get-WindowsDefaultBrowser
Get-WindowsOpenDirectories
Get-WindowsOSArchitecture
Get-WindowsProcessOverview
Get-WindowsProductKey
Get-WindowsVersionDetails
Get-WindowsWSLDistributionInfo
Open-WindowsExplorerTo
Register-WindowsDLLorOCX
Remove-WindowsInvalidFilenameCharacters
Rename-SanitizeFilenames
Rename-SanitizeFilenamesInFolder
Request-ExplorerRefresh
Request-WindowsAdminRights
Request-WindowsExplorerRefresh
Request-WindowsExplorerRefreshAlt
Resolve-WindowsSIDToIdentifier
Save-FoldersInCurrentDirectory
Save-WindowsOpenDirectories
Set-WindowsFolderIcon
Stop-AdobeProcesses
Stop-PwshProcesses
Test-WindowsIsAdmin
Update-WindowsEnvironmentVariables
```

#### WSL

```
Stop-WSL
```