#include maps\_utility;
#include common_scripts\utility;

apply(id)
{
    switch (id)
    {
        case "jug":
            self.maxhealth = 250;
            self.health = 250;
            break;
        case "speed":
            self setperk("specialty_fastreload");
            break;
        case "tap":
            self setperk("specialty_rof");
            break;
        case "revive":
            self setperk("specialty_quickrevive");
            break;
        case "stamina":
            self setmovespeedscale(1.15);
            self setperk("specialty_longersprint");
            break;
    }
}

owned(id)
{
    return isdefined(self.nr_perks) && isdefined(self.nr_perks[id]) && self.nr_perks[id];
}

// Reapply every truthy nr_perks entry. Do not refill Jug HP while still
// downed (revivetrigger present) so restore cannot stand the player up early.
restore_owned()
{
    if (!isdefined(self.nr_perks))
        return;

    downed = self maps\_laststand::player_is_in_laststand();
    ids = [];
    ids[0] = "jug";
    ids[1] = "speed";
    ids[2] = "tap";
    ids[3] = "revive";
    ids[4] = "stamina";
    for (i = 0; i < ids.size; i++)
    {
        if (!self owned(ids[i]))
            continue;
        if (ids[i] == "jug" && downed)
        {
            self.maxhealth = 250;
            continue;
        }
        self apply(ids[i]);
    }
}

// Solo Quick Revive is a 3-charge perk. Other purchased perks are never
// stripped on down; only QR is spent after the third self-revive.
spend_solo_quick_revive()
{
    if (get_players().size != 1 || self.nr_revives < 3 || !self owned("revive"))
        return;
    self.nr_perks["revive"] = false;
    self unsetperk("specialty_quickrevive");
}

// Called before the stock player damage handler; true means this hit is consumed.
intercept_damage(damage, means)
{
    if (getdvarint("nr_autotest") && getdvarint("sv_cheats"))
        setdvar("nr_damage_trace", "damage=" + damage + " health=" + self.health + " means=" + means);
    if (!isdefined(level.nr_active) || !isdefined(self.nr_perks))
        return false;
    if (isdefined(self.nr_recovering) && self.nr_recovering)
        return true;
    if (damage < self.health || means == "MOD_CRUSH" || means == "MOD_FALLING")
        return false;
    if (get_players().size != 1 || !self owned("revive"))
        return false;
    if (self.nr_revives >= 3 || level.intermission)
        return false;
    // Consume the lethal hit before Nacht's player_damage_override can end the game.
    self.nr_recovering = true;
    self.nr_revives++;
    self EnableInvulnerability();
    self.ignoreme = true;
    self thread recover();
    return true;
}

recover()
{
    self endon("disconnect");
    self.nr_busy = true;
    self freezecontrols(true);
    self disableweapons();
    // Do NOT call PlayerLastStand here: on solo Nacht that path feeds
    // player_damage_override / end_game and mission-fails instead of reviving.
    // Do NOT clear() ownership. Stock-style 100 HP reset is overwritten by
    // restore_owned() so Jug/Speed/Tap/Stamin-Up survive the line below.
    self spend_solo_quick_revive();
    self.maxhealth = 100;
    self.health = 100;
    self restore_owned();
    recovery_hud = self maps\nr_hud::text_element(0,15,1.5,(1,0.78,0.35),"center","middle");
    recovery_hud.alignx = "center";
    for (i = 6; i > 0; i--)
    {
        recovery_hud settext("QUICK REVIVE / " + i);
        wait 1;
    }
    self restore_owned();
    self.nr_busy = false;
    self freezecontrols(false);
    self enableweapons();
    recovery_hud destroy();
    self iprintlnbold("^3BACK IN THE FIGHT^7 | " + (3-self.nr_revives) + " self-revives left");
    wait 3;
    self.ignoreme = false;
    self DisableInvulnerability();
    self.nr_recovering = false;
    println("NR: SELF REVIVE COMPLETE " + self.nr_revives);
}

// Keep ownership during last stand. Stock revive_success notifies
// player_revived BEFORE reviveplayer(), which resets health to 100 and can
// drop specialty flags. Wait until laststand has ended, then restore.
watch_downs()
{
    self endon("disconnect");
    for (;;)
    {
        self waittill("player_revived");
        waittillframeend;
        while (isdefined(self) && self maps\_laststand::player_is_in_laststand())
            wait 0.05;
        if (isdefined(self))
            self restore_owned();
    }
}
