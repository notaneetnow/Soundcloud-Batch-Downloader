Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $basePath = [System.AppDomain]::CurrentDomain.BaseDirectory
}
else {
    $basePath = $PSScriptRoot
}

$basePath = $basePath.TrimEnd('\')

$configPath = Join-Path $basePath "settings.txt"
$toolsPath = Join-Path $basePath "tools"
$ytDlpPath = Join-Path $toolsPath "yt-dlp.exe"

$primaryColor = [System.Drawing.Color]::FromArgb(97,43,130)
$primaryHover = [System.Drawing.Color]::FromArgb(122,58,160)
$bgColor = [System.Drawing.Color]::FromArgb(18,18,24)
$cardColor = [System.Drawing.Color]::FromArgb(28,28,36)
$inputColor = [System.Drawing.Color]::FromArgb(38,38,48)
$textColor = [System.Drawing.Color]::FromArgb(235,235,240)
$mutedColor = [System.Drawing.Color]::FromArgb(155,155,165)

function Read-Settings {
    $settings = @{
        DOWNLOAD_PATH = "%USERPROFILE%\Music\SoundCloud"
        AUDIO_FORMAT = "mp3"
        EMBED_COVER = "true"
        KEEP_COVER_FILE = "false"
        KEEP_TEMP_FILES = "false"
        LANGUAGE = "English"
    }

    if (Test-Path $configPath) {
        Get-Content $configPath -Encoding UTF8 | ForEach-Object {
            if ($_ -match "^(.*?)=(.*)$") {
                $settings[$matches[1]] = $matches[2]
            }
        }
    }

    return $settings
}

function Save-Settings($settings) {
    @(
        "DOWNLOAD_PATH=$($settings.DOWNLOAD_PATH)"
        "AUDIO_FORMAT=$($settings.AUDIO_FORMAT)"
        "EMBED_COVER=$($settings.EMBED_COVER)"
        "KEEP_COVER_FILE=$($settings.KEEP_COVER_FILE)"
        "KEEP_TEMP_FILES=$($settings.KEEP_TEMP_FILES)"
        "LANGUAGE=$($settings.LANGUAGE)"
    ) | Set-Content $configPath -Encoding UTF8
}

function New-Label($text, $x, $y, $w, $h) {
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $text
    $label.Location = New-Object System.Drawing.Point($x,$y)
    $label.Size = New-Object System.Drawing.Size($w,$h)
    $label.ForeColor = $textColor
    $label.BackColor = [System.Drawing.Color]::Transparent
    $label.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    return $label
}

function Style-TextBox($box) {
    $box.BackColor = $inputColor
    $box.ForeColor = [System.Drawing.Color]::White
    $box.BorderStyle = "FixedSingle"
    $box.Font = New-Object System.Drawing.Font("Segoe UI", 10)
}

function Style-Button($button, $primary = $false) {
    if ($primary) {
        $button.BackColor = $primaryColor
        $button.Tag = "primary"
    } else {
        $button.BackColor = [System.Drawing.Color]::FromArgb(55,55,66)
        $button.Tag = "normal"
    }

    $button.ForeColor = [System.Drawing.Color]::White
    $button.FlatStyle = "Flat"
    $button.FlatAppearance.BorderSize = 0
    $button.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand

    $button.Add_MouseEnter({
        if ($this.Tag -eq "primary") {
            $this.BackColor = $primaryHover
        } else {
            $this.BackColor = [System.Drawing.Color]::FromArgb(70,70,84)
        }
    })

    $button.Add_MouseLeave({
        if ($this.Tag -eq "primary") {
            $this.BackColor = $primaryColor
        } else {
            $this.BackColor = [System.Drawing.Color]::FromArgb(55,55,66)
        }
    })
}

function Style-CheckBox($checkBox) {
    $checkBox.ForeColor = $textColor
    $checkBox.BackColor = [System.Drawing.Color]::Transparent
    $checkBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
}

$settings = Read-Settings
$displayDownloadPath = [Environment]::ExpandEnvironmentVariables($settings.DOWNLOAD_PATH)

$form = New-Object System.Windows.Forms.Form
$form.Text = "SoundCloud Batch Downloader - @notaneetnow"
$form.Size = New-Object System.Drawing.Size(600,680)
$form.StartPosition = "CenterScreen"
$form.BackColor = $bgColor
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0,0)
$header.Size = New-Object System.Drawing.Size(600,90)
$header.BackColor = [System.Drawing.Color]::FromArgb(24,20,32)
$form.Controls.Add($header)

