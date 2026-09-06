#include maps\_utility;

precache_assets()
{
    precacheshader("white");
    precacheshader("specialty_juggernaut_zombies");
    precacheshader("specialty_fastreload_zombies");
    precacheshader("specialty_doubletap_zombies");
    precacheshader("specialty_quickrevive_zombies");
    precacheshader("nr_stones_and_cheese");
}

text_element(x, y, scale, color, horizontal, vertical)
{
    h = newclienthudelem(self);
    h.horzalign = horizontal;
    h.vertalign = vertical;
    h.alignx = "left";
    h.aligny = "top";
    h.x = x;
    h.y = y;
    h.fontscale = scale;
    h.color = color;
    h.alpha = 1;
    h.archived = false;
    h.hidewheninmenu = true;
    return h;
}

init()
{
    self.nr_title = self text_element(18,18,1.3,(1,0.78,0.35),"left","top");
    self.nr_title settext("N A C H T  /  R E A W A K E N E D");
    self.nr_objective = self text_element(18,36,1,(0.85,0.89,0.91),"left","top");
    self.nr_status = self text_element(18,52,1,(0.65,0.72,0.76),"left","top");
    self.nr_health = self text_element(18,-85,1,(0.9,0.92,0.94),"left","bottom");
    self.nr_perktext = self text_element(18,-105,1,(1,0.78,0.35),"left","bottom");
    self.nr_prompt = self text_element(0,85,1.25,(1,0.86,0.5),"center","middle");
    self.nr_prompt.alignx = "center";
    self.nr_prompt settext("");
    self.nr_poster = newclienthudelem(self);
    self.nr_poster.horzalign = "right";
    self.nr_poster.vertalign = "middle";
    self.nr_poster.alignx = "right";
    self.nr_poster.aligny = "middle";
    self.nr_poster.x = -24;
    self.nr_poster.y = -10;
    self.nr_poster.alpha = 0;
    self.nr_poster.archived = false;
    self.nr_poster.hidewheninmenu = true;
    self.nr_poster setshader("nr_stones_and_cheese", 140, 140);
    self.nr_icons = [];
    shaders = [];
    shaders[0] = "specialty_quickrevive_zombies";
    shaders[1] = "specialty_juggernaut_zombies";
    shaders[2] = "specialty_fastreload_zombies";
    shaders[3] = "specialty_doubletap_zombies";
    for (i = 0; i < 4; i++)
    {
        h = self text_element(18 + i*27,-135,1,(1,1,1),"left","bottom");
        h setshader(shaders[i],22,22);
        h.alpha = 0.15;
        self.nr_icons[i] = h;
    }
}

update()
{
    if (level.intermission)
    {
        self.nr_title.alpha = 0;
        self.nr_objective.alpha = 0;
        self.nr_status.alpha = 0;
        self.nr_health.alpha = 0;
        self.nr_perktext.alpha = 0;
        self.nr_prompt.alpha = 0;
        self.nr_poster.alpha = 0;
        for (i = 0; i < self.nr_icons.size; i++) self.nr_icons[i].alpha = 0;
        return;
    }
    if (!level.nr_power)
        self.nr_objective settext("OBJECTIVE / Restore power upstairs");
    else if (level.nr_relays < 2)
        self.nr_objective settext("OBJECTIVE / Link downstairs relays " + level.nr_relays + "/2");
    else
        self.nr_objective settext("PACK-A-PUNCH ONLINE / Next to power upstairs");
    status = "ROUND " + level.round_number;
    if (getdvarint("nr_zombie_counter"))
        status += "  /  " + getaiarray("axis").size + " ACTIVE";
    self.nr_status settext(status);
    self.nr_health settext("HEALTH " + self.health + " / " + self.maxhealth);
    names = [];
    names[0] = "revive";
    names[1] = "jug";
    names[2] = "speed";
    names[3] = "tap";
    for (i = 0; i < 4; i++)
    {
        self.nr_icons[i].alpha = 0.15;
        if (isdefined(self.nr_perks[names[i]]) && self.nr_perks[names[i]])
            self.nr_icons[i].alpha = 1;
    }
    text = "";
    if (isdefined(self.nr_perks["stamina"]) && self.nr_perks["stamina"])
        text = "STAMIN-UP  ";
    if (get_players().size == 1)
    {
        if (isdefined(self.nr_perks["revive"]) && self.nr_perks["revive"])
            text += "SELF-REVIVES " + (3-self.nr_revives);
        else if (self.nr_revives >= 3)
            text += "SELF-REVIVES EXHAUSTED";
        else
            text += "QUICK REVIVE / NOT OWNED";
    }
    self.nr_perktext settext(text);
}

set_poster(show)
{
    if (!isdefined(self.nr_poster))
        return;
    if (show)
        self.nr_poster.alpha = 0.92;
    else
        self.nr_poster.alpha = 0;
}
