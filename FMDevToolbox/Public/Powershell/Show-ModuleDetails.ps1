using module "..\..\Private\Completions\Completers.psm1"

using namespace Spectre.Console
using namespace System.Collections.Generic
function Show-ModuleDetails {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [ValidateAvailableModules()]
        [String[]] $Name,
        [Switch] $ClearHost
    )

    begin {
        $ConsoleWidth = (Get-ConsoleWidth) - 1
        $ModuleMetadataPropsA = @('Guid', 'Author', 'CompanyName', 'Copyright', 'Description',
            'Prefix', 'RepositorySourceLocation', 'ProjectUri', 'IconUri', 'HelpInfoUri',
            'LicenseUri', 'ModuleType')
        $ModuleMetadataPropsB = @('Prefix', 'RepositorySourceLocation', 'ProjectUri',
            'IconUri', 'HelpInfoUri', 'LicenseUri', 'ModuleType')
        $ModulePathsProps = @('Path', 'RootModule', 'ModuleBase', 'ModuleList', 'FileList')
        $ModulePwshProps = @('PowerShellVersion', 'PowerShellHostName', 'PowerShellHostVersion',
            'ProcessorArchitecture', 'ClrVersion', 'ImplementingAssembly',
            'DotNetFrameworkVersion', 'PSStandardMembers', 'ExperimentalFeatures', 'OnRemove',
            'SessionState')
        $ModuleExportsProps = @('ExportedCommands', 'ExportedAliases', 'ExportedFunctions',
            'ExportedCmdlets', 'ExportedVariables', 'ExportedTypeFiles', 'ExportedFormatFiles',
            'ExportedDscResources', 'Scripts')

        $TableTheme = @{
            Color       = '#686c71'
            Border      = 'Rounded'
            HeaderColor = '#FFFFFF'
            TextColor   = '#aeb6bc'
            Width       = $ConsoleWidth
            AllowMarkup = $true
            Expand      = $true
        }
    }

    process {

        if($ClearHost){ Clear-Host }
        foreach ($Module in $Name) {

            try {
                Import-Module -Name $Module -Force -ErrorAction Stop
                $ModuleObject = Get-Module -Name $Module
            }
            catch {
                Write-Error "Error importing module $Module. Details: $_"
                continue
            }

            $CompatiblePSEditionsString  = (($ModuleObject.CompatiblePSEditions) -join ', ')
            $ModulePath = [System.IO.Path]::Combine($ModuleObject.ModuleBase, "$($ModuleObject.RootModule).psd1")
            $ModulePathResolved = if(Test-Path $ModulePath) { $ModulePath } else { $null }

            $ModuleMetadata        = [List[PSCustomObject]]@()
            $ModulePaths           = [List[PSCustomObject]]@()
            $ModulePowershell      = [List[PSCustomObject]]@()
            $ModuleExports         = [List[PSCustomObject]]@()
            $ModuleDependencies    = [List[PSCustomObject]]@()
            $ModuleReleaseNotes    = $ModuleObject.PrivateData.PSData['ReleaseNotes']

            $OBJMetaModuleName     = [PSCustomObject]@{ Property = "Module Name"; Value = $ModuleObject.Name }
            $OBJMetaModuleVersion  = [PSCustomObject]@{ Property = "Version"; Value = $ModuleObject.Version }
            $OBJMetaModulePre      = [PSCustomObject]@{ Property = "Prerelease"; Value = $ModuleObject.PrivateData.PSData['Prerelease'] }
            $OBJMetaModuleTags     = [PSCustomObject]@{ Property = "Tags"; Value = ($ModuleObject.PrivateData.PSData['Tags']) -join ', ' }
            $OBJMetaCompatiblePSE  = [PSCustomObject]@{ Property = 'CompatiblePSEditions'; Value = $CompatiblePSEditionsString }
            $OBJMetaArrayA         = ($ModuleMetadataPropsA | % { [PSCustomObject]@{ Property = $_; Value = $ModuleObject.$_ } }) -as [PSCustomObject[]]
            $OBJMetaArrayB         = ($ModuleMetadataPropsB | % { [PSCustomObject]@{ Property = $_; Value = $ModuleObject.$_ } }) -as [PSCustomObject[]]
            $OBJPathsManifestPath  = [PSCustomObject]@{ Property = "Manifest Path"; Value = $ModulePathResolved }
            $OBJPathsRootModule    = [PSCustomObject]@{ Property = "Root Module"; Value = $ModuleObject.RootModule }
            $OBJPathsArray         = ($ModulePathsProps | % { [PSCustomObject]@{ Property = $_; Value = $ModuleObject.$_ } }) -as [PSCustomObject[]]
            $OBJPowershellArray    = ($ModulePwshProps | % { [PSCustomObject]@{ Property = $_; Value = $ModuleObject.$_ } }) -as [PSCustomObject[]]
            $OBJExportsArray       = ($ModuleExportsProps | % { [PSCustomObject]@{ Property = $_; Value = $ModuleObject.$_ } }) -as [PSCustomObject[]]
            $OBJDependenciesArray  = (@('RequiredModules', 'RequiredAssemblies') | % { [PSCustomObject]@{ Property = $_; Value = $ModuleObject.$_ } }) -as [PSCustomObject[]]

            $null = $ModuleMetadata.Add($OBJMetaModuleName)
            $null = $ModuleMetadata.Add($OBJMetaModuleVersion)
            $null = $ModuleMetadata.Add($OBJMetaModulePre)
            $null = $ModuleMetadata.AddRange($OBJMetaArrayA)
            $null = $ModuleMetadata.Add($OBJMetaModuleTags)
            $null = $ModuleMetadata.Add($OBJMetaCompatiblePSE)
            $null = $ModuleMetadata.AddRange($OBJMetaArrayB)
            $null = $ModuleDependencies.AddRange($OBJDependenciesArray)
            $null = $ModulePaths.Add($OBJPathsRootModule)
            $null = $ModulePaths.Add($OBJPathsManifestPath)
            $null = $ModulePaths.AddRange($OBJPathsArray)
            $null = $ModulePowershell.AddRange($OBJPowershellArray)
            $null = $ModuleExports.AddRange($OBJExportsArray)

            $ModuleFullExports          = [System.Collections.Generic.List[Object]]@()
            $ModuleExportedFunctions    = [System.Collections.Generic.List[Object]]@()
            $ModuleExportedAliases      = [System.Collections.Generic.List[Object]]@()
            $ModuleExportedFilters      = [System.Collections.Generic.List[Object]]@()
            $ModuleExportedCmdlets      = [System.Collections.Generic.List[Object]]@()
            $ModuleExportedOther        = [System.Collections.Generic.List[Object]]@()
            $ModuleNestedModules        = [System.Collections.Generic.List[Object]]@()
            $ModuleExportedDscResources = [System.Collections.Generic.List[Object]]@()
            $ModuleExportedFormatFiles  = [System.Collections.Generic.List[Object]]@()
            $ModuleExportedTypeFiles    = [System.Collections.Generic.List[Object]]@()
            $ModuleExportedVariables    = [System.Collections.Generic.List[Object]]@()

            foreach ($Key in ($ModuleObject.ExportedCommands).Keys) {
                $ExportObject = ($ModuleObject.ExportedCommands)[$Key]
                if($ExportObject.CommandType -eq 'Function'){
                    $null = $ModuleExportedFunctions.Add($ExportObject)
                }
                elseif($ExportObject.CommandType -eq 'Cmdlet'){
                    $null = $ModuleExportedCmdlets.Add($ExportObject)
                }
                elseif($ExportObject.CommandType -eq 'Alias'){
                    $null = $ModuleExportedAliases.Add($ExportObject)
                }
                elseif($ExportObject.CommandType -eq 'Filter'){
                    $null = $ModuleExportedFilters.Add($ExportObject)
                }
                else{
                    $null = $ModuleExportedOther.Add($ExportObject)
                }
            }

            $ModuleFullExports.AddRange($ModuleExportedFunctions)
            $ModuleFullExports.AddRange($ModuleExportedCmdlets)
            $ModuleFullExports.AddRange($ModuleExportedAliases)
            $ModuleFullExports.AddRange($ModuleExportedFilters)
            $ModuleFullExports.AddRange($ModuleExportedOther)

            $NestedModulesList = [System.Collections.Generic.List[Object]]@()

            foreach ($NestedModule in $ModuleObject.NestedModules) {
                $Obj = [PSCustomObject]@{
                    ModuleType = $NestedModule.ModuleType
                    Name = $NestedModule.Name
                    Path = $NestedModule.Path
                    Version = $NestedModule.Version
                }
                $NestedModulesList.Add($Obj)
            }

            $ModuleFullExports | Format-SpectreTable @TableTheme -Title "All exports in $($ModuleObject.Name)"
            $NestedModulesList | Format-SpectreTable @TableTheme -Title "Nested Modules in $($ModuleObject.Name)"



            # foreach ($Key in ($ModuleObject.ExportedCmdlets).Keys) {
            #     $ExportObject = ($ModuleObject.ExportedCmdlets)[$Key]
            #     if($ExportObject){
            #         $null = $ModuleExports.Add($ExportObject)
            #     }
            # }
            # foreach ($Key in ($ModuleObject.ExportedDscResources).Keys) {
            #     $ExportObject = ($ModuleObject.ExportedDscResources)[$Key]
            #     if($ExportObject){
            #         $null = $ModuleExports.Add($ExportObject)
            #     }
            # }
            # foreach ($Key in ($ModuleObject.ExportedTypeFiles).Keys) {
            #     $ExportObject = ($ModuleObject.ExportedTypeFiles)[$Key]
            #     if($ExportObject){
            #         $null = $ModuleExportedTypeFiles.Add($ExportObject)
            #     }
            # }
            # foreach ($Key in ($ModuleObject.ExportedVariables).Keys) {
            #     $ExportObject = ($ModuleObject.ExportedVariables)[$Key]
            #     if($ExportObject){
            #         $null = $ModuleExports.Add($ExportObject)
            #     }
            # }
            # foreach ($Item in ($ModuleObject.ExportedFormatFiles)) {

            #     $FormatObj = [PSCustomObject]@{
            #         CommandType = "Format File"
            #         Name = $Item
            #         Version = ""
            #         Source = ""
            #     }
            #     $null = $ModuleExports.Add($FormatObj)
            # }

            #$ModuleExports | Format-Table
            #$ModuleExports | Format-SpectreTable @TableTheme
            # $ModuleExportedFunctions | Format-SpectreTable @TableTheme
            # $ModuleExportedAliases | Format-SpectreTable @TableTheme
            # $ModuleExportedCmdlets | Format-SpectreTable @TableTheme
            # $ModuleExportedDscResources | Format-SpectreTable @TableTheme
            # $ModuleExportedFormatFiles | Format-SpectreTable @TableTheme
            # $ModuleExportedTypeFiles | Format-SpectreTable @TableTheme
            # $ModuleExportedVariables | Format-SpectreTable @TableTheme

            # foreach ($Item in ($ModuleObject.ExportedCommands)) {
            #     $Item.GetType()
            #     $Item.GetType().BaseType
            # }


            # $OBJExportsArray = ($ModuleExportsProps | % { [PSCustomObject]@{ Property = $_; Value = $ModuleObject.$_ } }) -as [PSCustomObject[]]
            # $OBJExportsArray | Where-Object { $_.Property -eq 'ExportedCommands' } | ForEach-Object { $_.Value }


            # Write-SpectreHost -Message "[#95b8ff] $ModuleObject Main Metadata:[/]"
            # $ModuleMetadata | Format-SpectreTable @TableTheme

            # $ModuleDependencies | Format-Table
            # $ModulePaths | Format-Table
            # $ModulePowershell | Format-Table
            # $ModuleReleaseNotes | Format-Table
        }
    }
}