$accentBar = New-Object System.Windows.Forms.Panel
$accentBar.Location = New-Object System.Drawing.Point(0,0)
$accentBar.Size = New-Object System.Drawing.Size(600,6)
$accentBar.BackColor = $primaryColor
$header.Controls.Add($accentBar)

$title = New-Object System.Windows.Forms.Label
$title.Text = "SoundCloud Batch Downloader"
$title.Location = New-Object System.Drawing.Point(32,22)
$title.Size = New-Object System.Drawing.Size(360,30)
$title.ForeColor = [System.Drawing.Color]::White
$title.BackColor = [System.Drawing.Color]::Transparent
$title.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 17)
$header.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "Playlist to audio files - Powered by yt-dlp"
$subtitle.Location = New-Object System.Drawing.Point(34,56)
$subtitle.Size = New-Object System.Drawing.Size(365,22)
$subtitle.ForeColor = $mutedColor
$subtitle.BackColor = [System.Drawing.Color]::Transparent
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$header.Controls.Add($subtitle)

$languageBox = New-Object System.Windows.Forms.ComboBox
$languageBox.Location = New-Object System.Drawing.Point(420,55)
$languageBox.Size = New-Object System.Drawing.Size(140,24)
$languageBox.Items.AddRange(@("English","中文","日本語"))
$languageBox.DropDownStyle = "DropDownList"
$languageBox.BackColor = $inputColor
$languageBox.ForeColor = [System.Drawing.Color]::White
$languageBox.FlatStyle = "Flat"
$languageBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$header.Controls.Add($languageBox)

$languageBox.SelectedItem = $settings.LANGUAGE
if (-not $languageBox.SelectedItem) {
    $languageBox.SelectedItem = "English"
}

$panel = New-Object System.Windows.Forms.Panel
$panel.Location = New-Object System.Drawing.Point(34,112)
$panel.Size = New-Object System.Drawing.Size(515,345)
$panel.BackColor = $cardColor
$form.Controls.Add($panel)

$labelUrl = New-Label "SoundCloud Playlist Address" 28 24 455 22
$panel.Controls.Add($labelUrl)

$textUrl = New-Object System.Windows.Forms.TextBox
$textUrl.Location = New-Object System.Drawing.Point(28,50)
$textUrl.Size = New-Object System.Drawing.Size(455,28)
Style-TextBox $textUrl
$panel.Controls.Add($textUrl)

$labelPath = New-Label "Default Saving Path" 28 94 455 22
$panel.Controls.Add($labelPath)

$textPath = New-Object System.Windows.Forms.TextBox
$textPath.Location = New-Object System.Drawing.Point(28,120)
$textPath.Size = New-Object System.Drawing.Size(340,28)
$textPath.Text = $displayDownloadPath
Style-TextBox $textPath
$panel.Controls.Add($textPath)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse"
$browseButton.Location = New-Object System.Drawing.Point(382,119)
$browseButton.Size = New-Object System.Drawing.Size(101,30)
Style-Button $browseButton
$panel.Controls.Add($browseButton)

$labelFormat = New-Label "Audio Format" 28 172 180 22
$panel.Controls.Add($labelFormat)

$comboFormat = New-Object System.Windows.Forms.ComboBox
$comboFormat.Location = New-Object System.Drawing.Point(28,198)
$comboFormat.Size = New-Object System.Drawing.Size(140,28)
$comboFormat.Items.AddRange(@("mp3","m4a","flac","wav"))
$comboFormat.Text = $settings.AUDIO_FORMAT
$comboFormat.DropDownStyle = "DropDownList"
$comboFormat.BackColor = $inputColor
$comboFormat.ForeColor = [System.Drawing.Color]::White
$comboFormat.FlatStyle = "Flat"
$comboFormat.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$panel.Controls.Add($comboFormat)

