Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationFramework
Add-Type -Language CSharp -TypeDefinition $(Get-Content -Path "$PSScriptRoot\Display.cs" -Raw)

$Global:window
$Global:buttonGray = ""
$Global:buttonFont = ""
$Global:windowOpen = $false
[xml]$xaml = Get-Content -Path $PSScriptRoot\window.xaml
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem "Quit"

function Get-WindowsTheme {
    $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $useLightTheme = Get-ItemPropertyValue -Path $keyPath -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue
    if ($useLightTheme -eq 0) {
        $Global:buttonGray = "#525355"
        $Global:buttonFont = "#ffffff"
        return "#262626"
    } else {
        $Global:buttonGray = "#f4f4f4"
        $Global:buttonFont = "#000000"
        return "#FFFFFF"
    }
}

function Get-WindowsAccentColor {
    $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\History\Colors"
    $usedAccent = Get-ItemPropertyValue -Path $keyPath -Name "ColorHistory0" -ErrorAction SilentlyContinue
    return ("#" + ($usedAccent).ToString("X").Substring(2))
}

function Set-button {
    Param (
        [int]$buttonId
    )
    $accent = Get-WindowsAccentColor
    $button0.Background = If ($buttonId -Eq 0) {$accent} Else {$Global:buttonGray}
    $button90.Background = If ($buttonId -Eq 1) {$accent} Else {$Global:buttonGray}
    $button180.Background = If ($buttonId -Eq 2) {$accent} Else {$Global:buttonGray}
    $button270.Background = If ($buttonId -Eq 3) {$accent} Else {$Global:buttonGray}
	if ($Global:windowOpen) {$Global:window.close()}
	$Global:windowOpen = $false
}

function Get-ShellIcon {
    param (
        [int]$index
    )
    $iconPath = "$([System.Environment]::GetFolderPath('System'))\shell32.dll"
    $icon = [System.Drawing.Icon]::ExtractIcon($iconPath, $index, $false)
    return $icon
}

function contextClick {
    if ($Global:windowOpen) {return}
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)
    $window.Topmost = $true
    $window.Top = $([System.Windows.SystemParameters]::PrimaryScreenHeight - $window.Height - 40)
    $window.Left = $([System.Windows.SystemParameters]::PrimaryScreenWidth - $window.Width)
    $grid = $window.FindName('Grid')
    $grid.Background = Get-WindowsTheme
    $button0 = $window.FindName('Button0')
    $button0.Foreground = $Global:buttonFont
    $button90 = $window.FindName('Button90')
    $button90.Foreground = $Global:buttonFont
    $button180 = $window.FindName('Button180')
    $button180.Foreground = $Global:buttonFont
    $button270 = $window.FindName('Button270')
    $button270.Foreground = $Global:buttonFont
    $window.add_Closing({$Global:windowOpen = $false})
    $window.add_Deactivated({
        param(
            [System.Object]$send,
            [System.Object]$e
        )
        if (!$Global:windowOpen) {return}
        $send.close()
        $Global:windowOpen = $false
    })
    Set-Button $([Int][System.Windows.Forms.SystemInformation]::ScreenOrientation)
    $button0.add_Click({
        Set-Button 0
        [DisplayManager.Display]::Rotate(1, [DisplayManager.Display+Orientations]::DEGREES_CW_0)
    })
    $button90.add_Click({
        Set-Button 1
        [DisplayManager.Display]::Rotate(1, [DisplayManager.Display+Orientations]::DEGREES_CW_90)
    })
    $button180.add_Click({
        Set-Button 2
        [DisplayManager.Display]::Rotate(1, [DisplayManager.Display+Orientations]::DEGREES_CW_180)
    })
    $button270.add_Click({
        Set-Button 3
        [DisplayManager.Display]::Rotate(1, [DisplayManager.Display+Orientations]::DEGREES_CW_270)
    })
    $Global:windowOpen = $true
	$Global:window = $window
    $window.ShowDialog() | Out-Null
}

$exitMenuItem.add_Click({
	if ($Global:windowOpen) {$Global:window.close()}
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$notifyIcon.add_MouseClick({
    param(
        [System.Object]$send,
        [System.Object]$e
    )
    if ($e.button -eq [System.Windows.Forms.Mousebuttons]::Left) {contextClick}
})

$notifyIcon.Visible = $true
$notifyIcon.Text = "Screen rotato"
$contextMenu.Items.Add($exitMenuItem)
$notifyIcon.Icon = Get-ShellIcon -index 46
$notifyIcon.ContextMenuStrip = $contextMenu

[System.Windows.Forms.Application]::Run()
