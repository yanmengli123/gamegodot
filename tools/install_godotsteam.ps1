# GodotSteam 一键安装（Windows PowerShell）
# 用法：powershell -ExecutionPolicy Bypass -File install_godotsteam.ps1

$GODOT_VERSION = "4.6.3"
$ADDON_DIR = Join-Path (Split-Path -Parent $PSCommandPath) "..\demo\addons\godotsteam"

Write-Host "=== GodotSteam Installer ===" -ForegroundColor Green
Write-Host "Godot version: $GODOT_VERSION"
Write-Host "Addon dir: $ADDON_DIR"

if (-not (Test-Path $ADDON_DIR)) {
    New-Item -ItemType Directory -Path $ADDON_DIR -Force | Out-Null
}

$TMPDIR = Join-Path $env:TEMP "godotsteam_$([guid]::NewGuid())"
New-Item -ItemType Directory -Path $TMPDIR | Out-Null

try {
    Write-Host "Fetching latest GodotSteam release info..."
    $api = Invoke-RestMethod -Uri "https://api.github.com/repos/Grashopr/godot_steam/releases/latest"
    $url = $api.assets[0].browser_download_url
    Write-Host "Latest: $url"
    $zipPath = Join-Path $TMPDIR "godotsteam.zip"
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing

    Write-Host "Extracting..."
    Expand-Archive -Path $zipPath -DestinationPath $TMPDIR -Force

    $source = Join-Path $TMPDIR "gdsteam"
    if (Test-Path $source) {
        Copy-Item -Path "$source\*" -Destination $ADDON_DIR -Recurse -Force
        Write-Host "✅ Installed to $ADDON_DIR" -ForegroundColor Green
    } else {
        Write-Host "❌ gdsteam/ not found" -ForegroundColor Red
        exit 1
    }
} finally {
    Remove-Item -Path $TMPDIR -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Next: restart Godot and enable plugin in Project Settings > Plugins"
