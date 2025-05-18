function Get-SvgDimensions {
    [CmdletBinding(DefaultParameterSetName="File")]
    param(
        [Parameter(Mandatory,Position=0,ParameterSetName='File',ValueFromPipeline)]
        [string[]] $SVGFiles,

        [Parameter(Mandatory,Position=0,ParameterSetName='Data',ValueFromPipeline)]
        [string[]] $SVGData
    )

    process {

        switch ($PSCmdlet.ParameterSetName) {
            'File'  {
                foreach ($SVGFile in $SVGFiles) {

                    $SVGFilename = Split-Path -Path $SVGFile -Leaf

                    $SVGWidth    = 0
                    $SVGHeight   = 0
                    $SVGVBWidth  = 0
                    $SVGVBHeight = 0

                    [xml]$SVG = Get-Content -Path $SVGFile
                    $SVGRoot = $SVG.DocumentElement

                    # Attempt to extract from viewBox
                    if ($SVGRoot.hasAttribute("viewBox")) {
                        $viewBoxValues = $SVGRoot.viewBox.Split(' ')
                        $SVGVBWidth  = $viewBoxValues[2] -as [double]
                        $SVGVBHeight = $viewBoxValues[3] -as [double]
                    }
                    if ($SVGRoot.hasAttribute("width")) {
                        $reWidthInput = $SVGRoot.width
                        $reWidth = [regex]'([\d\.]+)(px)$'
                        if($reWidth.IsMatch($reWidthInput)){
                            $WidthMatch = $reWidth.Match($reWidthInput)
                            $SVGWidth = $WidthMatch.Groups[1].Value -as [double]
                        } else {
                            $SVGWidth = $SVGRoot.width -as [double]
                        }
                    }
                    if ($SVGRoot.hasAttribute("height")) {
                        $reHeightInput = $SVGRoot.height
                        $reHeight = [regex]'([\d\.]+)(px)$'
                        if($reHeight.IsMatch($reHeightInput)){
                            $HeightMatch = $reHeight.Match($reHeightInput)
                            $SVGHeight = $HeightMatch.Groups[1].Value -as [double]
                        } else {
                            $SVGHeight = $SVGRoot.height -as [double]
                        }
                    }

                    [PSCustomObject]@{
                        File          = $SVGFilename
                        Width         = $SVGWidth
                        Height        = $SVGHeight
                        ViewboxWidth  = $SVGVBWidth
                        ViewboxHeight = $SVGVBHeight
                    }
                }
            }
            'Data' {
                foreach ($SVGDefinition in $SVGData) {

                    $SVGWidth    = 0
                    $SVGHeight   = 0
                    $SVGVBWidth  = 0
                    $SVGVBHeight = 0

                    [xml]$SVG = $SVGDefinition
                    $SVGRoot = $SVG.DocumentElement

                    # Attempt to extract from viewBox
                    if ($SVGRoot.hasAttribute("viewBox")) {
                        $viewBoxValues = $SVGRoot.viewBox.Split(' ')
                        $SVGVBWidth  = $viewBoxValues[2] -as [double]
                        $SVGVBHeight = $viewBoxValues[3] -as [double]
                    }
                    if ($SVGRoot.hasAttribute("width")) {
                        $reWidthInput = $SVGRoot.width
                        $reWidth = [regex]'([\d\.]+)(px)$'
                        if($reWidth.IsMatch($reWidthInput)){
                            $WidthMatch = $reWidth.Match($reWidthInput)
                            $SVGWidth = $WidthMatch.Groups[1].Value -as [double]
                        } else {
                            $SVGWidth = $SVGRoot.width -as [double]
                        }
                    }
                    if ($SVGRoot.hasAttribute("height")) {
                        $reHeightInput = $SVGRoot.height
                        $reHeight = [regex]'([\d\.]+)(px)$'
                        if($reHeight.IsMatch($reHeightInput)){
                            $HeightMatch = $reHeight.Match($reHeightInput)
                            $SVGHeight = $HeightMatch.Groups[1].Value -as [double]
                        } else {
                            $SVGHeight = $SVGRoot.height -as [double]
                        }
                    }

                    [PSCustomObject]@{
                        SVGData       = $SVGDefinition
                        Width         = $SVGWidth
                        Height        = $SVGHeight
                        ViewboxWidth  = $SVGVBWidth
                        ViewboxHeight = $SVGVBHeight
                    }
                }
            }
        }

    }
}

