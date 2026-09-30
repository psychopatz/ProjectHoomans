--[[
    Incapacitated distress lanes: REPEAT voice lines -- aggregate.

    Kept as one import surface for the registration file while the authored
    text lives in per-group files that stay small enough to review.
]]

local Ally = require "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Repeat_Lines_Ally"
local Wider = require "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Repeat_Lines_Wider"
local Hostile = require "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Repeat_Lines_Hostile"

local function merge()
    local out = {}
    local i
    local j
    local groups = { Ally, Wider, Hostile }
    for i = 1, #groups do
        for j, value in pairs(groups[i] or {}) do
            out[j] = value
        end
    end
    return out
end

return merge()