$checkEmbedCover = New-Object System.Windows.Forms.CheckBox
$checkEmbedCover.Text = "Embed cover into audio"
$checkEmbedCover.Location = New-Object System.Drawing.Point(205,194)
$checkEmbedCover.Size = New-Object System.Drawing.Size(270,28)
$checkEmbedCover.Checked = ($settings.EMBED_COVER -eq "true")
Style-CheckBox $checkEmbedCover
$panel.Controls.Add($checkEmbedCover)

$checkKeepCover = New-Object System.Windows.Forms.CheckBox
$checkKeepCover.Text = "Keep separate cover image"
$checkKeepCover.Location = New-Object System.Drawing.Point(205,228)
$checkKeepCover.Size = New-Object System.Drawing.Size(270,28)
$checkKeepCover.Checked = ($settings.KEEP_COVER_FILE -eq "true")
Style-CheckBox $checkKeepCover
$panel.Controls.Add($checkKeepCover)

$checkKeepTemp = New-Object System.Windows.Forms.CheckBox
$checkKeepTemp.Text = "Keep .part / .ytdl temporary files"
$checkKeepTemp.Location = New-Object System.Drawing.Point(205,262)
$checkKeepTemp.Size = New-Object System.Drawing.Size(290,28)
$checkKeepTemp.Checked = ($settings.KEEP_TEMP_FILES -eq "true")
Style-CheckBox $checkKeepTemp
$panel.Controls.Add($checkKeepTemp)

$hint = New-Object System.Windows.Forms.Label
$hint.Text = "Advice: For clean folders, keep only MP3 output and embed covers."
$hint.Location = New-Object System.Drawing.Point(28,306)
$hint.Size = New-Object System.Drawing.Size(455,22)
$hint.ForeColor = $mutedColor
$hint.BackColor = [System.Drawing.Color]::Transparent
$hint.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$panel.Controls.Add($hint)

$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.Location = New-Object System.Drawing.Point(34,480)
$statusPanel.Size = New-Object System.Drawing.Size(515,38)
$statusPanel.BackColor = [System.Drawing.Color]::FromArgb(24,24,31)
$form.Controls.Add($statusPanel)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready - Settings are remembered automatically"
$statusLabel.Location = New-Object System.Drawing.Point(14,9)
$statusLabel.Size = New-Object System.Drawing.Size(485,22)
$statusLabel.ForeColor = $mutedColor
$statusLabel.BackColor = [System.Drawing.Color]::Transparent
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusPanel.Controls.Add($statusLabel)

$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Location = New-Object System.Drawing.Point(34,555)
$buttonPanel.Size = New-Object System.Drawing.Size(515,45)
$buttonPanel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($buttonPanel)

$xButton = New-Object System.Windows.Forms.Button
$xButton.Text = "@notaneetnow"
$xButton.Location = New-Object System.Drawing.Point(0,3)
$xButton.Size = New-Object System.Drawing.Size(130,38)
Style-Button $xButton
$buttonPanel.Controls.Add($xButton)

$xButton.BackColor = [System.Drawing.Color]::FromArgb(38,38,48)
$xButton.ForeColor = [System.Drawing.Color]::FromArgb(170,170,180)

$xButton.Add_MouseEnter({
    $this.BackColor = [System.Drawing.Color]::FromArgb(38,38,48)
    $this.ForeColor = [System.Drawing.Color]::FromArgb(170,170,180)
})

$xButton.Add_MouseLeave({
    $this.BackColor = [System.Drawing.Color]::FromArgb(38,38,48)
    $this.ForeColor = [System.Drawing.Color]::FromArgb(170,170,180)
})

