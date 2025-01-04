using namespace System.Management.Automation
using namespace Microsoft.Toolkit.Uwp.Notifications
using namespace Spectre.Console

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
param()

class ValidateAvailableModules : ValidateArgumentsAttribute {
    [void] Validate([Object] $arguments, [EngineIntrinsics] $engineIntrinsics) {
        $availableModules = (Get-Module -ListAvailable).Name
        if (-not $availableModules -contains $arguments) {
            throw [ArgumentException]::new("The module '$arguments' is not available on this system.")
        }
    }
}

class CompletionsNodeVersions : ArgumentCompleterAttribute {
    CompletionsNodeVersions() : base({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            $nvmCmd = Get-Command nvm.exe -CommandType Application -ErrorAction SilentlyContinue
            if($nvmCmd){
                $versionList = & $nvmCmd 'list'
                [string[]] $nodeVersions = $versionList -split "\r?\n" | % {
                    if([String]::IsNullOrEmpty($_)){ return }
                    (($_ -replace '\* ', '') -replace '\(([\w\s\-]+)\)', '').Trim()
                }
                return $nodeVersions | Where-Object { $_ -like "$wordToComplete*" }
            }
            else{
                $nodeCmd = Get-Command node.exe -CommandType Application -ErrorAction SilentlyContinue
                if($nodeCmd){
                    [string] $nodeVersion = (& $nodeCmd '--version').TrimStart('v')
                    return $nodeVersion | Where-Object { $_ -like "$wordToComplete*" }
                }
                else{
                    return $null
                }
            }
        }) { }
}

class CompletionsSpectreColors : ArgumentCompleterAttribute {
    CompletionsSpectreColors() : base({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $options = [Spectre.Console.Color] | Get-Member -Static -Type Properties | Select-Object -ExpandProperty Name
        return $options | Where-Object { $_ -like "$wordToComplete*" }
    }){}
}

class AvailableCmdletsFunctionsScriptsCompleter : ArgumentCompleterAttribute {
    AvailableCmdletsFunctionsScriptsCompleter() : base({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $options = Get-Command -All -CommandType Cmdlet, Function, Script | Select-Object -ExpandProperty Name
        return $options | Where-Object { $_ -like "$wordToComplete*" }
    }){}
}

class AvailableEnumsCompleter : ArgumentCompleterAttribute {
    AvailableEnumsCompleter() : base({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $options = [System.Collections.Generic.List[String]]@()
        $assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
        foreach ($assembly in $assemblies) {
            $assembly.GetTypes() | Where-Object { $_.IsEnum -and $_.IsPublic } | % {
                $options.Add($_.FullName)
            }
        }
        return $options | Where-Object { $_ -like "$wordToComplete*" }
    }){}
}

class AvailableModulesCompleter : ArgumentCompleterAttribute {
    AvailableModulesCompleter() : base({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $options = Get-Module -ListAvailable | Select-Object -ExpandProperty Name
        return $options | Where-Object { $_ -like "$wordToComplete*" }
    }){}
}

class LoadedModulesCompleter : ArgumentCompleterAttribute {
    LoadedModulesCompleter() : base({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $options = Get-Module | Select-Object -ExpandProperty Name
        return $options | Where-Object { $_ -like "$wordToComplete*" }
    }){}
}

class ValidateConsoleColors : IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        [String[]] $lookup = [System.Enum]::getvalues([System.ConsoleColor]) -as [String]
        return $lookup
    }
}

class ValidateSetAvailableModules : IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        [String[]] $lookup = Get-Module -ListAvailable | Select-Object -ExpandProperty Name
        return $lookup
    }
}

[System.IO.FileAttributes].GetEnumNames() | % {
    [PSCustomObject]@{
        Name = $_
        Value = [System.IO.FileAttributes].GetEnumValues()
    }
}

class SpectreConsoleTableBorder : IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        $lookup = [Spectre.Console.TableBorder] | Get-Member -Static -MemberType Properties | Select-Object -ExpandProperty Name
        return $lookup
    }
}

class ValidatePythonVersions : IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        [String[]] $v = $script:InstalledPythonVersionsAsStringArray
        return $v
    }
}

class ValidateUWPAdaptiveImageCrop : IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        $lookup = [AdaptiveImageCrop] | Get-Member -Static -MemberType Properties | Select-Object -ExpandProperty Name
        return $lookup
    }
}

class ValidateSpectreTableBorders : IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        $lookup = [Spectre.Console.TableBorder] | Get-Member -Static -MemberType Properties | Select-Object -ExpandProperty Name
        return $lookup
    }
}

class ValidateSpectreSpinnerTypes : IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        $lookup = [Spectre.Console.Spinner+Known] | Get-Member -Static -MemberType Properties | Select-Object -ExpandProperty Name
        return $lookup
    }
}