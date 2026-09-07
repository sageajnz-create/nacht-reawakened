#include maps\_utility;

// Development commands are inert in normal map launches.
watch()
{
    self endon("disconnect");
    if (!getdvarint("sv_cheats"))
        return;
    if (getdvarint("nr_autotest"))
        self thread test_suite();
    for (;;)
    {
        command = getdvar("nr_test");
        if (command != "")
        {
            setdvar("nr_test", "");
            if (command == "funds")
                self maps\_zombiemode_score::add_to_player_score(50000);
            else if (command == "position")
                println("NR: POSITION " + self.origin);
            else if (command == "hurt")
                self dodamage(300,self.origin);
            else if (command == "ammo")
            {
                drop = spawnstruct();
                drop.hint = "MAX AMMO";
                level maps\_zombiemode_powerups::full_ammo_powerup(drop);
            }
            else
            {
                for (i = 0; i < level.nr_stations.size; i++)
                {
                    s = level.nr_stations[i];
                    if (command == s.id)
                    {
                        // Facing toward the machine from its model's forward side.
                        forward = anglesToForward(s.model.angles);
                        self setorigin(s.origin + forward*80 + (0,0,12));
                        self setplayerangles(s.model.angles + (0,180,0));
                    }
                    if (command == "buy_" + s.id)
                        self maps\nr_stations::purchase(s);
                }
            }
            println("NR: TEST " + command + " score=" + self.score);
        }
        wait 0.25;
    }
}

check(condition, label)
{
    if (condition)
    {
        println("NR TEST PASS: " + label + "\n");
        setdvar("nr_last_test", "PASS " + label);
    }
    else
    {
        println("NR TEST FAIL: " + label + "\n");
        setdvar("nr_last_test", "FAIL " + label);
        setdvar("nr_test_failures", getdvar("nr_test_failures") + " | " + label);
        level.nr_test_failures++;
    }
}

test_suite()
{
    self endon("disconnect");
    level.nr_test_failures = 0;
    setdvar("nr_test_failures", "");
    setdvar("nr_test_result", "RUNNING");
    self EnableInvulnerability();
    self.ignoreme = true;
    wait 2;
    self.nr_perks = [];
    self.score = 500;
    jug = level.nr_stations[1];
    self maps\nr_stations::purchase(jug);
    check(self.score == 500 && !isdefined(self.nr_perks["jug"]), "power gates perks");
    self maps\nr_stations::purchase(level.nr_stations[0]);
    check(self.score == 0 && self.nr_perks["revive"], "solo revive available before power");
    self maps\nr_stations::purchase(level.nr_stations[6]);
    check(level.nr_power, "power switch");
    self maps\nr_stations::purchase(jug);
    check(self.score == 0 && !isdefined(self.nr_perks["jug"]), "insufficient funds rejected");
    self maps\_zombiemode_score::add_to_player_score(200000);
    before = self.score;
    self maps\nr_stations::purchase(level.nr_stations[5]);
    check(self.score == before, "Pack-a-Punch requires both relays");
    self maps\nr_stations::purchase(level.nr_stations[7]);
    self maps\nr_stations::purchase(level.nr_stations[7]);
    check(level.nr_relays == 1, "relay cannot be activated twice");
    self maps\nr_stations::purchase(level.nr_stations[8]);
    check(level.nr_relays == 2, "both relays unlock Pack-a-Punch");
    self maps\nr_stations::purchase(jug);
    check(self.maxhealth == 250 && self.health == 250, "Juggernog health");
    before = self.score;
    self maps\nr_stations::purchase(jug);
    check(self.score == before, "duplicate perk does not charge");
    self.nr_busy = true;
    self maps\nr_stations::purchase(level.nr_stations[2]);
    check(self.score == before && !isdefined(self.nr_perks["speed"]), "purchases blocked during recovery or another transaction");
    self.nr_busy = false;
    self maps\nr_stations::purchase(level.nr_stations[2]);
    check(self hasperk("specialty_fastreload"), "Speed Cola applied");
    self maps\nr_stations::purchase(level.nr_stations[3]);
    check(self hasperk("specialty_rof"), "Double Tap applied");
    self maps\nr_stations::purchase(level.nr_stations[4]);
    check(self hasperk("specialty_longersprint"), "Stamin-Up applied");
    self giveweapon("thompson");
    self setweaponammoclip("thompson", 7);
    self switchtoweapon("zombie_colt");
    wait 1;
    before = self.score;
    self maps\nr_stations::purchase(level.nr_stations[5]);
    wait 1;
    check(self hasweapon("nr_colt") && !self hasweapon("zombie_colt") && self.score == before-1250, "starting pistol upgrade and cost");
    check(self hasweapon("thompson") && self getweaponammoclip("thompson") == 7, "upgrade preserves the second weapon and its ammo");
    before = self.score;
    self maps\nr_stations::purchase(level.nr_stations[5]);
    check(self.score == before, "repeat upgrade rejected");
    self setweaponammoclip("nr_colt",0);
    drop = spawnstruct();
    drop.hint = "MAX AMMO";
    level maps\_zombiemode_powerups::full_ammo_powerup(drop);
    check(self getweaponammoclip("nr_colt") == weaponclipsize("nr_colt"), "Max Ammo fills upgraded magazine");
    before = self.score;
    level maps\nr_powerups::bonus();
    check(self.score == before+500, "Bonus Points reward");
    self test_all_upgrades();
    self test_double_tap();
    self.health = 200;
    self.maxhealth = 250;
    wait 8;
    setdvar("nr_regen_result", "health=" + self.health + " cap=" + self.maxhealth);
    check(self.health == 250 && self.maxhealth == 250, "Juggernog regenerates to its full health cap");
    for (i = 0; i < 3; i++)
    {
        // One purchase supplies three charges; no repurchase between recoveries.
        before = self.score;
        self DisableInvulnerability();
        wait 1;
        self dodamage(10000,self.origin);
        wait 0.1;
        check(self.nr_recovering, "solo lethal hit intercepted through damage callback");
        wait 9.1;
        check(self.nr_revives == i+1 && !self.nr_recovering && !isdefined(self.revivetrigger), "solo revive restores player");
        check(!isdefined(self.nr_perks["jug"]) && self.maxhealth == 100, "non-revive perks lost on down");
        check(self.score == before && !self.nr_busy && !self.ignoreme, "recovery releases player without an extra charge");
        self EnableInvulnerability();
        self.ignoreme = true;
    }
    before = self.score;
    self maps\nr_stations::purchase(level.nr_stations[0]);
    check(self.score == before && !isdefined(self.nr_perks["revive"]), "three self-revives limit");
    check(!self maps\nr_perks::intercept_damage(300,"MOD_MELEE"), "normal death resumes after revive limit");
    self DisableInvulnerability();
    wait 1;
    self dodamage(10000,self.origin);
    wait 2;
    check(level.intermission, "lethal damage ends the game after three recoveries");
    println("NR TEST COMPLETE failures=" + level.nr_test_failures + "\n");
    setdvar("nr_test_result", "COMPLETE failures=" + level.nr_test_failures);
    self iprintlnbold("TEST COMPLETE | Failures: " + level.nr_test_failures);
    setdvar("nr_autotest", 0);
}

