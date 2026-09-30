--[[
    Incapacitated distress lanes: FRIENDLY, SELF, STRANGER, NEUTRAL and the
    bare generic fallbacks.

    These listeners are owed less than group members, so the request is softer
    and becomes an appeal for help the downed NPC is not entitled to.

    See PNC_SocialFlavorDefinitions_Incapacitated_Shared.lua for the matrix
    documentation and the fallback ladder.
]]

local Shared = PNC.SocialFlavorDefinitions.Incapacitated
local Flavor = Shared.Flavor
local cell = Shared.cell
local line = Shared.line

return {
        -- FRIENDLY / SELF: a warm relationship that is not part of the group.
        -- ------------------------------------------------------------------
        {
            id = "friendly_bleedout_zombie",
            when = cell("friendly", "bleedout", "zombie"),
            npc = {
                line("UI_PNC_IncapCall_Friendly_Bleed_Z_1",
                    "The dead opened me up and I'm bleeding out! Please, {playerFirstName}!"),
                line("UI_PNC_IncapCall_Friendly_Bleed_Z_2",
                    "I'm bleeding, I'm down, I'm in trouble. Help me, {playerFirstName}."),
            },
        },
        {
            id = "friendly_bleedout",
            when = cell("friendly", "bleedout"),
            npc = {
                line("UI_PNC_IncapCall_Friendly_Bleed_1",
                    "I'm bleeding out. Please help me, {playerFirstName}."),
                line("UI_PNC_IncapCall_Friendly_Bleed_2",
                    "I can't stop this bleeding alone. Do you have anything?"),
            },
        },
        {
            id = "friendly_bandage",
            when = cell("friendly", "bandage"),
            npc = {
                line("UI_PNC_IncapCall_Friendly_Bandage_1",
                    "I'm down and cut up, {playerFirstName}. Do you have a bandage?"),
                line("UI_PNC_IncapCall_Friendly_Bandage_2",
                    "I can't get up. Could you patch me, {playerFirstName}?"),
            },
        },
        {
            id = "friendly",
            when = cell("friendly"),
            npc = {
                line("UI_PNC_IncapCall_Friendly_1",
                    "I'm down, {playerFirstName}. Please, I need help."),
                line("UI_PNC_IncapCall_Friendly_2",
                    "I can't get up. Are you going to help me?"),
                line("UI_PNC_IncapCall_Friendly_3",
                    "I'm in a bad way here. Please don't just watch."),
            },
        },
        {
            id = "self",
            when = cell("self"),
            npc = {
                line("UI_PNC_IncapCall_Self_1",
                    "I'm down and I can't get up. I need help."),
                line("UI_PNC_IncapCall_Self_2",
                    "I can't move. Somebody, help me."),
                line("UI_PNC_IncapCall_Self_3",
                    "I'm hurt bad. I need a hand."),
            },
        },
        -- ------------------------------------------------------------------
        -- STRANGER: a different, non-belligerent faction.  No name, no claim
        -- on the listener -- they ask for help they are not owed.
        -- ------------------------------------------------------------------
        {
            id = "stranger_bleedout_zombie",
            when = cell("stranger", "bleedout", "zombie"),
            npc = {
                line("UI_PNC_IncapCall_Stranger_Bleed_Z_1",
                    "I'm bleeding out here! Please, does anyone have a bandage?"),
                line("UI_PNC_IncapCall_Stranger_Bleed_Z_2",
                    "I'm hit and losing blood. Help me, please. I'm not your enemy."),
            },
        },
        {
            id = "stranger_bleedout",
            when = cell("stranger", "bleedout"),
            npc = {
                line("UI_PNC_IncapCall_Stranger_Bleed_1",
                    "I'm bleeding. I know we don't know each other, but please help."),
                line("UI_PNC_IncapCall_Stranger_Bleed_2",
                    "Anyone, please. I'm bleeding out and I can't stop it."),
            },
        },
        {
            id = "stranger_bandage",
            when = cell("stranger", "bandage"),
            npc = {
                line("UI_PNC_IncapCall_Stranger_Bandage_1",
                    "I've fallen and I can't get up. Could you spare a bandage?"),
                line("UI_PNC_IncapCall_Stranger_Bandage_2",
                    "I'm hurt. I'm not asking for much. Just help me wrap this."),
            },
        },
        {
            id = "stranger",
            when = cell("stranger"),
            npc = {
                line("UI_PNC_IncapCall_Stranger_1",
                    "I'm fainting. Please, someone, help me up."),
                line("UI_PNC_IncapCall_Stranger_2",
                    "I've gone down. I'm in no shape to fight. Please help."),
                line("UI_PNC_IncapCall_Stranger_3",
                    "You don't know me, but I need a hand here. Please."),
            },
        },
        -- ------------------------------------------------------------------
        -- NEUTRAL: no recognized standing at all.  The most reserved lane.
        -- ------------------------------------------------------------------
        {
            id = "neutral_bleedout",
            when = cell("neutral", "bleedout"),
            npc = {
                line("UI_PNC_IncapCall_Neutral_Bleed_1",
                    "I'm bleeding. Somebody, help me. I can't do this alone."),
                line("UI_PNC_IncapCall_Neutral_Bleed_2",
                    "I'm losing blood. Is anyone there? Anybody."),
            },
        },
        {
            id = "neutral_bandage",
            when = cell("neutral", "bandage"),
            npc = {
                line("UI_PNC_IncapCall_Neutral_Bandage_1",
                    "I can't get up. I need to be patched. Please."),
                line("UI_PNC_IncapCall_Neutral_Bandage_2",
                    "Down and wounded. Someone have a bandage to spare?"),
            },
        },
        {
            id = "neutral",
            when = cell("neutral"),
            npc = {
                line("UI_PNC_IncapCall_Neutral_1",
                    "I'm going down. I'm fainting. Please help me."),
                line("UI_PNC_IncapCall_Neutral_2",
                    "I can't stand. I need someone. Please."),
                line("UI_PNC_IncapCall_Neutral_3",
                    "I'm in a bad way. Help me, if you would."),
            },
        },
}
