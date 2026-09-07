$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
function Write-Utf8($path, $text) {
    $full = Join-Path $root $path
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($full)) | Out-Null
    [IO.File]::WriteAllText($full, $text, [Text.UTF8Encoding]::new($false))
}
function Replace-Once($text, $old, $new) {
    if (($text.Split(@($old), [StringSplitOptions]::None).Count - 1) -ne 1) { throw "Patch target not unique: $old" }
    return $text.Replace($old,$new)
}
$main = Get-Content stock/patch/maps/nazi_zombie_prototype.gsc -Raw
$main = Replace-Once $main 'maps\_destructible_opel_blitz::init();' "maps\nr_main::precache_assets();`n`tmaps\_destructible_opel_blitz::init();"
$main = Replace-Once $main 'init_sounds();' "init_sounds();`n`tmaps\nr_main::init();"
$main = Replace-Once $main 'include_powerup( "full_ammo" );' "include_powerup( `"full_ammo`" );`n`tinclude_powerup( `"bonus_points`" );"
Write-Utf8 'src/maps/nazi_zombie_prototype.gsc' $main

$callback = Get-Content stock/common/maps/_callbackglobal.gsc -Raw
$signature = 'Callback_PlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime )'
$callback = Replace-Once $callback ($signature + "`r`n{") ($signature + "`r`n{`r`n`tif (self maps\nr_perks::intercept_damage(iDamage, sMeansOfDeath)) return;")
Write-Utf8 'src/maps/_callbackglobal.gsc' $callback