// Exercise the live zombie damage listener with controlled bullet notifications.
// This isolates the perk's additional damage from aim, penetration and hit location.
empty_damage_func(type, loc, point, player)
{
}

test_double_tap()
{
    enemies = getaiarray("axis");
    check(enemies.size > 0, "zombie available for Double Tap damage checks");
    if (!enemies.size) return;
    enemy = enemies[0];
    enemy.health = 1000;
    enemy.maxhealth = 1000;
    self.nr_perks["tap"] = false;
    enemy notify("damage", 25, self, (1,0,0), enemy.origin, "MOD_RIFLE_BULLET");
    wait 0.2;
    check(enemy.health == 1000, "no bonus bullet damage without Double Tap");
    self.nr_perks["tap"] = true;
    enemy notify("damage", 25, self, (1,0,0), enemy.origin, "MOD_RIFLE_BULLET");
    wait 0.2;
    check(enemy.health == 975, "Double Tap adds one bullet of damage");
    // Stock zombie_damage chips grenades with DoDamage(round + random). Stub it so this
    // assert only measures Double Tap II (bullet-only extra damage in _gameskill).
    old_damage_func = level.global_damage_func;
    level.global_damage_func = maps\nr_debug::empty_damage_func;
    enemy notify("damage", 25, self, (1,0,0), enemy.origin, "MOD_GRENADE_SPLASH");
    wait 0.2;
    level.global_damage_func = old_damage_func;
    check(enemy.health == 975, "Double Tap does not multiply explosive damage");
    enemy.health = 10;
    enemy notify("damage", 25, self, (1,0,0), enemy.origin, "MOD_RIFLE_BULLET");
    wait 0.3;
    check(!isdefined(enemy) || !isalive(enemy), "Double Tap bonus damage can finish a zombie");
}

test_all_upgrades()
{
    originals = getarraykeys(level.nr_upgrades);
    for (w = 0; w < originals.size; w++)
    {
        gun = originals[w];
        upgraded = level.nr_upgrades[gun];
        self takeallweapons();
        self giveweapon(gun);
        self switchtoweapon(gun);
        wait 1;
        check(self getcurrentweapon() == gun, "equip original " + gun);
        before = self.score;
        self maps\nr_stations::purchase(level.nr_stations[5]);
        wait 1;
        check(self hasweapon(upgraded) && !self hasweapon(gun) && self.score == before-1250, "upgrade transaction " + gun);
        check(self getcurrentweapon() == upgraded, "equip upgrade " + gun);
        self setweaponammoclip(upgraded, 0);
        drop = spawnstruct();
        drop.hint = "MAX AMMO";
        level maps\_zombiemode_powerups::full_ammo_powerup(drop);
        check(self getweaponammoclip(upgraded) == weaponclipsize(upgraded), "refill upgrade " + gun);
    }
}
