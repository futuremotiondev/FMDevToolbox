Function ConvertTo-FlatObjectCookie {
    <#
    .SYNOPSIS
        Flatten an object to simplify discovery of data

    .DESCRIPTION
        Flatten an object.  This function will take an object, and flatten the properties using their full path into a single object with one layer of properties.

        You can use this to flatten XML, JSON, and other arbitrary objects.

        This can simplify initial exploration and discovery of data returned by APIs, interfaces, and other technologies.

        NOTE:
            Use tools like Get-Member, Select-Object, and Show-Object to further explore objects.
            This function does not handle certain data types well.  It was original designed to expand XML and JSON.

    .PARAMETER InputObject
        Object to flatten

    .PARAMETER Exclude
        Exclude any nodes in this list.  Accepts wildcards.

        Example:
            -Exclude price, title

    .PARAMETER ExcludeDefault
        Exclude default properties for sub objects.  True by default.

        This simplifies views of many objects (e.g. XML) but may exclude data for others (e.g. if flattening a process, ProcessThread properties will be excluded)

    .PARAMETER Include
        Include only leaves in this list.  Accepts wildcards.

        Example:
            -Include Author, Title

    .PARAMETER Value
        Include only leaves with values like these arguments.  Accepts wildcards.

    .PARAMETER MaxDepth
        Stop recursion at this depth.

    .INPUTS
        Any object

    .OUTPUTS
        System.Management.Automation.PSCustomObject

    .EXAMPLE

        #Pull unanswered PowerShell questions from StackExchange, Flatten the data to date a feel for the schema
        Invoke-RestMethod "https://api.stackexchange.com/2.0/questions/unanswered?order=desc&sort=activity&tagged=powershell&pagesize=10&site=stackoverflow" |
            ConvertTo-FlatObjectCookie -Include Title, Link, View_Count

            $object.items[0].owner.link : http://stackoverflow.com/users/1946412/julealgon
            $object.items[0].view_count : 7
            $object.items[0].link       : http://stackoverflow.com/questions/26910789/is-it-possible-to-reuse-a-param-block-across-multiple-functions
            $object.items[0].title      : Is it possible to reuse a &#39;param&#39; block across multiple functions?
            $object.items[1].owner.link : http://stackoverflow.com/users/4248278/nitin-tyagi
            $object.items[1].view_count : 8
            $object.items[1].link       : http://stackoverflow.com/questions/26909879/use-powershell-to-retreive-activated-features-for-sharepoint-2010
            $object.items[1].title      : Use powershell to retreive Activated features for sharepoint 2010
            ...

    .EXAMPLE

        #Set up some XML to work with
        $object = [xml]'
            <catalog>
               <book id="bk101">
                  <author>Gambardella, Matthew</author>
                  <title>XML Developers Guide</title>
                  <genre>Computer</genre>
                  <price>44.95</price>
               </book>
               <book id="bk102">
                  <author>Ralls, Kim</author>
                  <title>Midnight Rain</title>
                  <genre>Fantasy</genre>
                  <price>5.95</price>
               </book>
            </catalog>'

        #Call the flatten command against this XML
            ConvertTo-FlatObjectCookie $object -Include Author, Title, Price

            #Result is a flattened object with the full path to the node, using $object as the root.
            #Only leaf properties we specified are included (author,title,price)

                $object.catalog.book[0].author : Gambardella, Matthew
                $object.catalog.book[0].title  : XML Developers Guide
                $object.catalog.book[0].price  : 44.95
                $object.catalog.book[1].author : Ralls, Kim
                $object.catalog.book[1].title  : Midnight Rain
                $object.catalog.book[1].price  : 5.95

        #Invoking the property names should return their data if the orginal object is in $object:
            $object.catalog.book[1].price
                5.95

            $object.catalog.book[0].title
                XML Developers Guide

    .EXAMPLE

        #Set up some XML to work with
            [xml]'<catalog>
               <book id="bk101">
                  <author>Gambardella, Matthew</author>
                  <title>XML Developers Guide</title>
                  <genre>Computer</genre>
                  <price>44.95</price>
               </book>
               <book id="bk102">
                  <author>Ralls, Kim</author>
                  <title>Midnight Rain</title>
                  <genre>Fantasy</genre>
                  <price>5.95</price>
               </book>
            </catalog>' |
                ConvertTo-FlatObjectCookie -exclude price, title, id

        Result is a flattened object with the full path to the node, using XML as the root.  Price and title are excluded.

            $Object.catalog                : catalog
            $Object.catalog.book           : {book, book}
            $object.catalog.book[0].author : Gambardella, Matthew
            $object.catalog.book[0].genre  : Computer
            $object.catalog.book[1].author : Ralls, Kim
            $object.catalog.book[1].genre  : Fantasy

    .EXAMPLE
        #Set up some XML to work with
            [xml]'<catalog>
               <book id="bk101">
                  <author>Gambardella, Matthew</author>
                  <title>XML Developers Guide</title>
                  <genre>Computer</genre>
                  <price>44.95</price>
               </book>
               <book id="bk102">
                  <author>Ralls, Kim</author>
                  <title>Midnight Rain</title>
                  <genre>Fantasy</genre>
                  <price>5.95</price>
               </book>
            </catalog>' |
                ConvertTo-FlatObjectCookie -Value XML*, Fantasy

        Result is a flattened object filtered by leaves that matched XML* or Fantasy

            $Object.catalog.book[0].title : XML Developers Guide
            $Object.catalog.book[1].genre : Fantasy

    .EXAMPLE
        #Get a single process with all props, flatten this object.  Don't exclude default properties
        Get-Process | select -first 1 -skip 10 -Property * | ConvertTo-FlatObjectCookie -ExcludeDefault $false

        #NOTE - There will likely be bugs for certain complex objects like this.
                For example, $Object.StartInfo.Verbs.SyncRoot.SyncRoot... will loop until we hit MaxDepth. (Note: SyncRoot is now addressed individually)

    .NOTES
        I have trouble with algorithms.  If you have a better way to handle this, please let me know!

    .FUNCTIONALITY
        General Command
    #>
    [cmdletbinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    param(
        [parameter(Mandatory,ValueFromPipeline)]
        [PSObject[]]$InputObject,
        [string[]]$Exclude = "",
        [bool]$ExcludeDefault = $True,
        [string[]]$Include = $null,
        [string[]]$Value = $null,
        [int]$MaxDepth = 10
    )
    begin {

        function IsIn-Include {
            param($prop)
            if(-not $Include) {$True}
            else {
                foreach($Inc in $Include) {
                    if($Prop -like $Inc) { $True }
                }
            }
        }

        function IsIn-Value {
            param($val)
            if(-not $Value) {$True}
            else {
                foreach($string in $Value) {
                    if($val -like $string) { $True }
                }
            }
        }

        Function Get-Exclude {
            [cmdletbinding()]
            param($obj)
            if($ExcludeDefault) {
                try {
                    $defaultTypeProps = @( $obj.gettype().GetProperties() | Select-Object -ExpandProperty Name -ErrorAction Stop )
                    if($defaultTypeProps.count -gt 0) {
                        Write-Verbose "Excluding default properties for $($obj.gettype().Fullname):`n$($defaultTypeProps | Out-String)"
                    }
                }
                catch {
                    Write-Verbose "Failed to extract properties from $($obj.gettype().Fullname): $_"
                    $defaultTypeProps = @()
                }
            }
            @( $Exclude + $defaultTypeProps ) | Select-Object -Unique
        }

        function Recurse-Object {
            [cmdletbinding()]
            param(
                $Object,
                [String[]] $Path = '$Object',
                [PSObject] $Output,
                [Int32] $Depth = 0
            )
            Write-Verbose "Working in path $Path at depth $Depth"
            Write-Debug "Recurse Object called with PSBoundParameters:`n$($PSBoundParameters | Out-String)"
            $Depth++
            $excludeProps = @( Get-Exclude $object )
            $children = $object.psobject.properties | Where-Object { $excludeProps -notcontains $_.Name }
            Write-Debug "Working on properties:`n$($children | Select-Object -ExpandProperty Name | Out-String)"
            foreach ($child in @($children)) {
                $childName = $child.Name
                $childValue = $child.Value
                Write-Debug "Working on property $childName with value $($childValue | Out-String)"
                if ($childName -match '[^a-zA-Z0-9_]') {
                    $friendlyChildName = "'$childName'"
                } else {
                    $friendlyChildName = $childName
                }
                if ((IsIn-Include $childName) -and (IsIn-Value $childValue) -and $Depth -le $MaxDepth) {
                    $thisPath = @( $Path + $friendlyChildName ) -join "."
                    $Output | Add-Member -MemberType NoteProperty -Name $thisPath -Value $childValue
                    Write-Verbose "Adding member '$thisPath'"
                }
                if ($null -eq $childValue) {
                    Write-Verbose "Skipping NULL $childName"
                    continue
                }
                $eval1 = ( $childValue.GetType() -eq $Object.GetType() -and $childValue -is [datetime] )
                $eval2 = ( $childName -eq "SyncRoot" -and -not $childValue )
                if ( $eval1 -or $eval2 ) {
                    Write-Verbose "Skipping $childName with type $($childValue.GetType().fullname)"
                    continue
                }
                $childTypeIsArray = ((($childValue.GetType()).basetype.Name) -eq 'Array')
                $isArray = $childTypeIsArray ? $true : (@($childValue).count -gt 1)
                $count = 0
                $currentPath = @( $Path + $friendlyChildName ) -join "."
                $excludeProps = @( Get-Exclude $childValue )
                $childrensChildren = $childValue.psobject.properties | Where-Object { $excludeProps -notcontains $_.Name }

                $hashKeys = ($childValue.Keys -notlike $null -and $childValue.Values) ? $childValue.Keys : $null
                Write-Debug "Found children's children $($childrensChildren | Select-Object -ExpandProperty Name | Out-String)"


                if ((@($childrensChildren).count -ne 0 -or $hashKeys) -and $Depth -lt $MaxDepth) {
                    if ($hashKeys) {
                        Write-Verbose "Working on hashtable $currentPath"
                        foreach ($key in $hashKeys) {
                            Write-Verbose "Adding value from hashtable $currentPath['$key']"
                            $Output | Add-Member -MemberType NoteProperty -Name "$currentPath['$key']" -Value $childValue["$key"]
                            $Output = Recurse-Object -Object $childValue["$key"] -Path "$currentPath['$key']" -Output $Output -Depth $Depth
                        }
                    } else {
                        if ($isArray) {
                            foreach ($item in @($childValue)) {
                                Write-Verbose "Recursing through array node '$currentPath'"
                                $Output = Recurse-Object -Object $item -Path "$currentPath[$count]" -Output $Output -Depth $Depth
                                $Count++
                            }
                        } else {
                            Write-Verbose "Recursing through node '$currentPath'"
                            $Output = Recurse-Object -Object $childValue -Path $currentPath -Output $Output -Depth $Depth
                        }
                    }
                }
            }
            $Output
        }
    }

    process {
        foreach($object in $InputObject) {
            Recurse-Object -Object $object -Output $( New-Object -TypeName PSObject )
        }
    }
}