$openFolderButton = New-Object System.Windows.Forms.Button
$openFolderButton.Text = "Open Folder"
$openFolderButton.Location = New-Object System.Drawing.Point(215,3)
$openFolderButton.Size = New-Object System.Drawing.Size(130,38)
Style-Button $openFolderButton
$buttonPanel.Controls.Add($openFolderButton)

$downloadButton = New-Object System.Windows.Forms.Button
$downloadButton.Text = "Start Download"
$downloadButton.Location = New-Object System.Drawing.Point(360,3)
$downloadButton.Size = New-Object System.Drawing.Size(145,38)
Style-Button $downloadButton $true
$buttonPanel.Controls.Add($downloadButton)

function Apply-Language {
    if ($languageBox.Text -eq "中文") {
        $title.Text = "SoundCloud 批量下载器"
        $subtitle.Text = "播放列表转音频文件 - Powered by yt-dlp"
        $labelUrl.Text = "SoundCloud 播放列表地址"
        $labelPath.Text = "默认保存位置"
        $labelFormat.Text = "音频格式"
        $checkEmbedCover.Text = "把封面嵌入音频"
        $checkKeepCover.Text = "保留单独封面图片"
        $checkKeepTemp.Text = "保留 .part / .ytdl 临时文件"
        $hint.Text = "建议：想保持文件夹干净，只保留 MP3 并嵌入封面。"
        $statusLabel.Text = "准备就绪 - 设置会自动记住"
        $browseButton.Text = "浏览"
        $openFolderButton.Text = "打开文件夹"
        $downloadButton.Text = "开始下载"
    }
    elseif ($languageBox.Text -eq "日本語") {
        $title.Text = "SoundCloud 一括ダウンローダー"
        $subtitle.Text = "プレイリストを音声ファイルへ - Powered by yt-dlp"
        $labelUrl.Text = "SoundCloud プレイリスト URL"
        $labelPath.Text = "保存先フォルダー"
        $labelFormat.Text = "音声形式"
        $checkEmbedCover.Text = "カバーを音声に埋め込む"
        $checkKeepCover.Text = "カバー画像を保存する"
        $checkKeepTemp.Text = ".part / .ytdl 一時ファイルを保存"
        $hint.Text = "おすすめ：フォルダーを綺麗にするなら MP3 と埋め込みカバーのみ。"
        $statusLabel.Text = "準備完了 - 設定は自動保存されます"
        $browseButton.Text = "参照"
        $openFolderButton.Text = "フォルダー"
        $downloadButton.Text = "ダウンロード"
    }
    else {
        $title.Text = "SoundCloud Batch Downloader"
        $subtitle.Text = "Playlist to audio files - Powered by yt-dlp"
        $labelUrl.Text = "SoundCloud Playlist Address"
        $labelPath.Text = "Default Saving Path"
        $labelFormat.Text = "Audio Format"
        $checkEmbedCover.Text = "Embed cover into audio"
        $checkKeepCover.Text = "Keep separate cover image"
        $checkKeepTemp.Text = "Keep .part / .ytdl temporary files"
        $hint.Text = "Advice: For clean folders, keep only MP3 output and embed covers."
        $statusLabel.Text = "Ready - Settings are remembered automatically"
        $browseButton.Text = "Browse"
        $openFolderButton.Text = "Open Folder"
        $downloadButton.Text = "Start Download"
    }
}

$languageBox.Add_SelectedIndexChanged({
    $settings.LANGUAGE = $languageBox.Text
    Save-Settings $settings
    Apply-Language
})

Apply-Language

$form.Add_Shown({
    $textUrl.Focus()
})

$xButton.Add_Click({
    Start-Process "https://x.com/notaneetnow"
})

$browseButton.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.SelectedPath = $textPath.Text

    if ($folderDialog.ShowDialog() -eq "OK") {
        $textPath.Text = $folderDialog.SelectedPath
        $statusLabel.Text = "Saving path selected"
    }
})

