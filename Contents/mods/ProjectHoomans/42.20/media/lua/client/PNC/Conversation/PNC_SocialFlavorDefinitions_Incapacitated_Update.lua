--[[
    Authored incapacitated-state flavor -- update half of the matrix.

    See PNC_SocialFlavorDefinitions_Incapacitated_Shared.lua for the doc block
    describing the audience/need/threat lanes and the fallback ladder.
]]

local Shared = PNC.SocialFlavorDefinitions.Incapacitated
local Flavor = Shared.Flavor
local cell = Shared.cell
local line = Shared.line

-- ---------------------------------------------------------------------------
-- social.incapacitated_update  -- a status change while still down
-- ---------------------------------------------------------------------------

Flavor.Register("social.incapacitated_update", {
    id = "social.incapacitated_update",
    family = "incapacitated_distress",
    npc = {
        line("UI_PNC_IncapUpdate_Generic_1",
            "Still down here. I'm not going anywhere on my own."),
        line("UI_PNC_IncapUpdate_Generic_2",
            "I'm still on the floor. Don't forget about me."),
    },
    variants = {
        {
            id = "ally_bleedout_zombie",
            when = cell("ally", "bleedout", "zombie"),
            npc = {
                line("UI_PNC_IncapUpdate_Ally_Bleed_Z_1",
                    "Still bleeding out! Please, a bandage, right now!"),
                line("UI_PNC_IncapUpdate_Ally_Bleed_Z_2",
                    "I'm not getting better down here. I need patching, fast!"),
            },
        },
        {
            id = "ally_bleedout",
            when = cell("ally", "bleedout"),
            npc = {
                line("UI_PNC_IncapUpdate_Ally_Bleed_1",
                    "I'm still bleeding. Please hurry with that bandage."),
                line("UI_PNC_IncapUpdate_Ally_Bleed_2",
                    "It's not stopping. I need you to patch this now."),
            },
        },
        {
            id = "ally_bandage",
            when = cell("ally", "bandage"),
            npc = {
                line("UI_PNC_IncapUpdate_Ally_Bandage_1",
                    "I'm still down and still cut up. Whenever you can."),
                line("UI_PNC_IncapUpdate_Ally_Bandage_2",
                    "Not patched yet. I'm waiting on you."),
            },
        },
        {
            id = "ally_rescue",
            when = cell("ally", "rescue"),
            npc = {
                line("UI_PNC_IncapUpdate_Ally_Rescue_1",
                    "Still here. Still need help. Please."),
                line("UI_PNC_IncapUpdate_Ally_Rescue_2",
                    "I'm not up yet. Don't leave without me."),
            },
        },
        {
            id = "ally",
            when = cell("ally"),
            npc = {
                line("UI_PNC_IncapUpdate_Ally_1",
                    "Still down. Help me when you can, {playerFirstName}."),
                line("UI_PNC_IncapUpdate_Ally_2",
                    "I'm waiting on you. I can't walk yet."),
            },
        },
        {
            id = "friendly_bleedout",
            when = cell("friendly", "bleedout"),
            npc = {
                line("UI_PNC_IncapUpdate_Friendly_Bleed_1",
                    "Still bleeding here. Please don't leave me."),
                line("UI_PNC_IncapUpdate_Friendly_Bleed_2",
                    "I'm getting worse. Please help me, {playerFirstName}."),
            },
        },
        {
            id = "friendly",
            when = cell("friendly"),
            npc = {
                line("UI_PNC_IncapUpdate_Friendly_1",
                    "Still down. Are you still there?"),
                line("UI_PNC_IncapUpdate_Friendly_2",
                    "I can't get up yet. Please come back."),
            },
        },
        {
            id = "self",
            when = cell("self"),
            npc = {
                line("UI_PNC_IncapUpdate_Self_1",
                    "Still can't move. I need help."),
                line("UI_PNC_IncapUpdate_Self_2",
                    "Still not up. Still waiting on someone."),
            },
        },
        {
            id = "stranger_bleedout",
            when = cell("stranger", "bleedout"),
            npc = {
                line("UI_PNC_IncapUpdate_Stranger_Bleed_1",
                    "I'm still bleeding. Please, anyone."),
                line("UI_PNC_IncapUpdate_Stranger_Bleed_2",
                    "I'm getting weaker. I'm asking again. Please."),
            },
        },
        {
            id = "stranger_bandage",
            when = cell("stranger", "bandage"),
            npc = {
                line("UI_PNC_IncapUpdate_Stranger_Bandage_1",
                    "Still down here. If anyone has a bandage to spare."),
                line("UI_PNC_IncapUpdate_Stranger_Bandage_2",
                    "Still no bandage, still on the floor. Please."),
            },
        },
        {
            id = "stranger",
            when = cell("stranger"),
            npc = {
                line("UI_PNC_IncapUpdate_Stranger_1",
                    "I'm still down. I'm fainting. Please, help me."),
                line("UI_PNC_IncapUpdate_Stranger_2",
                    "I haven't moved. I can't. Please, someone."),
            },
        },
        {
            id = "neutral",
            when = cell("neutral"),
            npc = {
                line("UI_PNC_IncapUpdate_Neutral_1",
                    "Still down. Still fainting. Please, if you can."),
                line("UI_PNC_IncapUpdate_Neutral_2",
                    "I'm not up. I'm still here. Please help."),
            },
        },
        {
            id = "hostile_mercy_npc",
            when = cell("hostile", "mercy", "npc"),
            npc = {
                line("UI_PNC_IncapUpdate_Mercy_NPC_1",
                    "I'm still on the ground. I'm still asking. Let me live."),
                line("UI_PNC_IncapUpdate_Mercy_NPC_2",
                    "Nothing has changed. I'm still asking you to spare me."),
            },
        },
        {
            id = "hostile_mercy_player",
            when = cell("hostile", "mercy", "player"),
            npc = {
                line("UI_PNC_IncapUpdate_Mercy_Player_1",
                    "I'm still down. I said I'm done. Please."),
                line("UI_PNC_IncapUpdate_Mercy_Player_2",
                    "Still on the ground. Still asking. Please stop."),
            },
        },
        {
            id = "hostile_mercy",
            when = cell("hostile", "mercy"),
            npc = {
                line("UI_PNC_IncapUpdate_Mercy_1",
                    "Still down. Still asking you to let me be."),
                line("UI_PNC_IncapUpdate_Mercy_2",
                    "Still beaten. Still asking. Please."),
            },
        },
        {
            id = "hostile_faint_zombie",
            when = cell("hostile", "faint", "zombie"),
            npc = {
                line("UI_PNC_IncapUpdate_Faint_Hostile_1",
                    "Still on the floor. They're still out there."),
                line("UI_PNC_IncapUpdate_Faint_Hostile_2",
                    "Still down. Still done for. Nothing's changed."),
            },
        },
        {
            id = "faint_zombie",
            when = cell(nil, "faint", "zombie"),
            npc = {
                line("UI_PNC_IncapUpdate_Faint_1",
                    "Still fainting. Still on the ground."),
                line("UI_PNC_IncapUpdate_Faint_2",
                    "Still fading. Still can't get up."),
            },
        },
        {
            id = "hostile",
            when = cell("hostile"),
            npc = {
                line("UI_PNC_IncapUpdate_Hostile_1",
                    "Still down. Still not interested in your help."),
                line("UI_PNC_IncapUpdate_Hostile_2",
                    "Still here. Still don't want anything from you."),
            },
        },
        {
            id = "bleedout",
            when = cell(nil, "bleedout"),
            npc = {
                line("UI_PNC_IncapUpdate_Bleed_1",
                    "Still bleeding. Someone, please."),
                line("UI_PNC_IncapUpdate_Bleed_2",
                    "It hasn't stopped. Please, I need help."),
            },
        },
        {
            id = "bandage",
            when = cell(nil, "bandage"),
            npc = {
                line("UI_PNC_IncapUpdate_Bandage_1",
                    "Still need patching. Still can't stand."),
                line("UI_PNC_IncapUpdate_Bandage_2",
                    "Still waiting to be wrapped up."),
            },
        },
        {
            id = "help",
            when = cell(nil, "help"),
            npc = {
                line("UI_PNC_IncapUpdate_Help_1",
                    "Still down. Still need help."),
                line("UI_PNC_IncapUpdate_Help_2",
                    "Still can't get up. Still need a hand."),
            },
        },
    },
})

return PNC.SocialFlavorDefinitions
