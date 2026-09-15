-- List-item projections for factions, targets, and NPC records.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal
require "PNC/UI/Mobile/PNC_MobileGroupDebugModel"

local MobileModel = PNC.MobileGroupDebugModel
function Model.BuildFactionItems(snapshot)
    local output = {}
    for _, faction in ipairs(
        snapshot and snapshot.factions or {}
    ) do
        local mobile = faction.mobile
        local detail = faction.archetypeLabel
            .. " / " .. faction.status
            .. (faction.ownerPlayerKey
                and " / player-owned" or "")
        if mobile and mobile.active == true then
            detail = detail .. " | " .. MobileModel.StateText(mobile)
        end
        output[#output + 1] = {
            id = faction.id,
            label = faction.name,
            detail = detail,
            faction = faction,
        }
    end
    return output
end

function Model.BuildTargetFactionItems(snapshot)
    local output = Model.BuildFactionItems(snapshot)
    local provisional = snapshot
        and snapshot.currentPlayerDiplomacyFaction or nil
    if provisional then
        output[#output + 1] = {
            id = provisional.id,
            label = provisional.name,
            detail = "Player diplomacy identity / provisional",
            faction = provisional,
        }
    end
    return output
end

function Model.BuildNPCItems(snapshot)
    local output = {}
    for _, npc in ipairs(snapshot and snapshot.roster or {}) do
        local affiliation = npc.affiliation or {}
        output[#output + 1] = {
            id = npc.id,
            label = npc.name,
            detail = affiliation.factionID
                or "unaffiliated",
            npc = npc,
        }
    end
    return output
end
return Model

