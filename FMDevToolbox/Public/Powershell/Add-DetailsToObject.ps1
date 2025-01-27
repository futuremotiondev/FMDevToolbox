using namespace System.Management.Automation
function Add-DetailsToObject {
    <#
    .SYNOPSIS
    Adds details and properties such as a TypeName, new properties, and default parameters to PowerShell objects.

    .DESCRIPTION
    The Add-DetailsToObject function allows you to enhance PowerShell objects by adding custom
    type names, note properties, and default display properties. It supports pipeline input and
    can be used to modify multiple objects at once.

    .PARAMETER InputObject
    The object(s) to decorate. Accepts pipeline input.

    .PARAMETER TypeName
    The typename to add. This will show up when you use Get-Member against the resulting object.

    .PARAMETER PropertyToAdd
    A hashtable of additional note properties to add to the object. Format is 'Key = Value'.
    Example: `-PropertyToAdd @{ FileName = "explorer.exe"; IsSystemFile = $true; }`

    .PARAMETER DefaultProperties
    A list of properties that show up by default when outputing the object. Other properties are not shown by default.

    .PARAMETER Passthru
    Indicates whether to pass the result object back. Defaults to $true.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to add a type name to an object.
    `$obj = [PSCustomObject]@{ Name = 'John Doe'; Age = 30 }
    Add-DetailsToObject -InputObject $obj -TypeName 'Person'`

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to add note properties to an object.
    `$obj = [PSCustomObject]@{ Name = 'Jane Doe'; Age = 25 }
    Add-DetailsToObject -InputObject $obj -PropertyToAdd @{ Location = 'New York'; Occupation = 'Engineer' }`

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to change the default display properties of an object.
    `$obj = [PSCustomObject]@{ Name = 'Alice'; Age = 28; City = 'Seattle' }
    Add-DetailsToObject -InputObject $obj -DefaultProperties 'Name', 'City'`

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to use the function with pipeline input.
    `[PSCustomObject]@{ Name = 'Bob'; Age = 40 } | Add-DetailsToObject -TypeName 'Employee' -PropertyToAdd @{ Department = 'HR' }`

    .EXAMPLE
    # **Example 5**
    # This example demonstrates how to use all parameters together.
    `$obj = [PSCustomObject]@{ Name = 'Charlie'; Age = 35 }
    Add-DetailsToObject -InputObject $obj -TypeName 'Manager' -PropertyToAdd @{ TeamSize = 10 } -DefaultProperties 'Name', 'TeamSize'`

    .OUTPUTS
    Returns the modified object(s) with added details.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: [Current Date]
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    param (
        [Parameter(
            Mandatory = $true,
            Position=0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage="The Object(s) to decorate. Accepts pipeline input."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('input','i')]
        [PSCustomObject[]] $InputObject,

        [Parameter(Position=1,HelpMessage="Typename to add. This will show up when you use Get-Member against the resulting object.")]
        [Alias('type','t')]
        [string] $TypeName,

        [Parameter(Position=2,HelpMessage="Adds additional note properties. Format is a hashtable with the format 'Key = Value'. Example: -PropertyToAdd @{ ComputerName = 'FUTUREMOTION-PC'; Date = (Get-Date); } ")]
        [Alias('toadd','add')]
        [System.Collections.Hashtable] $PropertyToAdd,

        [Parameter(Position=3,HelpMessage="Change the default properties that show up. Only the properties that you specify here will appear when outputting the object either directly or with `Write-Output`, etc.")]
        [ValidateNotNullOrEmpty()]
        [Alias('dp')]
        [System.String[]] $DefaultProperties,

        [Parameter(HelpMessage='Whether to pass the result object back. Defaults to $true.')]
        [Alias('pt','p')]
        [Boolean] $Passthru = $true
    )
    begin {
        if($PSBoundParameters['DefaultProperties']) {
            $PSStandardMembers = [PSMemberInfo[]][PSPropertySet]::new('DefaultDisplayPropertySet', $DefaultProperties)
        }
    }
    process {
        foreach( $Object in $InputObject ) {
            switch ($PSBoundParameters.Keys) {
                'PropertyToAdd' {
                    foreach($Key in $PropertyToAdd.Keys) {
                        $Object.PSObject.Properties.Add([PSNoteProperty]::new($Key, $PropertyToAdd[$Key]))
                    }
                }
                'TypeName' {
                    [void] $Object.PSObject.TypeNames.Insert(0, $TypeName)
                }
                'DefaultProperties' {
                    Add-Member -InputObject $Object -MemberType MemberSet -Name PSStandardMembers -Value $PSStandardMembers
                }
            }
            if($Passthru) {
                $Object
            }
        }
    }
}