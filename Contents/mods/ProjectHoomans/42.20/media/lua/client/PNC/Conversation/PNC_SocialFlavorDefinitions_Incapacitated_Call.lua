--[[
    Incapacitated distress lanes: registration.

    Loads each lane contribution and registers them as one ordered variant
    list, most specific first.  See
    PNC_SocialFlavorDefinitions_Incapacitated_Shared.lua for the matrix
    documentation and the fallback ladder.
]]

local Shared = PNC.SocialFlavorDefinitions.Incapacitated
local Flavor = Shared.Flavor
local line = Shared.line
local Ally = require "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Call_Ally"
local Other = require "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Call_Other"
local Hostile = require "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Call_Hostile"

-- Assembly order is the selection order for equally specific matches:
-- ally lanes first, then the wider audience lanes, then the attacker-directed
-- hostile lanes.
local function assemble()
    local variants = {}
    local i
    local j
    local group
    local groups = { Ally, Other, Hostile }
    for i = 1, #groups do
        group = groups[i]
        for j = 1, #(group or {}) do
            variants[#variants + 1] = group[j]
        end
    end
    return variants
end

-- ---------------------------------------------------------------------------
-- social.incapacitated_call  -- the moment the NPC goes down
-- ---------------------------------------------------------------------------

Flavor.Register("social.incapacitated_call", {
    id = "social.incapacitated_call",
    family = "incapacitated_distress",
    npc = {
        line("UI_PNC_IncapCall_Generic_1",
            "I'm down! {playerFirstName}, I need a hand over here!"),
        line("UI_PNC_IncapCall_Generic_2",
            "I can't get up. Help me, {playerFirstName}."),
        line("UI_PNC_IncapCall_Generic_3",
            "I'm hit bad. Don't leave me like this."),
    },
    variants = assemble(),
})

return PNC.SocialFlavorDefinitions
