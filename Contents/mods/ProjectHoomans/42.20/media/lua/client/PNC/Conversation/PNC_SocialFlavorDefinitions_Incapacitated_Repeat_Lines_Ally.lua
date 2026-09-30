--[[
    Incapacitated distress lanes: REPEAT voice lines, ally and self lanes.
    Lanes only; registration lives in ..._Repeat.lua.
]]

local Shared = PNC.SocialFlavorDefinitions.Incapacitated
local line = Shared.line

return {

    ally = {
                line("UI_PNC_IncapRepeat_Ally_1",
                    "Still down, {playerFirstName}. I'm not going anywhere on my own."),
                line("UI_PNC_IncapRepeat_Ally_2",
                    "I'm still on the floor. Please don't forget about me."),
                line("UI_PNC_IncapRepeat_Ally_3",
                    "Any time now, {playerFirstName}. I can't walk."),
                line("UI_PNC_IncapRepeat_Ally_4",
                    "Not up yet. I need you to come back for me."),
                line("UI_PNC_IncapRepeat_Ally_5",
                    "I'm waiting. Please, whenever you can."),
                line("UI_PNC_IncapRepeat_Ally_6",
                    "Still here. Still can't move. Still need help."),
                line("UI_PNC_IncapRepeat_Ally_7",
                    "{playerFirstName}? I'm still down. Don't leave me."),
                line("UI_PNC_IncapRepeat_Ally_8",
                    "Can't get up. Not yet. Come back for me."),
    },
    ally_bleedout = {
                line("UI_PNC_IncapRepeat_Ally_Bleed_1",
                    "Still bleeding here! I need that bandage!"),
                line("UI_PNC_IncapRepeat_Ally_Bleed_2",
                    "It hasn't stopped. Please, I'm losing too much."),
                line("UI_PNC_IncapRepeat_Ally_Bleed_3",
                    "Bleeding out and waiting. Please hurry."),
                line("UI_PNC_IncapRepeat_Ally_Bleed_4",
                    "I'm getting weaker. I need patching now."),
                line("UI_PNC_IncapRepeat_Ally_Bleed_5",
                    "Still not wrapped up. Please, {playerFirstName}."),
                line("UI_PNC_IncapRepeat_Ally_Bleed_6",
                    "The blood isn't stopping. Help me."),
    },
    ally_bandage = {
                line("UI_PNC_IncapRepeat_Ally_Bandage_1",
                    "Still cut up and still down. Bandage when you can."),
                line("UI_PNC_IncapRepeat_Ally_Bandage_2",
                    "Not patched yet. I'm stuck here until you do."),
                line("UI_PNC_IncapRepeat_Ally_Bandage_3",
                    "I need wrapping before I can move. Please."),
                line("UI_PNC_IncapRepeat_Ally_Bandage_4",
                    "Still waiting on those bandages, {playerFirstName}."),
                line("UI_PNC_IncapRepeat_Ally_Bandage_5",
                    "Wounds are still open. Can you patch me?"),
    },
    ally_faint = {
                line("UI_PNC_IncapRepeat_Faint_Ally_1",
                    "Still can't get up. They're still close."),
                line("UI_PNC_IncapRepeat_Faint_Ally_2",
                    "I'm not moving. Not yet. I can't."),
                line("UI_PNC_IncapRepeat_Faint_Ally_3",
                    "Lying here hoping nothing finds me."),
    },
    self = {
                line("UI_PNC_IncapRepeat_Self_1",
                    "Still down. Still can't move. I need help."),
                line("UI_PNC_IncapRepeat_Self_2",
                    "I'm not getting up on my own. Please."),
                line("UI_PNC_IncapRepeat_Self_3",
                    "Still stuck here. Someone, please."),
    },
}
