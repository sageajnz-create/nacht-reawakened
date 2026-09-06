# Install the already-built release without rebuilding the tested assets.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (Get-Process CoDWaW -ErrorAction SilentlyContinue) {
    throw 'Close WaW before installing the release.'
}
$release = Join-Path $root 'dist/nacht_reawakened'
$target = Join-Path $env:LOCALAPPDATA 'Activision/CoDWaW/mods/nacht_reawakened'
$files = @('mod.ff', 'nacht_reawakened.iwd')
foreach ($name in $files) {
    if (!(Test-Path -LiteralPath (Join-Path $release $name))) { throw "Missing release file: $name" }
}
$backup = Join-Path $root ('backups/installed-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
foreach ($name in $files) {
    $existing = Join-Path $target $name
    if (Test-Path -LiteralPath $existing) {
        [IO.Directory]::CreateDirectory($backup) | Out-Null
        Copy-Item -LiteralPath $existing -Destination (Join-Path $backup $name)
    }
}
[IO.Directory]::CreateDirectory($target) | Out-Null
foreach ($name in $files) {
    $from = Join-Path $release $name
    $to = Join-Path $target $name
    Copy-Item -LiteralPath $from -Destination $to -Force
    if ((Get-FileHash -LiteralPath $from).Hash -ne (Get-FileHash -LiteralPath $to).Hash) {
        throw "Installed file verification failed: $name. Previous files are in $backup"
    }
}
Write-Output "Installed and verified: $target"
if (Test-Path -LiteralPath $backup) { Write-Output "Previous installed release: $backup" }
