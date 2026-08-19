# ============================================================
#  Kaguya 液态玻璃皮肤 · 一键安装脚本（Windows PowerShell）
#  用法：双击「一键安装.bat」，或在仓库根目录运行本脚本。
#  效果：复制皮肤包到 DSH profile + 合并挂载行（可重复运行）。
# ============================================================
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pkg  = Join-Path $root 'anime-theme'
if (-not (Test-Path (Join-Path $pkg 'package.json'))) {
    Write-Host '[错误] 没有在脚本旁边找到 anime-theme 包。请把本脚本放在仓库根目录再运行。' -ForegroundColor Red
    exit 1
}

# 1. 定位 DSH profile 目录（可用 DSH_HOME 覆盖）
$dshHome = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE '.dsh' }
$profile = Join-Path $dshHome 'profiles\web'
if (-not (Test-Path $profile)) {
    Write-Host "[错误] 找不到 DSH profile 目录：$profile" -ForegroundColor Red
    Write-Host '如果你的 DSH 装在别处，先设置环境变量 DSH_HOME 再运行本脚本。' -ForegroundColor Yellow
    exit 1
}

# 2. 复制皮肤包（覆盖更新，幂等）
$dest = Join-Path $profile 'node_modules\anime-theme'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item -Path (Join-Path $pkg '*') -Destination $dest -Recurse -Force
Write-Host "[1/3] 皮肤包已安装：$dest" -ForegroundColor Green

# 3. 合并挂载行（幂等：已存在则跳过；修改前自动备份）
$patch = Join-Path $profile 'cordis.patch.yml'
$row   = "- insert:`n    - id: ui-anime-theme`n      name: 'anime-theme'`n"
if (-not (Test-Path $patch)) {
    [System.IO.File]::WriteAllText($patch, $row, $utf8)
    Write-Host '[2/3] 已创建 cordis.patch.yml 并写入挂载行' -ForegroundColor Green
} else {
    $content = [System.IO.File]::ReadAllText($patch)
    if ($content -match 'ui-anime-theme') {
        Write-Host '[2/3] 挂载行已存在，跳过' -ForegroundColor Green
    } else {
        $bak = "$patch.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $patch $bak
        if (-not $content.EndsWith("`n")) { $content += "`n" }
        [System.IO.File]::WriteAllText($patch, $content + $row, $utf8)
        Write-Host "[2/3] 挂载行已追加（原文件备份到 $bak）" -ForegroundColor Green
    }
}

# 4. 完成提示
Write-Host '[3/3] 安装完成！' -ForegroundColor Green
Write-Host ''
Write-Host '下一步：重启 dsh web，然后浏览器打开 http://127.0.0.1:3080（浅色模式）即可看到 Kaguya 皮肤。' -ForegroundColor Cyan
Write-Host '以后更新皮肤：把新文件放进本仓库目录，再运行一次本脚本，浏览器 F5 即可。' -ForegroundColor Cyan
