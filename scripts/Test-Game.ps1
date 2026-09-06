param([string]$GamePath = 'C:\Call Of Duty World At War', [switch]$AutoTest)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$running = Get-Process CoDWaW -ErrorAction SilentlyContinue
if ($running) { throw 'Close the existing WaW session before starting an isolated test.' }
$target = Join-Path $root 'runtime/mods/nacht_reawakened'
[IO.Directory]::CreateDirectory($target) | Out-Null
Copy-Item (Join-Path $root 'dist/nacht_reawakened/mod.ff') (Join-Path $target 'mod.ff') -Force
Copy-Item (Join-Path $root 'dist/nacht_reawakened/nacht_reawakened.iwd') (Join-Path $target 'nacht_reawakened.iwd') -Force
$args = '+set fs_homepath "' + (Join-Path $root 'runtime') + '" +set fs_game mods/nacht_reawakened +set snd_volume 0 +set r_fullscreen 0 +set r_mode 1280x720 +set developer 1 +set logfile 2 +set g_log nr-tests.log +set com_introPlayed 1'
if ($AutoTest) { $args += ' +set nr_autotest 1' } else { $args += ' +set nr_autotest 0' }
$args += ' +devmap nazi_zombie_prototype'
Start-Process -FilePath (Join-Path $GamePath 'CoDWaW.exe') -WorkingDirectory $GamePath -ArgumentList $args -Wait
