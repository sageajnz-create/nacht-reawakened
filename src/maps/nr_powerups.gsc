#include maps\_utility;

bonus()
{
    players = get_players();
    for (i = 0; i < players.size; i++)
    {
        if (isalive(players[i]) && players[i].sessionstate == "playing")
            players[i] maps\_zombiemode_score::add_to_player_score(500);
    }
    iprintlnbold("^3BONUS POINTS^7 | +500");
    println("NR: BONUS POINTS");
}
