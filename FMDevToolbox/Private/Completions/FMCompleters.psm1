using namespace System.Management.Automation
using namespace Microsoft.Toolkit.Uwp.Notifications
using namespace Spectre.Console

# $Assemblies = @( Get-ChildItem -Path "$script:LibRoot\*.dll" -Recurse -ErrorAction Continue )
# foreach ($assembly in @($Assemblies)) {
#     $aName = $assembly.Name
#     $aFullName = $assembly.FullName


#     try {
#         Write-Verbose -Message "Importing assembly $aFullName now."
#         Add-Type -LiteralPath $aFullName -Verbose:$false
#     }
#     catch {
#         $eMsg = $_.Exception.Message
#         $lExceptions = $_.Exception.LoaderExceptions | Sort-Object -Unique
#         Write-Error "Error processing assembly $aName. Exception: $eMsg"
#         foreach ($err in $lExceptions) {
#             Write-Error "Processing $aName LoaderExceptions: $($err.Message)"
#         }
#     }
# }

class CompletionsPowershellGenericTypes : ArgumentCompleterAttribute {
    CompletionsPowershellGenericTypes() : base({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $options = [Spectre.Console.Color] | Get-Member -Static -Type Properties | Select-Object -ExpandProperty Name
        return $options | Where-Object { $_ -like "$wordToComplete*" }
    }){}
}
class ValidateAvailableModules : ValidateArgumentsAttribute {
    [void] Validate([Object] $arguments, [EngineIntrinsics] $engineIntrinsics) {
        $availableModules = (Get-Module -ListAvailable).Name
        if (-not $availableModules -contains $arguments) {
            throw [ArgumentException]::new("The module '$arguments' is not available on this system.")
        }
    }
}

#  Validate Node Versions  ////////////////////////////////////////////////////////////////////////#
#//////////////////////////////////////////////////////////////////////////////////////////////////#

class ValidateNodeVersions : IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        $nvmCmd = Get-Command nvm.exe -EA 0
        if($nvmCmd){
            [version[]] $v = @()
            $v = (& $nvmCmd 'list') -split "\r?\n" | % {
                if([String]::IsNullOrEmpty($_)){ return }
                (($_ -replace '\* ', '') -replace '\(([\w\s\-]+)\)', '').Trim()
            } | Sort-Object -Descending
            return [string[]] $v
        }
        else{
            $nodeCmd = Get-Command node.exe -EA 0
            if($nodeCmd){
                $v = (& $nodeCmd '--version').TrimStart('v').Trim()
                return [string[]] $v
            }
            else { return [string[]] @($null) }
        }
    }
}
class ValidateNodeVersionsPlusAll : IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        $nvmCmd = Get-Command nvm.exe -EA 0
        if($nvmCmd){
            [version[]] $v = @()
            $v = (& $nvmCmd 'list') -split "\r?\n" | % {
                if([String]::IsNullOrEmpty($_)){ return }
                (($_ -replace '\* ', '') -replace '\(([\w\s\-]+)\)', '').Trim()
            } | Sort-Object -Descending
            [string[]] $vs = $v
            $vs += 'All'; return [string[]] $vs
        }
        else{
            $nodeCmd = Get-Command node.exe -EA 0
            if($nodeCmd){
                [string[]] $v = (& $nodeCmd '--version').TrimStart('v')
                $v += 'All'; return [string[]] $v;
            }
            else { return [string[]] @($null) }
        }
    }
}
class CompletionsNodeVersions : ArgumentCompleterAttribute {
    CompletionsNodeVersions() : base({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $nvmCmd = Get-Command nvm.exe -EA 0
        if($nvmCmd){
            [version[]] $v = (& $nvmCmd 'list') -split "\r?\n" | % {
                if([String]::IsNullOrEmpty($_)){ return }
                (($_ -replace '\* ', '') -replace '\(([\w\s\-]+)\)', '').Trim()
            }
            [string[]] $vs = $v | Sort-Object -Descending | % { $_.ToString() }
            return $vs | where { $_ -like "$wordToComplete*" }
        }
        else{
            $nodeCmd = Get-Command node.exe -EA 0
            if($nodeCmd){
                [string[]] $vs = @()
                $vs += (& $nodeCmd '--version').TrimStart('v')
                return $vs | where { $_ -like "$wordToComplete*" }
            }
            else {
                return $null
            }
        }
    }){}
}
class CompletionsNodeVersionsPlusAll : ArgumentCompleterAttribute {
    CompletionsNodeVersionsPlusAll() : base({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $nvmCmd = Get-Command nvm.exe -EA 0
        if($nvmCmd){
            [version[]] $v = (& $nvmCmd 'list') -split "\r?\n" | % {
                if([String]::IsNullOrEmpty($_)){ return }
                (($_ -replace '\* ', '') -replace '\(([\w\s\-]+)\)', '').Trim()
            }
            [string[]] $vs = $v | Sort-Object -Descending | % { $_.ToString() }
            $vs += 'All';
            return $vs | where { $_ -like "$wordToComplete*" }
        }
        else{
            $nodeCmd = Get-Command node.exe -EA 0
            if($nodeCmd){
                [string[]] $vs = @()
                $vs += (& $nodeCmd '--version').TrimStart('v')
                return $vs | where { $_ -like "$wordToComplete*" }
            }
            else { return [string[]] @($null) }
        }
    }){}
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

class ValidateSpectreSpinners : IValidateSetValuesGenerator {
    [String[]] GetValidValues(){
        [string[]] $lookup = @(
            "Aesthetic", "Arc", "Arrow", "Arrow2", "Arrow3", "Ascii", "Balloon",
            "Balloon2", "BetaWave", "Bounce", "BouncingBall", "BouncingBar", "BoxBounce",
            "BoxBounce2", "Christmas", "Circle", "CircleHalves", "CircleQuarters",
            "Clock", "Default", "Dots", "Dots10", "Dots11", "Dots12", "Dots2", "Dots3",
            "Dots4", "Dots5", "Dots6", "Dots7", "Dots8", "Dots8Bit", "Dots9", "Dqpb",
            "Earth", "Flip", "Grenade", "GrowHorizontal", "GrowVertical", "Hamburger",
            "Hearts", "Layer", "Line", "Line2", "Material", "Monkey", "Moon", "Noise",
            "Pipe", "Point", "Pong", "Runner", "Shark", "SimpleDots", "SimpleDotsScrolling",
            "Smiley", "SquareCorners", "Squish", "Star", "Star2", "Toggle", "Toggle10",
            "Toggle11", "Toggle12", "Toggle13", "Toggle2", "Toggle3", "Toggle4", "Toggle5",
            "Toggle6", "Toggle7", "Toggle8", "Toggle9", "Triangle", "Weather"
        )
        return $lookup
    }
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


