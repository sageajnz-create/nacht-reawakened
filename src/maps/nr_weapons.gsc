#include maps\_utility;

precache_assets()
{
    maps\nr_weapon_table::precache_assets();
}

register_upgraded_wall_weapons()
{
    // Wall buys look up cost/hint in level.zombie_weapons. Register each PaP variant
    // using the base wall price so promote_wall_buys can swap them safely.
    if (!isdefined(level.nr_upgrades) || !isdefined(level.zombie_weapons))
        return;
    keys = getarraykeys(level.nr_upgrades);
    for (i = 0; i < keys.size; i++)
    {
        base = keys[i];
        up = level.nr_upgrades[base];
        if (isdefined(level.zombie_weapons[up]))
            continue;
        if (!isdefined(level.zombie_weapons[base]))
            continue;
        src = level.zombie_weapons[base];
        struct = spawnstruct();
        struct.weapon_name = up;
        struct.weapon_classname = "weapon_" + up;
        struct.hint = src.hint;
        struct.cost = src.cost;
        struct.ammo_cost = src.ammo_cost;
        level.zombie_weapons[up] = struct;
    }
    println("NR: registered upgraded wall weapon entries");
}

promote_wall_buys(base_gun, upgraded)
{
    if (!isdefined(base_gun) || !isdefined(upgraded))
        return;
    names = [];
    names[names.size] = base_gun;
    if (isdefined(level.nr_upgrades))
    {
        keys = getarraykeys(level.nr_upgrades);
        for (i = 0; i < keys.size; i++)
        {
            if (level.nr_upgrades[keys[i]] == upgraded)
                names[names.size] = keys[i];
        }
    }
    count = 0;
    count += promote_ents(getentarray("weapon_upgrade", "targetname"), names, upgraded);
    count += promote_ents(getentarray("weapon_cabinet_use", "targetname"), names, upgraded);
    if (count > 0)
        iprintln("^3Wall buy Pack-a-Punched^7");
    println("NR: WALL PROMOTE " + base_gun + " -> " + upgraded + " count=" + count);
}

promote_ents(ents, names, upgraded)
{
    count = 0;
    if (!isdefined(ents))
        return 0;
    for (i = 0; i < ents.size; i++)
    {
        if (!isdefined(ents[i].zombie_weapon_upgrade))
            continue;
        for (n = 0; n < names.size; n++)
        {
            if (ents[i].zombie_weapon_upgrade != names[n])
                continue;
            ents[i].zombie_weapon_upgrade = upgraded;
            if (isdefined(level.zombie_weapons[upgraded]))
                ents[i] SetHintString(level.zombie_weapons[upgraded].hint);
            count++;
            break;
        }
    }
    return count;
}

upgrade()
{
    gun = self getcurrentweapon();
    if (!isdefined(level.nr_upgrades[gun]))
    {
        self iprintln("^3This weapon is already upgraded or cannot be upgraded");
        return;
    }
    cost = 1250;
    if (isdefined(level.nr_pack_cost))
        cost = level.nr_pack_cost;
    if (self.score < cost)
    {
        self iprintln("^1Pack-a-Punch costs " + cost + " points");
        return;
    }
    // Validate the replacement before charging or removing the original.
    // No waits: another gameplay thread cannot interrupt this transaction.
    self.nr_busy = true;
    upgraded = level.nr_upgrades[gun];
    self giveweapon(upgraded);
    if (!self hasweapon(upgraded))
    {
        self.nr_busy = false;
        self iprintln("^1Upgrade unavailable | Your weapon and points were kept");
        return;
    }
    self maps\_zombiemode_score::minus_to_player_score(cost);
    self takeweapon(gun);
    self givemaxammo(upgraded);
    self setweaponammoclip(upgraded,weaponclipsize(upgraded));
    self switchtoweapon(upgraded);
    self.nr_busy = false;
    promote_wall_buys(gun, upgraded);
    self iprintlnbold("^3PACK-A-PUNCH^7 | Weapon upgraded");
    println("NR: UPGRADE " + gun + " -> " + upgraded);
}