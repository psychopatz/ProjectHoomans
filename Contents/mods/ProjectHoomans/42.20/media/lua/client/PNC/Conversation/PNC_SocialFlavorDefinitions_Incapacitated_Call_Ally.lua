--[[
    Incapacitated distress lane: ALLY.

    A faction member, follower or companion.  Confident, direct, and specific
    about the wound so the owner knows what to bring.

    See PNC_SocialFlavorDefinitions_Incapacitated_Shared.lua for the matrix
    documentation and the fallback ladder.
]]

local Shared = PNC.SocialFlavorDefinitions.Incapacitated
local Flavor = Shared.Flavor
local cell = Shared.cell
local line = Shared.line

return {
        -- ALLY: a faction member, follower or companion.  Confident, direct,
        -- and specific about the wound so the owner knows what to bring.
        -- ------------------------------------------------------------------
        {
            id = "ally_bleedout_zombie",
            when = cell("ally", "bleedout", "zombie"),
            npc = {
                line("UI_PNC_IncapCall_Ally_Bleed_Z_1",
                    "They got me bleeding bad! {playerFirstName}, I need a bandage right now!"),
                line("UI_PNC_IncapCall_Ally_Bleed_Z_2",
                    "I'm bleeding out from the dead! Patch me up, {playerFirstName}, quick!"),
                line("UI_PNC_IncapCall_Ally_Bleed_Z_3",
                    "Zombies opened me up and I can't stop the bleeding. Bandage, please!"),
            },
        },
        {
            id = "ally_bleedout",
            when = cell("ally", "bleedout"),
            npc = {
                line("UI_PNC_IncapCall_Ally_Bleed_1",
                    "I'm down and bleeding out! Someone get me a bandage!"),
                line("UI_PNC_IncapCall_Ally_Bleed_2",
                    "I can't stop the bleeding on my own. Help me, {playerFirstName}!"),
                line("UI_PNC_IncapCall_Ally_Bleed_3",
                    "Losing blood fast here. I need to be patched up!"),
            },
        },
        {
            id = "ally_bandage_zombie",
            when = cell("ally", "bandage", "zombie"),
            npc = {
                line("UI_PNC_IncapCall_Ally_Bandage_Z_1",
                    "I'm down and torn up. {playerFirstName}, I need patching before they come back."),
                line("UI_PNC_IncapCall_Ally_Bandage_Z_2",
                    "Can't stand up, can't fight like this. Somebody bandage these wounds!"),
                line("UI_PNC_IncapCall_Ally_Bandage_Z_3",
                    "I'm hurt and on the floor. {playerFirstName}, get me wrapped up!"),
            },
        },
        {
            id = "ally_bandage",
            when = cell("ally", "bandage"),
            npc = {
                line("UI_PNC_IncapCall_Ally_Bandage_1",
                    "I need patching, {playerFirstName}. I can't move on my own."),
                line("UI_PNC_IncapCall_Ally_Bandage_2",
                    "I'm clipped and down. Somebody bring a bandage for me."),
                line("UI_PNC_IncapCall_Ally_Bandage_3",
                    "Get me bandaged and I can get moving again. {playerFirstName}?"),
            },
        },
        {
            id = "ally_rescue",
            when = cell("ally", "rescue"),
            npc = {
                line("UI_PNC_IncapCall_Ally_Rescue_1",
                    "I'm going down. {playerFirstName}, don't let me die here!"),
                line("UI_PNC_IncapCall_Ally_Rescue_2",
                    "I need help! Get me out of this, {playerFirstName}!"),
                line("UI_PNC_IncapCall_Ally_Rescue_3",
                    "I can't do anything from down here. Talk to me, help me!"),
            },
        },
        {
            id = "ally",
            when = cell("ally"),
            npc = {
                line("UI_PNC_IncapCall_Ally_1",
                    "I'm down! {playerFirstName}, help me up!"),
                line("UI_PNC_IncapCall_Ally_2",
                    "I can't walk, {playerFirstName}. Stay with me, help me."),
                line("UI_PNC_IncapCall_Ally_3",
                    "Down but not out. Get me back on my feet."),
            },
        },
        -- ------------------------------------------------------------------
}
