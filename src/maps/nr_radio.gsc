#include maps\_utility;
#include maps\_music;

// Downstairs Stones & Cheese radio. Playback uses dedicated alias mx_nr_stones
// (cloned into mod.ff via scripts/Clone-RadioAlias.py + nr_radio.ff). Streamed
// WAV must exist as a loose file under the installed mod; IWD packing is backup.

init()
{
    level.nr_eggs_playing = false;
    level.nr_radio_alias = "mx_nr_stones";
}

toggle(origin)
{
    if (!isdefined(level.nr_eggs_playing))
        level.nr_eggs_playing = false;
    if (level.nr_eggs_playing)
        stop_song();
    else
        start_song(origin);
}

start_song(origin)
{
    level.nr_eggs_playing = true;
    level.eggs = 1;
    // Duck WAVE_1 when our amb CSC is loaded (developer/devmap). Retail ignores unknown states.
    setmusicstate("SILENT");
    wait(0.15);
    stop_emitter();
    if (!isdefined(origin))
        origin = (0, 0, 0);
    // 2D local + world emitter so start works on retail and stop can kill the origin.
    players = get_players();
    for (i = 0; i < players.size; i++)
        players[i] playlocalsound("mx_nr_stones");
    level.nr_eggs_ent = spawn("script_origin", origin);
    level.nr_eggs_ent playsound("mx_nr_stones");
    setmusicstate("eggs");
    iprintlnbold("^3STONES & CHEESE^7 | Reggae forever");
    println("NR: EGGS music start (mx_nr_stones)");
}

stop_song()
{
    level.nr_eggs_playing = false;
    level.eggs = 0;
    stop_emitter();
    setmusicstate("SILENT");
    wait(0.05);
    setmusicstate("WAVE_1");
    iprintlnbold("^3RADIO OFF^7");
    println("NR: EGGS music stop");
}

stop_emitter()
{
    if (isdefined(level.nr_eggs_ent))
    {
        level.nr_eggs_ent stopsounds();
        level.nr_eggs_ent delete();
        level.nr_eggs_ent = undefined;
    }
}