$openFolderButton.Add_Click({
    $path = [Environment]::ExpandEnvironmentVariables($textPath.Text.Trim())

    if (!(Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }

    Start-Process explorer.exe $path
})

$downloadButton.Add_Click({
    $url = $textUrl.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($url)) {
        [System.Windows.Forms.MessageBox]::Show("Enter Playlist Address", "Missing URL")
        return
    }

    if (!(Test-Path $ytDlpPath)) {
        [System.Windows.Forms.MessageBox]::Show("yt-dlp.exe not found: $ytDlpPath", "Missing yt-dlp")
        return
    }

    $downloadPath = [Environment]::ExpandEnvironmentVariables($textPath.Text.Trim())

    $settings.DOWNLOAD_PATH = $downloadPath
    $settings.AUDIO_FORMAT = $comboFormat.Text.Trim()
    $settings.EMBED_COVER = $checkEmbedCover.Checked.ToString().ToLower()
    $settings.KEEP_COVER_FILE = $checkKeepCover.Checked.ToString().ToLower()
    $settings.KEEP_TEMP_FILES = $checkKeepTemp.Checked.ToString().ToLower()
    $settings.LANGUAGE = $languageBox.Text

    Save-Settings $settings

    if (!(Test-Path $downloadPath)) {
        New-Item -ItemType Directory -Path $downloadPath -Force | Out-Null
    }

    $statusLabel.Text = "Download started - PowerShell window opened"

    $currentLanguage = $languageBox.SelectedItem.ToString()

$doneTitle = "Download Complete"
$doneMessage = "Download finished successfully."
$failTitle = "Download Failed"
$failMessage = "Download failed. Please check the PowerShell window."

if ($currentLanguage -eq "中文") {
    $doneTitle = "下载完成"
    $doneMessage = "下载已成功完成。"
    $failTitle = "下载失败"
    $failMessage = "下载失败，请检查 PowerShell 窗口。"
}
elseif ($currentLanguage -eq "日本語") {
    $doneTitle = "ダウンロード完了"
    $doneMessage = "ダウンロードが完了しました。"
    $failTitle = "ダウンロード失敗"
    $failMessage = "ダウンロードに失敗しました。PowerShell ウィンドウを確認してください。"
}

$runScriptPath = Join-Path $env:TEMP ("soundcloud_downloader_" + [Guid]::NewGuid().ToString() + ".ps1")

$embedCoverArg = ""
if ($checkEmbedCover.Checked) {
    $embedCoverArg = "--embed-thumbnail"
}

$writeCoverArg = ""
if ($checkKeepCover.Checked) {
    $writeCoverArg = "--write-thumbnail"
}

$tempArg = ""
if (!$checkKeepTemp.Checked) {
    $tempArg = "--no-continue --no-part"
}

$runScript = @"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

`$ytDlpPath = '$ytDlpPath'
`$downloadPath = '$downloadPath'
`$audioFormat = '$($settings.AUDIO_FORMAT)'
`$url = '$url'
`$outputTemplate = Join-Path `$downloadPath '%(playlist_title)s\%(title)s.%(ext)s'

& `$ytDlpPath -x --audio-format `$audioFormat --add-metadata --no-keep-fragments $embedCoverArg $writeCoverArg $tempArg -o `$outputTemplate `$url

`$topForm = New-Object System.Windows.Forms.Form
`$topForm.TopMost = `$true
`$topForm.StartPosition = "CenterScreen"
`$topForm.Size = New-Object System.Drawing.Size(1,1)
`$topForm.Show()
`$topForm.Hide()

if (`$LASTEXITCODE -eq 0) {
    [System.Windows.Forms.MessageBox]::Show(`$topForm, '$doneMessage', '$doneTitle')
}
else {
    [System.Windows.Forms.MessageBox]::Show(`$topForm, '$failMessage', '$failTitle')
}

`$topForm.Dispose()
Remove-Item '$runScriptPath' -Force -ErrorAction SilentlyContinue
exit
"@

$runScript | Set-Content $runScriptPath -Encoding UTF8

Start-Process powershell -ArgumentList @(
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$runScriptPath`""
)
})

[void]$form.ShowDialog()