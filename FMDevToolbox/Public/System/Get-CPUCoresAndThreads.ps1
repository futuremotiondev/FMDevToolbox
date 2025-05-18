function Get-CPUCoresAndThreads {
    [CmdletBinding()]
    param()
    $logicalProcessors = [System.Environment]::ProcessorCount
    $physicalCores = foreach ($line in $(iex 'wmic cpu get NumberOfCores')) {
        if(($line.Trim()) -match '^[\d]{1,3}$'){
            $line
        }
    }
    [PSCustomObject]@{
        PhysicalCores = $physicalCores
        LogicalProcessors = $logicalProcessors
    }
}