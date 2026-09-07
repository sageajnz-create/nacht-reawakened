#include clientscripts\_utility; 
#include clientscripts\_ambientpackage;
#include clientscripts\_music;

main()
{
            declareAmbientPackage( "zombies" );
                addAmbientElement( "zombies", "amb_spooky_2d", 5, 8, 300, 2000 );

 		declareAmbientRoom( "zombies" );
 			setAmbientRoomReverb ("zombies","stoneroom", 1, 1);

  activateAmbientPackage( 0, "zombies", 0 );
  activateAmbientRoom( 0, "zombies", 0 );

  declareMusicState("SPLASH_SCREEN");
	musicAlias("mx_splash_screen", 12);	
	musicwaittilldone();

  declareMusicState("WAVE_1"); 
	musicAliasloop("mx_zombie_wave_1", 0, 4);	

  // Stones & Cheese EE: WaW only reliably stream-overrides stock mx_game_over for musicAlias. Stones ships on that stream; end_of_game uses round_over instead. SILENT still stops the oneshot.
  declareMusicState("eggs");
	musicAlias("mx_game_over", 1);

  declareMusicState("SILENT");

	thread radio_init();
}

add_song(song)
{
	if(!isdefined(level.radio_songs))
 		level.radio_songs = [];
	level.radio_songs[level.radio_songs.size] = song;
}

fade(id, time)
{
	rate = 0;
	if(time != 0)
		rate = 1.0 / time;
	setSoundVolumeRate(id, rate);
	setSoundVolume(id, 0.0);
	while(SoundPlaying(id) && getSoundVolume(id) > .0001)
		wait(.1);
	stopSound(id);
}

radio_advance()
{
	for(;;)
	{
		while(SoundPlaying(level.radio_id) || level.radio_index == 0)
			wait(1);
		level notify("kzmb_next_song");
		wait(1);
	}
}

radio_thread()
{
	assert(isdefined(level.radio_id));
	assert(isdefined(level.radio_songs));
	assert(isdefined(level.radio_index));
	assert(level.radio_songs.size > 0);
	for(;;)
	{
		level waittill("kzmb_next_song");
		playsound(0, "static", self.origin);
		if(SoundPlaying(level.radio_id))
			fade(level.radio_id, 1);
		else
			wait(.5);
		level.radio_id = playsound(0, level.radio_songs[level.radio_index], self.origin);
		level.radio_index += 1;
		if(level.radio_index >= level.radio_songs.size)
			level.radio_index = 0;
		wait(1);
	}
}

radio_init()
{
	level.radio_id = -1;
	level.radio_index = 0;
	add_song( "wtf" );
	add_song( "dog_fire" );
	add_song( "true_crime_4" );
	add_song( "all_mixed_up" );
	add_song( "dusk" );	
	add_song( "the_march" );
	add_song( "drum_no_bass" );
	add_song( "russian_theme" );
	add_song( "sand" );
	add_song( "stag_push" );
	add_song( "pby_old" );
	add_song( "wild_card" );
	add_song( "" );
	radios = getentarray(0, "kzmb","targetname");
	while (!isdefined(radios) || !radios.size)
	{
		wait(5);
		radios = getentarray(0, "kzmb","targetname");
	}
	array_thread(radios, ::radio_thread );
	array_thread(radios, ::radio_advance );
}