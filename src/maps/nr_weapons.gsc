#include maps\_utility;

precache_assets()
{
    maps\nr_weapon_table::precache_assets();
}

upgrade()
{
    gun = self getcurrentweapon();
    if (!isdefined(level.nr_upgrades[gun]))
    {
        self iprintln("^3This weapon is already upgraded or cannot be upgraded");
        return;
    }
    if (self.score < 5000)
    {
        self iprintln("^1Pack-a-Punch costs 5000 points");
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
    self maps\_zombiemode_score::minus_to_player_score(5000);
    self takeweapon(gun);
    self givemaxammo(upgraded);
    self setweaponammoclip(upgraded,weaponclipsize(upgraded));
    self switchtoweapon(upgraded);
    self.nr_busy = false;
    self iprintlnbold("^3PACK-A-PUNCH^7 | Weapon upgraded");
    println("NR: UPGRADE " + gun + " -> " + upgraded);
}
