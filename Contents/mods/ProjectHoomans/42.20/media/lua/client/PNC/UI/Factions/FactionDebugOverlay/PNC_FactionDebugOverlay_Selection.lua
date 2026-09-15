-- Selection resolution for the faction debug overlay.

PNC = PNC or {}
local Overlay = PNC.FactionDebugOverlay
local Internal = Overlay._Internal
local ClientState = Internal.ClientState

local function firstDistinctFaction(snapshot, sourceID)
    for _, faction in ipairs(snapshot and snapshot.factions or {}) do
        if faction.id ~= sourceID then return faction.id end
    end
    return nil
end

local function firstNPCForFaction(snapshot, factionID)
    for _, npc in ipairs(snapshot and snapshot.roster or {}) do
        local affiliation = npc.affiliation or {}
        if affiliation.factionID == factionID then
            return npc.id
        end
    end
    local first = snapshot and snapshot.roster
        and snapshot.roster[1] or nil
    return first and first.id or nil
end

function ISPNCFactionDebugOverlay:resolveSelection()
    local snapshot = ClientState.factionDebug
    local sourceID = self.sourceFactionID
        or snapshot and snapshot.selectedFactionID
        or snapshot and snapshot.currentPlayerFactionID
        or snapshot and snapshot.factions
            and snapshot.factions[1]
            and snapshot.factions[1].id
    local targetID = self.targetFactionID
        or snapshot and snapshot.selectedTargetFactionID
    if targetID == sourceID then targetID = nil end
    targetID = targetID
        or firstDistinctFaction(snapshot, sourceID)
    local npcID = self.npcID
        or snapshot and snapshot.selectedNPCID
        or firstNPCForFaction(snapshot, sourceID)
    self.sourceFactionID = sourceID
    self.targetFactionID = targetID
    self.npcID = npcID
end

return Overlay

