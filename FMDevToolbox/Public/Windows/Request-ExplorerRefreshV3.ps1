function Request-ExplorerRefreshV3 {
    param (
        [switch] $SendF5,
        [Int32] $SendF5Delay=150
    )

    $shellApplication = New-Object -ComObject Shell.Application
    $windows = $shellApplication.Windows()
    $count = $windows.Count()

    foreach( $i in 0..($count-1) ) {
        $item = $windows.Item( $i )
        if( $item.Name() -like '*Explorer*' ) {
            $item.Refresh()
        }
    }

    $ie4cmd = Get-Command ie4uinit.exe -CommandType Application
    $params = '-show'
    & $ie4cmd $params

    if($SendF5){
        $wshell = New-Object -ComObject wscript.shell;
        Start-Sleep -Milliseconds $SendF5Delay
        $wshell.SendKeys("{F5}")
        Start-Sleep -Milliseconds $SendF5Delay
        $wshell.SendKeys("{F5}")
    }
}