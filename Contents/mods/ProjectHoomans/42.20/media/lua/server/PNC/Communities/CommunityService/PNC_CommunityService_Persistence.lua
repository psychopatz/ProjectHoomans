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
local Reset = (PNC.Persistence and PNC.Persistence.Reset)
    or require "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Reset"

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
    raw = Reset.Read(Constants.REGISTRY_MODDATA_KEY)
    local reason = Reset.Check(raw, Constants.REGISTRY_SCHEMA_VERSION, nil,
        function(value)
            return type(value.byID) == "table"
                and type(value.sitesByID) == "table"
        end)
    normalized = Types.NormalizeRegistry(reason == nil and raw or nil)
    Communities.Registry = normalized
    Communities.Loaded = true
    Communities.Dirty = (reason ~= nil and reason ~= "empty_state")
        or (reason == nil and not Types.AreEqual(raw, normalized))
    if reason ~= nil and reason ~= "empty_state" then
        Reset.Mark(Communities, raw, Constants.REGISTRY_SCHEMA_VERSION,
            reason, "communities")
    end
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
    normalized = Types.NormalizeRegistry(Communities.Registry)
    local written = Reset.Write(Constants.REGISTRY_MODDATA_KEY,
        copy(normalized))
    if not written then return false, "moddata_unavailable" end
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
