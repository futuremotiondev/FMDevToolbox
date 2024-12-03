function Invoke-AndWaitForProcessOpen {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $ProcessName,
        [Parameter(Mandatory)]
        [String] $Executable,
        [Parameter(Mandatory)]
        [String] $Label,
        [int] $Timeout = 4000
    )

    if($Executable -notmatch "(\.exe$|\.cmd$|\.com$|\.bat$|\.msi$)"){
        throw "File must be an executable. (.exe, .cmd, .com, .bat, .msi)"
    }
    if(-not(Test-Path $Executable -PathType Leaf)){
        throw "Passed executable does not exist on disk. ($Executable)"
    }

    $GetNumInstances = {
        (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue).Count
    }

    $StartDate = Get-Date
    $Command = Get-Command $Executable -CommandType Application
    $NumInstances = & $GetNumInstances

    if($NumInstances -gt 0){
        Write-Verbose "$Label is already open."
        return
    }
    else {
        try {
            & $Command
        }
        catch {
            throw "Error starting specified command ($Command). Details: $_"
        }

        $TimeoutDate = $StartDate.AddMilliseconds($Timeout)
        $TimeoutOccured = $false
        do {
            Start-Sleep -Milliseconds 300
            if($TimeoutDate -gt (Get-Date)){
                $TimeoutOccured = $true
                break
            }
        } while ((& $GetNumInstances) -gt 0)

        if($TimeoutOccured){
            Write-Verbose "$Label didn't start within the specified -TimeoutInSeconds ($Timeout)"
        }
        else {
            Write-Verbose "$Label is now available."
        }
    }
}