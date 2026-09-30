--[[
    Incapacitated distress lanes: REPEAT registration.

    Wires the authored repeat lines into the flavor registry under a distinct
    id with the same family and merge key as the call line, so this replaces
    the initial plea in place instead of stacking on top of it.
]]

local Shared = PNC.SocialFlavorDefinitions.Incapacitated
local Flavor = Shared.Flavor
local cell = Shared.cell
local line = Shared.line
local Lines = require "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Repeat_Lines"

Flavor.Register("social.incapacitated_repeat", {
    id = "social.incapacitated_repeat",
    family = "incapacitated_distress",
    npc = {
        line("UI_PNC_IncapRepeat_Generic_1",
            "Still down here. I still need help."),
        line("UI_PNC_IncapRepeat_Generic_2",
            "I'm not up yet. Please."),
    },
    variants = {
        { id = "ally_bleedout", when = cell("ally", "bleedout"), npc = Lines.ally_bleedout },
        { id = "ally_bandage", when = cell("ally", "bandage"), npc = Lines.ally_bandage },
        { id = "ally_faint", when = cell("ally", "faint"), npc = Lines.ally_faint },
        { id = "ally", when = cell("ally"), npc = Lines.ally },
        { id = "self", when = cell("self"), npc = Lines.self },
        { id = "friendly_bleedout", when = cell("friendly", "bleedout"), npc = Lines.friendly_bleedout },
        { id = "friendly_bandage", when = cell("friendly", "bandage"), npc = Lines.friendly_bandage },
        { id = "friendly", when = cell("friendly"), npc = Lines.friendly },
        { id = "stranger_bleedout", when = cell("stranger", "bleedout"), npc = Lines.stranger_bleedout },
        { id = "stranger_bandage", when = cell("stranger", "bandage"), npc = Lines.stranger_bandage },
        { id = "stranger", when = cell("stranger"), npc = Lines.stranger },
        { id = "neutral", when = cell("neutral"), npc = Lines.neutral },
        { id = "hostile_mercy_npc", when = cell("hostile", "mercy", "npc"), npc = Lines.mercy_npc },
        { id = "hostile_mercy", when = cell("hostile", "mercy"), npc = Lines.mercy },
        { id = "hostile_faint", when = cell("hostile", "faint"), npc = Lines.faint },
        { id = "hostile", when = cell("hostile"), npc = Lines.dissent },
        { id = "bleedout", when = cell(nil, "bleedout"), npc = Lines.bare_bleedout },
        { id = "bandage", when = cell(nil, "bandage"), npc = Lines.bare_bandage },
        { id = "faint", when = cell(nil, "faint"), npc = Lines.bare_faint },
        { id = "mercy", when = cell(nil, "mercy"), npc = Lines.bare_mercy },
        { id = "help", when = cell(nil, "help"), npc = Lines.bare_help },
        { id = "rescue", when = cell(nil, "rescue"), npc = Lines.bare_rescue },
    },
})

return PNC.SocialFlavorDefinitions
