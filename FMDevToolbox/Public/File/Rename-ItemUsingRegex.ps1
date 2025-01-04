function Rename-ItemUsingRegex {
    <#
    .SYNOPSIS
    Rename items using regular expressions.

    .DESCRIPTION
    Rename a series of items using regular expressions for matching and replacing item names.
    By default, matching takes place partially. To match a name fully, use the -MatchFullName switch.

    .PARAMETER Match
    The regular expression to search for.

    .PARAMETER Replace
    The replacement pattern, e.g., $1-$2.

    .PARAMETER Path
    The path to operate on. Defaults to the current directory.

    .PARAMETER PartialMatch
    Match partial item names. Default is to match the entire name.

    .PARAMETER PassThru
    Pass the renamed items down the pipeline.

    .PARAMETER NoCount
    Suppress count of renamed items at the end and don't warn if count equals 0.
    Note: Count is never shown when using -PassThru!

    .PARAMETER File
    Match files only.

    .PARAMETER Directory
    Match directories only.

    .PARAMETER Recurse
    Operate on subdirectories too.

    .PARAMETER Force
    Operate on hidden items too.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to rename text files with names containing 1 to 3 letters
    # (a, b, or c) by appending "-test" to their names.
    Rename-ItemUsingRegex '[abc]{1,3}\.txt' '$0-test'

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to use parts of the original name in the replacement,
    # adding '-test' before the extension.
    Rename-ItemUsingRegex '([abc]{1,3})\.(txt)' '$1-test.$2'

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to rename all directories starting with "old" to start with "new".
    Rename-ItemUsingRegex '^old(.+)$' 'new$1' -Directory

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to rename files recursively in subdirectories,
    # changing ".log" extensions to ".txt".
    Rename-ItemUsingRegex '\.log$' '.txt' -Recurse -File

    .EXAMPLE
    # **Example 5**
    # This example demonstrates how to rename hidden files that start with "temp"
    # by prefixing them with "archived_".
    Rename-ItemUsingRegex '^temp(.+)$' 'archived_$1' -Force -File

    .EXAMPLE
    # **Example 6**
    # This example demonstrates how to rename items without showing the count of renamed items,
    # even if no items are found.
    Rename-ItemUsingRegex 'backup' 'archive' -NoCount

    .OUTPUTS
    If -PassThru is specified, outputs the renamed items.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 01-01-2025
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    param (

        # The path to operate on
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String] $Path = $PWD,
        # The regular expression to search for
        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String] $Match,
        # The replacement regular expression, e.g. $1-$2
        [Parameter(Mandatory, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [String] $Replace,
        [Parameter(ParameterSetName = 'File')] [Switch] $File, # Match files only
        [Parameter(ParameterSetName = 'Directory')] [Switch] $Directory, # Match directories only

        [Switch] $MatchFullName, # Match full item names. Default is Partial.
        [Switch] $PassThru,      # Pass the renamed items down the pipeline
        [Switch] $NoCount,       # Supress count of renamed items at end and don't warn if count equals 0. Note: Count is never shown when using -PassThru!
        [Switch] $Recurse,       # Operate on subdirectories too
        [Switch] $Force,         # Operate on hidden items too
        [Switch] $LogToFile,     # Log all rename operations to a file.
        [String] $LogfilePath    = "$env:HOMEPATH\.fmotiondev\logs"
    )

    begin {
        # Pick up the value of the $Verbose switch
        $Verbose = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Verbose")
        Write-Debug "Verbose = $Verbose"

        if ($MatchFullName) { $Match = "^$Match`$" }
        $RecurseType = ($Recurse) ? ' and below' : ''

        Write-Verbose "Renaming items in `"$Path`"$RecurseType matching `"$Match`" with `"$Replace`""

        try { "" -match $Match | Out-Null }
        catch { Write-Error "Invalid match pattern ""$Match"": $_" -ErrorAction Stop }
        try { "" -replace $Match, $Replace | Out-Null }
        catch { Write-Error "Invalid replacement pattern ""$Replace"": $_" -ErrorAction Stop }
        [int] $count = 0

        if($LogToFile){
            $logFileName = "RegexRenameLog-$(Get-Date -Format 'yyyy-MM-dd hh-mmtt ss-fff').log"
            $logFinalPath = Join-Path $LogfilePath -ChildPath $logFileName
            New-Log -Message "Renaming items in $Path on $(Get-Date)" -Level INFO -IncludeCallerInfo -NoConsole -LogFilePath $logFinalPath
        }
    }

    process {
        if (-not(Test-Path -Path $Path)) {
            Write-Error "The specified path '$Path' does not exist."
            return
        }

        Get-ChildItem -Path $Path -Directory:$Directory -File:$File -Recurse:$Recurse -Force:$Force |
        where { $_.Name -match $Match } | % {
            $newName = $_.Name -replace $Match, $Replace
            try {
                Rename-Item -Verbose:$Verbose -Path $_.FullName -NewName $newName -PassThru:$PassThru
            }
            catch {
                New-Log -Message "Failed to rename file $($_.FullName) to $newName." -Level ERROR -NoConsole -LogFilePath $logFinalPath
                continue
            }
            New-Log -Message "Renamed file $($_.FullName) to $newName." -Level SUCCESS -NoConsole -LogFilePath $logFinalPath
            $count++
        }
    }
    end {
        if (-not$NoCount) {
            if ($count -eq 0) {
                Write-Error "No items found matching `"$Match`"!"
                New-Log -Message "No items were found for the specified RegEx pattern." -Level WARNING -NoConsole -LogFilePath $logFinalPath
            } elseif (-not$PassThru) {
                Write-Output "$count Item(s) renamed."
                New-Log -Message "$count Item(s) were renamed successfully." -Level SUCCESS -NoConsole -LogFilePath $logFinalPath
            }
        }
    }
}


