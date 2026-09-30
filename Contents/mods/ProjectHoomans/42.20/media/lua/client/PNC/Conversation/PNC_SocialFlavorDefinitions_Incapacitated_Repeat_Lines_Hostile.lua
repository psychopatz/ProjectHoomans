--[[
    Incapacitated distress lanes: REPEAT voice lines, hostile lanes.
    Lanes only; registration lives in ..._Repeat.lua.
]]

local Shared = PNC.SocialFlavorDefinitions.Incapacitated
local line = Shared.line

return {

    mercy_npc = {
                line("UI_PNC_IncapRepeat_Mercy_NPC_1",
                    "Still down, {attackerName}. I'm still asking. Please."),
                line("UI_PNC_IncapRepeat_Mercy_NPC_2",
                    "You've already won. I'm still asking you to let me live."),
                line("UI_PNC_IncapRepeat_Mercy_NPC_3",
                    "Still on the ground. Still begging, {attackerName}."),
    },
    mercy = {
                line("UI_PNC_IncapRepeat_Mercy_1",
                    "I'm still down. I'm still asking you to stop. Please."),
                line("UI_PNC_IncapRepeat_Mercy_2",
                    "Still beaten. Still on the ground. Please let me live."),
                line("UI_PNC_IncapRepeat_Mercy_3",
                    "I said I'm done. I meant it. Please."),
                line("UI_PNC_IncapRepeat_Mercy_4",
                    "Still here. Still asking. Please, don't finish me."),
                line("UI_PNC_IncapRepeat_Mercy_5",
                    "Nothing's changed. I'm still asking for my life."),
    },
    faint = {
                line("UI_PNC_IncapRepeat_Faint_1",
                    "Still on the ground. Still fading. Still nothing I can do."),
                line("UI_PNC_IncapRepeat_Faint_2",
                    "Can't get up. Can't fight. Can't do anything."),
                line("UI_PNC_IncapRepeat_Faint_3",
                    "Still down here. Still done for."),
    },
    dissent = {
                line("UI_PNC_IncapRepeat_Hostile_1",
                    "Still down. Still want you gone. Both things are true."),
                line("UI_PNC_IncapRepeat_Hostile_2",
                    "I haven't moved. I also haven't changed my mind. Leave."),
                line("UI_PNC_IncapRepeat_Hostile_3",
                    "Still here. Still don't want your help."),
    },
}
