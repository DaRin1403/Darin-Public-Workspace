# ============================================================
#  Kaguya 液态玻璃皮肤 · 一键卸载脚本（Windows PowerShell）
#  效果：从 cordis.patch.yml 移除挂载行 + 删除皮肤包目录。
# ============================================================
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)

$dshHome = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE '.dsh' }
$profile = Join-Path $dshHome 'profiles\web'

$patch = Join-Path $profile 'cordis.patch.yml'
if (Test-Path $patch) {
    $content = [System.IO.File]::ReadAllText($patch)
    if ($content -match 'ui-anime-theme') {
        $bak = "$patch.bak-uninstall-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $patch $bak
        # 移除挂载行块：- insert: 到 name: 'anime-theme'（含缩进），保留其余内容
        $new = $content -replace "(?m)^- insert:\r?\n(\s+- id: ui-anime-theme\r?\n\s+name: 'anime-theme'\r?\n)", ''
        [System.IO.File]::WriteAllText($patch, $new, $utf8)
        Write-Host '[1/2] 挂载行已移除（原文件备份到 ' -NoNewline -ForegroundColor Green
        Write-Host $bak -NoNewline -ForegroundColor Green
        Write-Host '）' -ForegroundColor Green
    } else {
        Write-Host '[1/2] 挂载行不存在，跳过' -ForegroundColor Green
    }
} else {
    Write-Host '[1/2] cordis.patch.yml 不存在，跳过' -ForegroundColor Green
}

$dest = Join-Path $profile 'node_modules\anime-theme'
if (Test-Path $dest) {
    Remove-Item $dest -Recurse -Force
    Write-Host '[2/2] 皮肤包目录已删除' -ForegroundColor Green
} else {
    Write-Host '[2/2] 皮肤包目录不存在，跳过' -ForegroundColor Green
}

Write-Host ''
Write-Host '卸载完成。重启 dsh web 后恢复官方界面。' -ForegroundColor Cyan
