#include maps\_utility;

precache_assets()
{
    maps\nr_stations::precache_assets();
    maps\nr_weapons::precache_assets();
    maps\nr_hud::precache_assets();
}

init()
{
    level.nr_active = true;
    level.nr_power = false;
    level.nr_relays = 0;
    if (getdvar("nr_zombie_counter") == "")
        setdvar("nr_zombie_counter",1);
    if (getdvar("nr_fov") == "")
        setdvar("nr_fov",85);
    if (getdvar("nr_difficulty") == "")
        setdvar("nr_difficulty", "modern");
    maps\nr_stations::init();
    maps\nr_weapons::register_upgraded_wall_weapons();
    level thread players_watch();
    println("NR: Nacht Reawakened initialized");
}

players_watch()
{
    for (;;)
    {
        players = get_players();
        for (i = 0; i < players.size; i++)
        {
            if (!isdefined(players[i].nr_started))
            {
                players[i].nr_started = true;
                players[i] thread player_start();
            }
        }
        wait 0.5;
    }
}

player_start()
{
    self endon("disconnect");
    self.nr_perks = [];
    self.nr_busy = false;
    self.nr_revives = 0;
    self.nr_recovering = false;
    while (!isdefined(self.score))
        wait 0.1;
    self maps\nr_hud::init();
    fov = getdvarint("nr_fov");
    if (fov < 65) fov = 65;
    if (fov > 100) fov = 100;
    self setclientdvar("cg_fov",fov);
    self thread maps\nr_perks::watch_downs();
    self thread maps\nr_debug::watch();
    cash = getdvarint("nr_cash");
    if (cash > 0)
    {
        self maps\_zombiemode_score::add_to_player_score(cash);
        self iprintlnbold("^3PLAYTEST CASH^7 | +" + cash);
    }
    self thread interactions();
    wait 2;
    self iprintlnbold("^3NACHT REAWAKENED^7 | Restore power upstairs");
    println("NR: Player bootstrap complete");
}

facing_station(station)
{
    if (!isdefined(station))
        return false;
    to = station.origin - self.origin;
    to = (to[0], to[1], 0);
    if ((to[0] * to[0] + to[1] * to[1]) < 1)
        return true;
    forward = anglesToForward(self getplayerangles());
    forward = (forward[0], forward[1], 0);
    // ~50 degree view cone
    return VectorDot(VectorNormalize(forward), VectorNormalize(to)) > 0.64;
}

interactions()
{
    self endon("disconnect");
    held = 0;
    previous = undefined;
    latched = false;
    for (;;)
    {
        self maps\nr_hud::update();
        station = undefined;
        if (isalive(self) && !level.intermission && self.sessionstate == "playing" && !self.nr_busy && !self maps\_laststand::player_is_in_laststand())
            station = maps\nr_stations::nearest(self);
        if (isdefined(station))
        {
            self maps\nr_hud::set_poster(station.id == "eggs" && self facing_station(station));
            self.nr_prompt settext(self maps\nr_stations::hint(station));
            if (!isdefined(previous) || previous != station.id)
                held = 0;
            previous = station.id;
            if (self usebuttonpressed() && !latched)
            {
                held += 0.1;
                if (held >= 0.7)
                {
                    latched = true;
                    self maps\nr_stations::purchase(station);
                }
            }
            else if (!self usebuttonpressed())
            {
                held = 0;
                latched = false;
            }
        }
        else
        {
            self maps\nr_hud::set_poster(false);
            self.nr_prompt settext("");
            previous = undefined;
            held = 0;
            if (!self usebuttonpressed())
                latched = false;
        }
        wait 0.1;
    }
}
