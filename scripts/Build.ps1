param([string]$GamePath = 'C:\Call Of Duty World At War', [switch]$Install)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
& "$PSScriptRoot/Prepare.ps1"
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'Preparation failed' }

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
if (-not $py) { throw 'Python is required to clone mx_nr_stones into nr_radio.ff' }
& $py.Source "$PSScriptRoot/Clone-RadioAlias.py" --game-path $GamePath --root $root
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'Clone-RadioAlias failed' }
$radioFf = Join-Path $root 'build/nr_radio.ff'
if (!(Test-Path -LiteralPath $radioFf)) { throw "Missing cloned radio fastfile: $radioFf" }

$zones = Join-Path $GamePath 'zone/english'
$linkerArgs = @('--asset-search-path','src;stock/weapons','--output-folder','build')
foreach ($name in @('common','code_post_gfx','nazi_zombie_prototype','nazi_zombie_factory')) { $linkerArgs += @('-l',(Join-Path $zones "$name.ff")) }
$linkerArgs += @('-l', $radioFf)
$linkerArgs += 'mod'
& './tools/oat-032/Linker.exe' @linkerArgs *> tools/build.log
if ($LASTEXITCODE -ne 0) { Get-Content tools/build.log -Tail 25; throw "Link failed: $LASTEXITCODE" }
$release = Join-Path $root 'dist/nacht_reawakened'
[IO.Directory]::CreateDirectory($release) | Out-Null
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$iwd = Join-Path $release 'nacht_reawakened.iwd'
$pendingIwd = Join-Path $root 'build/nacht_reawakened.pending.iwd'
if (Test-Path -LiteralPath $pendingIwd) { Remove-Item -LiteralPath $pendingIwd }
# Pack dedicated Stones & Cheese stream as IWD backup (STORE so it can stream).
# Retail playback still requires the loose files Deploy-StonesStream copies.
$archive = [IO.Compression.ZipFile]::Open($pendingIwd, [IO.Compression.ZipArchiveMode]::Create)
try {
    $source = Join-Path $root 'src'
    foreach ($file in Get-ChildItem -LiteralPath $source -Recurse -File) {
        $relative = $file.FullName.Substring($source.Length + 1).Replace('\','/')
        if ($relative.StartsWith('sound/', [StringComparison]::OrdinalIgnoreCase)) { continue }
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $relative) | Out-Null
    }
    $song = Join-Path $source 'sound/Stream/Music/Mission/zombie/mx_nr_stones.wav'
    if (!(Test-Path -LiteralPath $song)) { throw "Missing Stones & Cheese stream: $song" }
    $store = [IO.Compression.CompressionLevel]::NoCompression
    foreach ($entry in @(
        'sound/Stream/Music/Mission/zombie/mx_nr_stones.wav',
        'sound/Stream/music/Mission/zombie/mx_nr_stones.wav'
    )) {
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $song, $entry, $store) | Out-Null
    }
} finally { $archive.Dispose() }
Copy-Item build/mod.ff (Join-Path $release 'mod.ff') -Force
Copy-Item $radioFf (Join-Path $release 'nr_radio.ff') -Force
Move-Item -LiteralPath $pendingIwd -Destination $iwd -Force
& "$PSScriptRoot/Deploy-StonesStream.ps1" -TargetModDir $release
if ($Install) {
    & "$PSScriptRoot/Install.ps1"
}
Get-Content tools/build.log -Tail 4
Get-ChildItem $release -Recurse | Select-Object FullName,Length
