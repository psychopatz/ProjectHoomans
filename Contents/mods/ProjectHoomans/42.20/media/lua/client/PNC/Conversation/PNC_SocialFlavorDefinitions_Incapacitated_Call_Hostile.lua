--[[
    Incapacitated distress lanes: hostile standing.

    A hostile downed by a survivor pleads for mercy; a hostile downed by the
    dead simply goes out.  This is the only lane that addresses the attacker.

    See PNC_SocialFlavorDefinitions_Incapacitated_Shared.lua for the matrix
    documentation and the fallback ladder.
]]

local Shared = PNC.SocialFlavorDefinitions.Incapacitated
local Flavor = Shared.Flavor
local cell = Shared.cell
local line = Shared.line

return {
        -- HOSTILE + HUMAN ATTACKER: pleading for mercy from whoever put them
        -- down.  This is the only lane that addresses the attacker directly.
        -- ------------------------------------------------------------------
        {
            id = "hostile_mercy_npc",
            when = cell("hostile", "mercy", "npc"),
            npc = {
                line("UI_PNC_IncapCall_Mercy_NPC_1",
                    "Enough! You've beaten me. Let me live, {attackerName}. Please."),
                line("UI_PNC_IncapCall_Mercy_NPC_2",
                    "I'm finished, I know it. I'm asking you. Please don't."),
                line("UI_PNC_IncapCall_Mercy_NPC_3",
                    "Mercy, {attackerName}. I can't fight you anymore. Let me go."),
            },
        },
        {
            id = "hostile_mercy_player",
            when = cell("hostile", "mercy", "player"),
            npc = {
                line("UI_PNC_IncapCall_Mercy_Player_1",
                    "Alright! I'm down. You've won. Please, don't finish me."),
                line("UI_PNC_IncapCall_Mercy_Player_2",
                    "I can't get up. I'm asking you to stop. Please, {playerFirstName}."),
                line("UI_PNC_IncapCall_Mercy_Player_3",
                    "Spare me. I'm done fighting. Please."),
            },
        },
        {
            id = "hostile_mercy",
            when = cell("hostile", "mercy"),
            npc = {
                line("UI_PNC_IncapCall_Mercy_1",
                    "I give up. Please, let me live."),
                line("UI_PNC_IncapCall_Mercy_2",
                    "I'm down. Enough. Please don't."),
                line("UI_PNC_IncapCall_Mercy_3",
                    "Mercy. I'm beaten. I'm asking you."),
            },
        },
        -- ------------------------------------------------------------------
        -- HOSTILE or HUMANE-THREATENED: dying in front of the dead, with no
        -- survivor to plead to.
        -- ------------------------------------------------------------------
        {
            id = "hostile_faint_zombie",
            when = cell("hostile", "faint", "zombie"),
            npc = {
                line("UI_PNC_IncapCall_Faint_Hostile_1",
                    "No... not like this. Not to them."),
                line("UI_PNC_IncapCall_Faint_Hostile_2",
                    "I'm done. I'm fainting. Damn it."),
                line("UI_PNC_IncapCall_Faint_Hostile_3",
                    "Can't get up. Can't do anything. This is it."),
            },
        },
        {
            id = "faint_zombie",
            when = cell(nil, "faint", "zombie"),
            npc = {
                line("UI_PNC_IncapCall_Faint_1",
                    "I can't get up. I'm fainting. This is bad."),
                line("UI_PNC_IncapCall_Faint_2",
                    "Everything's going dark. I'm not getting up from this."),
                line("UI_PNC_IncapCall_Faint_3",
                    "I'm slipping. I'm fainting. I'm sorry."),
            },
        },
        {
            id = "hostile",
            when = cell("hostile"),
            npc = {
                line("UI_PNC_IncapCall_Hostile_1",
                    "Do not touch me. Just get away from me."),
                line("UI_PNC_IncapCall_Hostile_2",
                    "I'm down. Leave me alone, all of you."),
                line("UI_PNC_IncapCall_Hostile_3",
                    "I don't want your help. Go."),
            },
        },
        -- Bleedout and bandage lanes with no audience or threat information.
        -- The need still has to be expressed; only the tone falls back.
        {
            id = "bleedout",
            when = cell(nil, "bleedout"),
            npc = {
                line("UI_PNC_IncapCall_Bleed_1",
                    "I'm bleeding out! Someone, a bandage, anything!"),
                line("UI_PNC_IncapCall_Bleed_2",
                    "I can't stop the bleeding on my own. Please, help."),
                line("UI_PNC_IncapCall_Bleed_3",
                    "Losing too much blood. Help me, please."),
            },
        },
        {
            id = "bandage",
            when = cell(nil, "bandage"),
            npc = {
                line("UI_PNC_IncapCall_Bandage_1",
                    "I need patching up. I can't stand. Please."),
                line("UI_PNC_IncapCall_Bandage_2",
                    "Wounded and down. Somebody, bandage me."),
                line("UI_PNC_IncapCall_Bandage_3",
                    "I need to be wrapped up before I can move. Please help."),
            },
        },
        {
            id = "rescue",
            when = cell(nil, "rescue"),
            npc = {
                line("UI_PNC_IncapCall_Rescue_1",
                    "I'm down and I can't move. I need help!"),
                line("UI_PNC_IncapCall_Rescue_2",
                    "Somebody get to me, please!"),
            },
        },
        {
            id = "help",
            when = cell(nil, "help"),
            npc = {
                line("UI_PNC_IncapCall_Help_1",
                    "I'm down. I need help."),
                line("UI_PNC_IncapCall_Help_2",
                    "Can't get up. Someone help me, please."),
            },
        },
}
