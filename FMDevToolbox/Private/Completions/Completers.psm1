using namespace System.Management.Automation
using namespace Microsoft.Toolkit.Uwp.Notifications

class CompletionsNVMNodeVersions : ArgumentCompleterAttribute {
    CompletionsNVMNodeVersions() : base({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            $options = Get-NVMNodeVersions
            return $options | Where-Object { $_ -like "$wordToComplete*" }
        }) { }
}

class CompletionsSpectreColors : ArgumentCompleterAttribute {
    CompletionsSpectreColors() : base({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $options = [Spectre.Console.Color] | Get-Member -Static -Type Properties | Select-Object -ExpandProperty Name
        return $options | Where-Object { $_ -like "$wordToComplete*" }
    }){}
}

class CompletionsModuleEnumeration : ArgumentCompleterAttribute {
    CompletionsModuleEnumeration() : base({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $options = Get-Module | Select-Object -ExpandProperty Name
        return $options | Where-Object { $_ -like "$wordToComplete*" }
    }){}
}

class ValidatePythonVersions : IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        [String[]] $v = ($script:InstalledPythonVersions).Version
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