--[[
    Incapacitated distress lanes: REPEAT voice lines, wider audience lanes.
    Lanes only; registration lives in ..._Repeat.lua.
]]

local Shared = PNC.SocialFlavorDefinitions.Incapacitated
local line = Shared.line

return {

    friendly = {
                line("UI_PNC_IncapRepeat_Friendly_1",
                    "Still down here, {playerFirstName}. Still need a hand."),
                line("UI_PNC_IncapRepeat_Friendly_2",
                    "I haven't moved. Please, if you're still there."),
                line("UI_PNC_IncapRepeat_Friendly_3",
                    "Still can't get up. Please come back."),
                line("UI_PNC_IncapRepeat_Friendly_4",
                    "I'm still here. Still needing help."),
                line("UI_PNC_IncapRepeat_Friendly_5",
                    "Are you still there? I can't get up on my own."),
    },
    friendly_bleedout = {
                line("UI_PNC_IncapRepeat_Friendly_Bleed_1",
                    "Still bleeding. Please, I'm asking again."),
                line("UI_PNC_IncapRepeat_Friendly_Bleed_2",
                    "It's still not stopping. Please help me."),
                line("UI_PNC_IncapRepeat_Friendly_Bleed_3",
                    "I'm still losing blood. Please."),
                line("UI_PNC_IncapRepeat_Friendly_Bleed_4",
                    "Getting worse down here. Please don't leave it."),
    },
    friendly_bandage = {
                line("UI_PNC_IncapRepeat_Friendly_Bandage_1",
                    "Still wounded, still down. A bandage would help."),
                line("UI_PNC_IncapRepeat_Friendly_Bandage_2",
                    "Still waiting to be patched, {playerFirstName}."),
                line("UI_PNC_IncapRepeat_Friendly_Bandage_3",
                    "I can't move until these are wrapped. Please."),
    },
    stranger = {
                line("UI_PNC_IncapRepeat_Stranger_1",
                    "I'm still down. I'm fainting. Please, anyone."),
                line("UI_PNC_IncapRepeat_Stranger_2",
                    "Still on the ground. Still no better. Please help."),
                line("UI_PNC_IncapRepeat_Stranger_3",
                    "I haven't moved. I can't. Please, someone."),
                line("UI_PNC_IncapRepeat_Stranger_4",
                    "Still here. Asking again. Please help me up."),
                line("UI_PNC_IncapRepeat_Stranger_5",
                    "I know I'm a stranger, but I still need help. Please."),
                line("UI_PNC_IncapRepeat_Stranger_6",
                    "Still down, still fading. Please, if anyone's there."),
    },
    stranger_bleedout = {
                line("UI_PNC_IncapRepeat_Stranger_Bleed_1",
                    "Still bleeding. Please. Anyone. Anything."),
                line("UI_PNC_IncapRepeat_Stranger_Bleed_2",
                    "I'm still losing blood. I'm begging you."),
                line("UI_PNC_IncapRepeat_Stranger_Bleed_3",
                    "It's not stopping. Please, I don't have long."),
    },
    stranger_bandage = {
                line("UI_PNC_IncapRepeat_Stranger_Bandage_1",
                    "Still down and still cut up. Please, a bandage."),
                line("UI_PNC_IncapRepeat_Stranger_Bandage_2",
                    "Still waiting. I can't get up by myself."),
    },
    neutral = {
                line("UI_PNC_IncapRepeat_Neutral_1",
                    "Still down. Still fainting. Please."),
                line("UI_PNC_IncapRepeat_Neutral_2",
                    "I'm still here. I still can't move. Please."),
                line("UI_PNC_IncapRepeat_Neutral_3",
                    "Still on the floor. Asking again. Please."),
                line("UI_PNC_IncapRepeat_Neutral_4",
                    "No change. Still need help. Please."),
    },
}
