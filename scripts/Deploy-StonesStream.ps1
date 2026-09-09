# Copy the dedicated Stones & Cheese stream as loose files. WaW retail streamed
# music resolves from on-disk mod files; do not delete an existing stream.
param(
    [Parameter(Mandatory = $true)][string]$TargetModDir,
    [string]$SongPath = ''
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (-not $SongPath) {
    $candidates = @(
        (Join-Path $root 'dist/nacht_reawakened/sound/Stream/Music/Mission/zombie/mx_nr_stones.wav'),
        (Join-Path $root 'src/sound/Stream/Music/Mission/zombie/mx_nr_stones.wav')
    )
    $SongPath = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $SongPath -or -not (Test-Path -LiteralPath $SongPath)) {
    throw 'Missing Stones & Cheese stream (mx_nr_stones.wav).'
}
$relPaths = @(
    'sound/Stream/Music/Mission/zombie/mx_nr_stones.wav',
    'sound/Stream/music/Mission/zombie/mx_nr_stones.wav'
)
$copied = @()
foreach ($rel in $relPaths) {
    $dest = Join-Path $TargetModDir ($rel -replace '/', [IO.Path]::DirectorySeparatorChar)
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dest)) | Out-Null
    Copy-Item -LiteralPath $SongPath -Destination $dest -Force
    if ((Get-FileHash -LiteralPath $SongPath).Hash -ne (Get-FileHash -LiteralPath $dest).Hash) {
        throw "Loose Stones stream verification failed: $dest"
    }
    $copied += $dest
}
# Remove leftover game-over hijack from older installs; keep mx_nr_stones.
foreach ($legacy in @(
    'sound/Stream/Music/Mission/zombie/mx_game_over.wav',
    'sound/Stream/music/Mission/zombie/mx_game_over.wav'
)) {
    $legacyPath = Join-Path $TargetModDir ($legacy -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (Test-Path -LiteralPath $legacyPath) {
        Remove-Item -LiteralPath $legacyPath -Force
    }
}
Write-Output "Deployed loose Stones stream:"
$copied | ForEach-Object { Write-Output "  $_" }
