# ============================================================
#  Kaguya 液态玻璃皮肤 · 网络一键安装（Windows PowerShell）
#  由用户在终端粘贴的一条命令下载并执行：
#    irm https://raw.githubusercontent.com/DaRin1403/Darin-Public-Workspace/main/install-oneline.ps1 | iex
#  （国内网络可换用 jsdelivr 镜像：
#    irm https://cdn.jsdelivr.net/gh/DaRin1403/Darin-Public-Workspace@main/install-oneline.ps1 | iex）
#  流程：下载最新仓库 zip → 解压到临时目录 → 执行仓库内「一键安装.ps1」→ 清理。
# ============================================================
$ErrorActionPreference = 'Stop'

$base = 'https://github.com/DaRin1403/Darin-Public-Workspace'
$url  = "$base/archive/refs/heads/main.zip"
$tmp  = Join-Path $env:TEMP "kaguya-theme-install"
$zip  = Join-Path $tmp 'repo.zip'

New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    Write-Host '[1/4] 正在下载最新版皮肤仓库…' -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing -TimeoutSec 300

    Write-Host '[2/4] 解压中…' -ForegroundColor Cyan
    Expand-Archive -Path $zip -DestinationPath $tmp -Force

    $inner = Get-ChildItem -Path $tmp -Directory | Where-Object { $_.Name -like 'Darin-Public-Workspace*' } | Select-Object -First 1
    if (-not $inner) { throw '解压结果里没找到仓库目录' }

    Write-Host '[3/4] 开始安装…' -ForegroundColor Cyan
    & (Join-Path $inner.FullName '一键安装.ps1')

    Write-Host '[4/4] 全部完成！' -ForegroundColor Green
    Write-Host ''
    Write-Host '最后一步：重启 dsh web，浏览器打开 http://127.0.0.1:3080（浅色模式）即可看到 Kaguya 皮肤。' -ForegroundColor Yellow
} catch {
    Write-Host ''
    Write-Host "[失败] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host '如果卡在下载（网络无法直连 GitHub），请手动下载桌面压缩包 Kaguya_Theme_1.1.0.zip，解压后双击「一键安装.bat」即可。' -ForegroundColor Yellow
    exit 1
} finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
