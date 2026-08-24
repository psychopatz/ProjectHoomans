if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Factions = PNC.Factions
local Internal = Factions.Internal
local Core = PNC.Core
local Constants = PNC.FactionConstants
local Types = PNC.FactionTypes
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
function Factions.Load()
    local raw
    local normalized
    if not Internal.authority() then return false, "not_authority" end
    if PNC.Registry and PNC.Registry.EnsureLoaded then
        PNC.Registry.EnsureLoaded()
    end
    raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Constants.REGISTRY_MODDATA_KEY)
        or {}
    normalized = Types.NormalizeFactionRegistry(raw)
    Factions.Registry = normalized
    Factions.Loaded = true
    Factions.Dirty = not Types.AreEqual(raw, normalized)
    Internal.rebuildIndexes()
    if Factions.ReconcilePlayerMemberships then
        Factions.ReconcilePlayerMemberships(
            getGameTime and getGameTime()
                and getGameTime().getWorldAgeHours
                and getGameTime():getWorldAgeHours() or 0
        )
    end
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileAll
    then
        PNC.FactionBehavior.ReconcileAll("registry_load")
    end
    if PNC.ProvisionScheduler then
        for factionID in pairs(Factions.Registry.byID or {}) do
            PNC.ProvisionScheduler.MarkFactionDirty(factionID)
        end
    end
    return true, Factions.Dirty
end

function Factions.EnsureLoaded()
    if not Factions.Loaded then return Factions.Load() end
    return true
end

function Factions.Save()
    local target
    local normalized
    Factions.EnsureLoaded()
    if not Factions.Dirty then return false, "not_dirty" end
    target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Constants.REGISTRY_MODDATA_KEY)
        or nil
    if not target then return false, "moddata_unavailable" end
    normalized = Types.NormalizeFactionRegistry(Factions.Registry)
    Internal.assignTable(target, Internal.copy(normalized))
    Factions.Registry = normalized
    Factions.Dirty = false
    return true, "saved"
end

function Factions.RebuildIndexes()
    Factions.EnsureLoaded()
    return Internal.rebuildIndexes()
end

function Factions.GenerateID()
    Factions.EnsureLoaded()
    for _ = 1, Constants.ID_GENERATION_RETRIES do
        local candidate = Factions.IDGenerator()
        if Types.IsValidFactionID(candidate)
            and not Factions.Registry.byID[candidate]
        then
            return candidate
        end
    end
    return nil, "id_generation_failed"
end

return Factions