$laststand = Get-Content stock/common/maps/_laststand.gsc -Raw
$laststand = Replace-Once $laststand 'reviveTime = 3;' "reviveTime = 3;`n`tif (isdefined(level.nr_active) && self hasperk(`"specialty_quickrevive`")) reviveTime = 1.5;"
$laststand = Replace-Once $laststand "revive_trigger_think()`r`n{" "revive_trigger_think()`r`n{`r`n`tself endon(`"player_revived`");"
Write-Utf8 'src/maps/_laststand.gsc' $laststand

$skill = Get-Content stock/common/maps/_gameskill.gsc -Raw
$needle = 'self waittill( "damage", amount, attacker, direction_vec, point, type );'
$hook = @'

        // Double Tap II: extra bullet damage only (not explosives/melee/fire).
        if (isdefined(level.nr_active) && isdefined(attacker) && isplayer(attacker) && isdefined(attacker.nr_perks) && isdefined(attacker.nr_perks["tap"]) && attacker.nr_perks["tap"] && isalive(self))
        {
            is_bullet = false;
            if (isdefined(type))
            {
                if (type == "MOD_RIFLE_BULLET")
                    is_bullet = true;
                else if (type == "MOD_PISTOL_BULLET")
                    is_bullet = true;
            }
            if (is_bullet)
            {
                if (self.health > amount)
                    self.health -= amount;
                else
                {
                    self dodamage(amount, point, attacker);
                    wait 0.05;
                }
            }
        }
'@
$skill = Replace-Once $skill $needle ($needle + $hook)
# WaW's SetNormalHealth uses the engine's 100-health baseline, not the
# script maxhealth field raised by Juggernog. Keep the existing regen timing.
$skill = Replace-Once $skill 'self setnormalhealth( newHealth );' @'
{
                    if (isdefined(level.nr_active))
                    {
                        healthCap = self.maxhealth;
                        self.health = int(newHealth * self.maxhealth);
                        self.maxhealth = healthCap;
                    }
                    else
                        self setnormalhealth( newHealth );
                }
'@
$skill = Replace-Once $skill 'self setnormalhealth( 2 / self.maxHealth );' @'
if (isdefined(level.nr_active))
            {
                healthCap = self.maxhealth;
                self.health = 2;
                self.maxhealth = healthCap;
            }
            else
                self setnormalhealth( 2 / self.maxHealth );
'@
$skill = Replace-Once $skill "shouldShowCoverWarning()`r`n{" "shouldShowCoverWarning()`r`n{`r`n`tif (isdefined(level.nr_active)) return false;"
Write-Utf8 'src/maps/_gameskill.gsc' $skill

$spawner = Get-Content stock/patch/maps/_zombiemode_spawner_prototype.gsc -Raw
$spawner = $spawner.Replace('self PushPlayer( true );','self PushPlayer( getdvar("nr_difficulty") == "classic" );')
Write-Utf8 'src/maps/_zombiemode_spawner_prototype.gsc' $spawner
$mode = Get-Content stock/patch/maps/_zombiemode_prototype.gsc -Raw
$mode = Replace-Once $mode 'level.zombie_total = max;' @'
if (getdvar("nr_difficulty") != "classic")
    {
        max = int((5 + level.round_number*2 + level.round_number*level.round_number*0.12) * (1 + (get_players().size-1)*0.5));
        if (getdvar("nr_difficulty") == "relaxed") max = int(max*0.75);
    }
    level.zombie_total = max;
'@
Write-Utf8 'src/maps/_zombiemode_prototype.gsc' $mode
# EE owns the mx_game_over stream; keep death sting on round_over (Prepare regenerates this file).
$modeFile = Get-Content 'src/maps/_zombiemode_prototype.gsc' -Raw
$modeFile = $modeFile -replace 'add_sound\(\s*"end_of_game"\s*,\s*"mx_game_over"\s*\);', 'add_sound( "end_of_game", "round_over" ); // EE owns mx_game_over stream'
Write-Utf8 'src/maps/_zombiemode_prototype.gsc' $modeFile

$powerups = Get-Content stock/nacht/maps/_zombiemode_powerups.gsc -Raw
$needle = 'add_zombie_powerup( "full_ammo",  "zombie_ammocan", &"ZOMBIE_POWERUP_MAX_AMMO");'
# Keep patch independent of the stock tab alignment.
$rx = [regex]'(?m)^.*add_zombie_powerup\( "full_ammo".*$'
if ($rx.Matches($powerups).Count -ne 1) { throw 'Missing powerup registration' }
$powerups = $rx.Replace($powerups, '$0' + "`n`tadd_zombie_powerup( `"bonus_points`", `"zombie_x2_icon`", `"BONUS POINTS`" );")
$powerups = Replace-Once $powerups 'players[i] GiveMaxAmmo( primaryWeapons[x] );' "players[i] GiveMaxAmmo( primaryWeapons[x] );`n`t`t`tplayers[i] SetWeaponAmmoClip(primaryWeapons[x], WeaponClipSize(primaryWeapons[x]));"
$powerups = Replace-Once $powerups 'level.zombie_vars["zombie_point_scalar"] *= 2;' 'level.zombie_vars["zombie_point_scalar"] = 2;'
$powerups = Replace-Once $powerups 'case "nuke":' "case `"bonus_points`":`n`t`t`t`t`t`t`tlevel maps\nr_powerups::bonus();`n`t`t`t`t`t`t`tbreak;`n`t`t`t`t`t`tcase `"nuke`":"
# Ground-snap powerup drops so window/ledge kills do not float.
$powerups = Replace-Once $powerups 'powerup = spawn ("script_model", drop_point + (0,0,40));' "trace = bullettrace( drop_point + (0,0,80), drop_point + (0,0,-1000), false, undefined );`n`tdrop_origin = drop_point + (0,0,12);`n`tif ( isdefined( trace ) && isdefined( trace[`"position`"] ) && trace[`"fraction`"] < 1 )`n`t`tdrop_origin = trace[`"position`"] + (0,0,12);`n`tpowerup = spawn (`"script_model`", drop_origin);"
Write-Utf8 'src/maps/_zombiemode_powerups.gsc' $powerups

$upgrades = [ordered]@{
    colt='Bunker Buster'; sw_357='Last Word'; m1carbine='Carbine Reborn'; m1garand='Dead Reckoning'; gewehr43='Geist 43';
    stg44='Sturm Repeater'; thompson='Chicago Revenant'; mp40='Afterlife 40'; kar98k='Long Night'; springfield='Dawn Breaker';
    ptrs41_zombie='Iron Verdict'; kar98k_scoped_zombie='Night Watch'; m1garand_gl='Dead Reckoning GL';
    m2_flamethrower_zombie='Hell Furnace'; doublebarrel='Twin Reapers'; doublebarrel_sawed_grip='Pocket Apocalypse';
    shotgun='Trench Sweeper'; fg42_bipod='Fallen Guard'; mg42_bipod='Grave Digger'; '30cal_bipod'='Midnight Thunder';
    bar='Browning Afterlife'; panzerschrek='Bunker Breaker'; ray_gun='Ray of Reckoning'
}
$gsc = "// Generated by scripts/Prepare.ps1 from the installed stock weapons.`nprecache_assets()`n{`n    level.nr_upgrades = [];`n"
$weaponZones = @()
foreach ($entry in $upgrades.GetEnumerator()) {
    $name = $entry.Key
    $tokens = (Get-Content "stock/weapons/weapons/$name" -Raw).Split('\')
    $fields = [ordered]@{}
    for ($i=1; $i -lt $tokens.Length-1; $i+=2) { $fields[$tokens[$i]] = $tokens[$i+1] }
    $fields['displayName'] = $entry.Value
    $fields['ammoName'] = "nr_$name"
    $fields['clipName'] = "nr_$name"
    foreach ($key in @('ammoPickupSound','ammoPickupSoundPlayer','emptyFireSound','emptyFireSoundPlayer')) {
        if ($fields[$key] -in @('weap_ammo_pickup','player_out_of_ammo')) { $fields[$key] = '' }
    }
    foreach ($key in @('damage','minDamage','explosionInnerDamage','explosionOuterDamage')) {
        if ($fields.Contains($key)) { $fields[$key] = [string]([int]$fields[$key]*4) }
    }
    foreach ($key in @('maxAmmo','startAmmo')) {
        if ($fields.Contains($key)) { $fields[$key] = [string]([Math]::Min(1200,[int]$fields[$key]*2)) }
    }
    if ([int]$fields['clipSize'] -gt 2) { $fields['clipSize'] = [string][Math]::Min(150,[Math]::Ceiling([int]$fields['clipSize']*1.5)) }
    # Keep underbarrel grenade launchers functional; their stock alternate weapon remains available.
    $out = 'WEAPONFILE'
    foreach ($field in $fields.GetEnumerator()) { $out += '\' + $field.Key + '\' + $field.Value }
    Write-Utf8 "src/weapons/nr_$name" $out
    # The SP raw parser has an 8 KiB limit. OAT emits every empty/default field;
    # omit zero/empty fields only in the raw runtime copy, keeping the full FF source.
    $compact = 'WEAPONFILE'
    foreach ($field in $fields.GetEnumerator()) {
        if ($field.Value -ne '' -and $field.Value -ne '0') { $compact += '\' + $field.Key + '\' + $field.Value }
    }
    if ([Text.Encoding]::UTF8.GetByteCount($compact) -ge 8192) { throw "Weapon too large for WaW SP parser: $name" }
    Write-Utf8 "src/weapons/sp/nr_$name" $compact
    $gsc += "    level.nr_upgrades[`"$name`"] = `"nr_$name`";`n    precacheitem(`"nr_$name`");`n"
    $weaponZones += "weapon,nr_$name"
}
$gsc += "    level.nr_upgrades[`"zombie_colt`"] = `"nr_colt`";`n}`n"
Write-Utf8 'src/maps/nr_weapon_table.gsc' $gsc

$zone = @('>game,T4')
foreach ($name in @('revive','jugg','sleight','doubletap','packapunch')) { $zone += "xmodel,zombie_vending_${name}_on" }
$zone += 'xmodel,zombie_power_lever','xmodel,zombie_power_lever_handle','xmodel,zombie_perk_bottle_sleight','xmodel,static_berlin_ger_radio'
$zone += 'material,nr_stones_and_cheese'
foreach ($name in @('juggernaut','fastreload','doubletap','quickrevive')) { $zone += "material,specialty_${name}_zombies" }
$zone += $weaponZones
Get-ChildItem src/maps -Filter '*.gsc' | Sort-Object Name | ForEach-Object { $zone += 'rawfile,maps/' + $_.Name }
Get-ChildItem src/clientscripts -Filter '*.csc' -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object { $zone += 'rawfile,clientscripts/' + $_.Name }
Write-Utf8 'zone_source/mod.zone' ($zone -join "`n")
Write-Output "Prepared $($upgrades.Count) upgrades and stock script patches."
