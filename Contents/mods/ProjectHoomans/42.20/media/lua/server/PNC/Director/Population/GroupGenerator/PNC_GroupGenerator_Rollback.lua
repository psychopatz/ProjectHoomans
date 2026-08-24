if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local H = PNC.GroupGenerator.Internal

function H.RollbackFaction(factionID, at)
    local faction = factionID and PNC.Factions.Get(factionID) or nil
    for npcID in pairs(faction and faction.memberIDs or {}) do
        if PNC.Factions.RemoveNPC then
            PNC.Factions.RemoveNPC(factionID, npcID,
                "population_generation_rollback", at)
        end
        if PNC.API and PNC.API.Despawn then PNC.API.Despawn(npcID) end
    end
    if factionID and PNC.Factions.Destroy then
        PNC.Factions.Destroy(factionID, "population_generation_rollback", at)
    end
end

function H.RollbackGeneratedMembers(factionID, result, at)
    for _, npcID in ipairs(result and result.npcIDs or {}) do
        if PNC.Factions.RemoveNPC then
            PNC.Factions.RemoveNPC(factionID, npcID,
                "population_generation_rollback", at)
        end
        if PNC.API and PNC.API.Despawn then PNC.API.Despawn(npcID) end
    end
    if PNC.Factions.ClearMobileGroup then
        PNC.Factions.ClearMobileGroup(factionID,
            "population_generation_rollback")
    end
end
