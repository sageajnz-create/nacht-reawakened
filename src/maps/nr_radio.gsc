#include maps\_utility;
#include maps\_music;

// Stones & Cheese radio EE. Retail mods-menu does not load custom eggs musicState,
// so this plays dedicated alias mx_nr_stones on a script_origin (cloned into mod.ff).

init()
{
    level.nr_eggs_playing = false;
    level.eggs = 0;
    level.nr_radio_alias = "mx_nr_stones";
}

start(station)
{
    if (isdefined(level.nr_eggs_playing) && level.nr_eggs_playing)
        return;

    level notify("nr_radio_stop");
    clear_emitter();

    level.nr_eggs_playing = true;
    level.eggs = 1;
    level.nr_radio_previous_music = level.musicState;
    setmusicstate("SILENT");

    origin = (0, 0, 0);
    if (isdefined(station) && isdefined(station.origin))
        origin = station.origin;

    level.nr_eggs_ent = spawn("script_origin", origin);
    level.nr_eggs_ent playsound("mx_nr_stones", "nr_track_finished");
    level.nr_eggs_ent thread finish_track();

    iprintlnbold("^3STONES & CHEESE^7 | Reggae forever");
    println("NR: EGGS music start (playsound mx_nr_stones)");
}

stop()
{
    level notify("nr_radio_stop");

    playing = isdefined(level.nr_eggs_playing) && level.nr_eggs_playing;
    level.nr_eggs_playing = false;
    level.eggs = 0;
    clear_emitter();

    previous = "WAVE_1";
    if (isdefined(level.nr_radio_previous_music) && level.nr_radio_previous_music != "" && level.nr_radio_previous_music != "SILENT" && level.nr_radio_previous_music != "eggs")
        previous = level.nr_radio_previous_music;
    setmusicstate(previous);

    if (playing)
    {
        iprintlnbold("^3RADIO OFF^7");
        println("NR: EGGS music stop");
    }
}

finish_track()
{
    self endon("death");
    level endon("nr_radio_stop");
    self waittill("nr_track_finished");
    maps\nr_radio::stop();
}

clear_emitter()
{
    if (isdefined(level.nr_eggs_ent))
    {
        level.nr_eggs_ent stopsounds();
        level.nr_eggs_ent delete();
        level.nr_eggs_ent = undefined;
    }
}

verify()
{
    return isdefined(level.nr_eggs_playing) && level.nr_eggs_playing && isdefined(level.nr_eggs_ent);
}
