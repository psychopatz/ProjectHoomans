--[[
    Authored leadership-loss flavor.

    Fired when a player who led a faction dies in front of their own people.
    The surviving NPCs speak as mourners, not as observers: the tone comes from
    each NPC's own relationship to the dead leader (leaderGrief) and the content
    acknowledges the outcome (leaderSuccession), because the group really
    carries on either way: a surviving player inherits it, or it converts to
    refugees under an NPC leader as a mobile group.

    Context keys (from PNC.FlavorText.BuildLeaderDeathContext):
        leaderGrief       devoted, close, colonist, distant, dissent
        leaderSuccession  promoted, player, none
        leaderDied        true

    Address tokens: {playerFirstName} listener, {leaderName} the dead leader,
    {successorName} whoever took over.  The base `npc` list is always non-empty,
    so no combination can render nothing even if a variant is missing.

    Lane text lives in the _Close and _Wider files; this file registers them.
]]

PNC = PNC or {}
PNC.SocialFlavorDefinitions = PNC.SocialFlavorDefinitions or {}

local Flavor = PsychopatzCore and PsychopatzCore.SocialFlavor
if not Flavor then return PNC.SocialFlavorDefinitions end

local Close = require "PNC/Conversation/PNC_SocialFlavorDefinitions_LeaderDeath_Close"
local Wider = require "PNC/Conversation/PNC_SocialFlavorDefinitions_LeaderDeath_Wider"

-- Order matters only for equally specific matches, which cannot happen here
-- because every lane keys on distinct grief/succession values.
local function assemble()
    local out = {}
    local i
    local j
    local groups = { Close, Wider }
    for i = 1, #groups do
        for j = 1, #(groups[i] or {}) do
            out[#out + 1] = groups[i][j]
        end
    end
    return out
end

local function line(key, fallback)
    return { key = key, fallback = fallback }
end

Flavor.Register("social.witnessed_leader_death", {
    id = "social.witnessed_leader_death",
    family = "leader_loss",
    npc = {
        line("UI_PNC_LeaderDeath_Base_1",
            "{leaderName} is gone. Somebody has to lead us now."),
        line("UI_PNC_LeaderDeath_Base_2",
            "They're dead. We need to decide who's in charge."),
        line("UI_PNC_LeaderDeath_Base_3",
            "We just lost {leaderName}. We can't stand here doing nothing."),
    },
    variants = assemble(),
})

return PNC.SocialFlavorDefinitions
