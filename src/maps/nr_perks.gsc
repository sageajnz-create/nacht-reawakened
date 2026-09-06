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

clear()
{
    // Solo Quick Revive is a 3-charge perk: keep it through downs until spent.
    keep_revive = false;
    if (get_players().size == 1 && isdefined(self.nr_perks["revive"]) && self.nr_perks["revive"] && self.nr_revives < 3)
        keep_revive = true;

    self.nr_perks = [];
    self unsetperk("specialty_fastreload");
    self unsetperk("specialty_rof");
    self unsetperk("specialty_quickrevive");
    self unsetperk("specialty_longersprint");
    self setmovespeedscale(1);
    self.maxhealth = 100;

    if (keep_revive)
    {
        self.nr_perks["revive"] = true;
        self setperk("specialty_quickrevive");
    }
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
    if (get_players().size != 1 || !isdefined(self.nr_perks["revive"]) || !self.nr_perks["revive"])
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
    self clear();
    self.maxhealth = 100;
    self.health = 100;
    recovery_hud = self maps\nr_hud::text_element(0,15,1.5,(1,0.78,0.35),"center","middle");
    recovery_hud.alignx = "center";
    for (i = 6; i > 0; i--)
    {
        recovery_hud settext("QUICK REVIVE / " + i);
        wait 1;
    }
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

// WaW rawfile scripts do not reliably resolve waittill_any from
// common_scripts\utility, and stock waittill_any only waits on arg1
// (args 2+ are endons). Use builtin waittill for "any of these".
watch_downs()
{
    self endon("disconnect");
    for (;;)
    {
        self nr_waittill_downed();
        self clear();
        wait 0.1;
    }
}

nr_waittill_downed()
{
    self endon("disconnect");
    ent = spawnstruct();
    self thread nr_waittill_downed_msg(ent, "player_downed");
    self thread nr_waittill_downed_msg(ent, "death");
    self thread nr_waittill_downed_msg(ent, "fake_death");
    ent waittill("done");
}

nr_waittill_downed_msg(ent, msg)
{
    self endon("disconnect");
    ent endon("done");
    self waittill(msg);
    ent notify("done");
}
