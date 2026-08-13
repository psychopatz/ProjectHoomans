if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ProductionContext = PNC.ProductionContext or {}
local Context = PNC.ProductionContext

function Context.ForPlayer(player)
    local faction = PNC.Factions and PNC.Factions.GetPlayerFaction
        and PNC.Factions.GetPlayerFaction(player) or nil
    if not faction then return nil, "FACTION_REQUIRED" end
    local colony
    if PNC.Communities and PNC.Communities.GetForFaction then
        for _, candidate in ipairs(PNC.Communities.GetForFaction(faction.id) or {}) do
            if candidate.status == "active" then colony = candidate; break end
        end
    end
    if not colony then return nil, "COLONY_REQUIRED" end
    local base = PNC.BaseService and PNC.BaseService.GetForColony
        and PNC.BaseService.GetForColony(colony.id) or nil
    if not base then return nil, "BASE_REQUIRED" end
    local storage = PNC.ColonyStorageRepository.GetPrimary(faction.id, colony.id)
    return { faction = faction, colony = colony, base = base, storage = storage }
end

return Context
