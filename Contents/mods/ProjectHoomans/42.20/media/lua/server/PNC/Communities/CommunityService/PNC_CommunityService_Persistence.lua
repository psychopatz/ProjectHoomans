if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Communities = PNC.Communities or {}
PNC.Communities.Internal = PNC.Communities.Internal or {}

local Communities = PNC.Communities
local Internal = Communities.Internal
local Core = PNC.Core
local Constants = PNC.CommunityConstants
local Types = PNC.CommunityTypes
local CommunityMath = PNC.CommunityMath
local FactionTypes = PNC.FactionTypes
local authority = Internal.authority
local copy = Internal.copy
local assignTable = Internal.assignTable
local rebuildDerivedIndexes = Internal.rebuildDerivedIndexes
local reconcileLeaders = Internal.reconcileLeaders
local reconcileNPCReferences = Internal.reconcileNPCReferences

function Communities.Load()
    local raw
    local normalized
    if not authority() then return false, "not_authority" end
    if PNC.Registry and PNC.Registry.EnsureLoaded then
        PNC.Registry.EnsureLoaded()
    end
    if PNC.Factions and PNC.Factions.EnsureLoaded then
        PNC.Factions.EnsureLoaded()
    end
    raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(
            Constants.REGISTRY_MODDATA_KEY
        ) or {}
    normalized = Types.NormalizeRegistry(raw)
    Communities.Registry = normalized
    Communities.Loaded = true
    Communities.Dirty = not Types.AreEqual(raw, normalized)
    reconcileNPCReferences()
    rebuildDerivedIndexes()
    reconcileLeaders()
    return true, Communities.Dirty
end

function Communities.EnsureLoaded()
    if not Communities.Loaded then
        return Communities.Load()
    end
    return true
end

function Communities.Save()
    local target
    local normalized
    Communities.EnsureLoaded()
    if not Communities.Dirty then return false, "not_dirty" end
    target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(
            Constants.REGISTRY_MODDATA_KEY
        ) or nil
    if not target then return false, "moddata_unavailable" end
    normalized = Types.NormalizeRegistry(Communities.Registry)
    assignTable(target, copy(normalized))
    Communities.Registry = normalized
    Communities.Dirty = false
    return true, "saved"
end

function Communities.GenerateID()
    Communities.EnsureLoaded()
    for _ = 1, Constants.ID_GENERATION_RETRIES do
        local candidate = Communities.IDGenerator()
        if Types.IsValidCommunityID(candidate)
            and not Communities.Registry.byID[candidate]
        then
            return candidate
        end
    end
    return nil, "id_generation_failed"
end


return Communities
