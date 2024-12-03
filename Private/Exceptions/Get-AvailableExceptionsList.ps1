function Get-AvailableExceptionsList {
    [CmdletBinding()]
    param()
    end {
        $irregulars = 'Dispose|OperationAborted|Unhandled|ThreadAbort|ThreadStart|TypeInitialization'
        [AppDomain]::CurrentDomain.GetAssemblies() | ForEach-Object {
            $_.GetExportedTypes() -match 'Exception' -notmatch $irregulars |
            Where-Object {
                $_.GetConstructors() -and $(
                $_exception = New-Object $_.FullName
                New-Object Management.Automation.ErrorRecord $_exception, ErrorID, OpenError, Target
                )
            } | Select-Object -ExpandProperty FullName
        } 2> $null
    }
}