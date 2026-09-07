#include maps\_utility;
#include maps\_music;

precache_assets()
{
    precachemodel("zombie_vending_revive_on");
    precachemodel("zombie_vending_jugg_on");
    precachemodel("zombie_vending_sleight_on");
    precachemodel("zombie_vending_doubletap_on");
    precachemodel("zombie_vending_packapunch_on");
    precachemodel("zombie_power_lever");
    precachemodel("zombie_power_lever_handle");
    precachemodel("zombie_perk_bottle_sleight");
    precachemodel("static_berlin_ger_radio");
    precacheshader("nr_stones_and_cheese");
}

init()
{
    level.nr_stations = [];
    level.nr_eggs_playing = false;
    add("revive", "QUICK REVIVE", 500, (-200, 55, 8), 90, "zombie_vending_revive_on", (0.25,0.65,1));
    add("jug", "JUGGERNOG", 2500, (970, 640, 8), 180, "zombie_vending_jugg_on", (1,0.22,0.16));
    add("speed", "SPEED COLA", 3000, (760, 990, 8), 270, "zombie_vending_sleight_on", (0.3,1,0.45));
    add("tap", "DOUBLE TAP II", 2000, (1020, 780, 160), 270, "zombie_vending_doubletap_on", (1,0.65,0.15));
    add("stamina", "STAMIN-UP", 2000, (-220, 800, 160), 95, "zombie_vending_sleight_on", (1,0.9,0.3));
    add("pack", "PACK-A-PUNCH", 5000, (620, 1000, 148), 0, "zombie_vending_packapunch_on", (0.5,0.8,1));
    add("power", "RESTORE POWER", 0, (395, 1000, 168), 0, "zombie_power_lever", (1,0.8,0.35));
    add("relay_a", "STARTING ROOM RELAY", 0, (200, -380, 48), 90, "zombie_power_lever", (1,0.8,0.35));
    add("relay_b", "HELP ROOM RELAY", 0, (1040, 830, 40), 270, "zombie_power_lever", (1,0.8,0.35));
    add("eggs", "STONES & CHEESE", 0, (130, -378, 4), 180, "static_berlin_ger_radio", (0.45,1,0.35));
}

add(id, label, cost, origin, yaw, model, color)
{
    station = spawnstruct();
    station.id = id;
    station.label = label;
    station.cost = cost;
    station.origin = origin;
    station.color = color;
    station.model = spawn("script_model", origin);
    station.model setmodel(model);
    station.model.angles = (0,yaw,0);
    station.used = false;
    if (id == "power" || id == "relay_a" || id == "relay_b")
    {
        station.handle = spawn("script_model", origin);
        station.handle setmodel("zombie_power_lever_handle");
        station.handle.angles = (0,yaw,0);
    }
    level.nr_stations[level.nr_stations.size] = station;
}

nearest(player)
{
    best = undefined;
    bestdist = 105;
    for (i = 0; i < level.nr_stations.size; i++)
    {
        station = level.nr_stations[i];
        if (abs(player.origin[2] - station.origin[2]) > 65)
            continue;
        d = distance2d(player.origin, station.origin);
        if (d < bestdist)
        {
            trace = bullettrace(player geteye(), station.origin + (0,0,35), false, player);
            if (trace["fraction"] < 0.85)
                continue;
            best = station;
            bestdist = d;
        }
    }
    return best;
}

hint(station)
{
    id = station.id;
    if (station.used)
        return station.label + " | ONLINE";
    if (id != "power" && id != "revive" && id != "eggs" && !level.nr_power)
        return station.label + " | Requires power upstairs";
    if (id == "eggs")
    {
        if (level.nr_eggs_playing)
            return "Hold USE | Stop Stones & Cheese";
        return "Hold USE | Stones & Cheese";
    }
    if (id == "pack" && level.nr_relays < 2)
        return "PACK-A-PUNCH | Activate both downstairs relays";
    if (isdefined(self.nr_perks[id]) && self.nr_perks[id])
        return station.label + " | Owned";
    if (id == "revive" && get_players().size == 1 && self.nr_revives >= 3)
        return "QUICK REVIVE | Solo limit reached";
    cost = station.cost;
    if (id == "revive" && get_players().size > 1)
        cost = 1500;
    if (id == "pack")
    {
        if (!isdefined(level.nr_upgrades[self getcurrentweapon()]))
            return "PACK-A-PUNCH | Select a weapon that can be upgraded";
        return "Hold USE | " + station.label + " [" + cost + "]";
    }
    return "Hold USE | " + station.label + " [" + cost + "]";
}

purchase(station)
{
    if (!isdefined(station) || station.used || !isalive(self) || level.intermission || self.nr_busy || self maps\_laststand::player_is_in_laststand())
        return;
    id = station.id;
    if (id != "power" && id != "revive" && id != "eggs" && !level.nr_power)
        return;
    if (id == "power")
    {
        station.used = true;
        level.nr_power = true;
        iprintlnbold("^3POWER RESTORED^7 | Activate both downstairs relays");
        println("NR: POWER ON");
        return;
    }
    if (id == "eggs")
    {
        if (!level.nr_eggs_playing)
        {
            level.nr_eggs_playing = true;
            level.eggs = 1;
            // Hard-stop WAVE_1 on the client first (fake musicState skip left wave fading under Stones).
            setmusicstate("SILENT");
            wait(0.15);
            setmusicstate("eggs");
            iprintlnbold("^3STONES & CHEESE^7 | Reggae forever");
            println("NR: EGGS music start");
        }
        else
        {
            level.nr_eggs_playing = false;
            level.eggs = 0;
            setmusicstate("SILENT");
            iprintlnbold("^3RADIO OFF^7");
            println("NR: EGGS music stop");
        }
        return;
    }
    if (id == "relay_a" || id == "relay_b")
    {
        if (station.used)
            return;
        station.used = true;
        level.nr_relays++;
        if (level.nr_relays == 2)
            iprintlnbold("^3PACK-A-PUNCH ONLINE^7 | Return upstairs");
        else
            iprintlnbold("^3RELAY ONLINE^7 | One relay remaining");
        println("NR: RELAY ONLINE " + id);
        return;
    }
    if (id == "pack")
    {
        if (level.nr_relays == 2)
            self maps\nr_weapons::upgrade();
        return;
    }
    if (isdefined(self.nr_perks[id]) && self.nr_perks[id])
        return;
    if (id == "revive" && get_players().size == 1 && self.nr_revives >= 3)
        return;
    cost = station.cost;
    if (id == "revive" && get_players().size > 1)
        cost = 1500;
    if (self.score < cost)
    {
        self iprintln("^1Not enough points");
        return;
    }
    self maps\_zombiemode_score::minus_to_player_score(cost);
    self.nr_perks[id] = true;
    self maps\nr_perks::apply(id);
    self iprintln("^3" + station.label + "^7 acquired");
    println("NR: PURCHASE " + id + " score=" + self.score);
}
