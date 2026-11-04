-- One-way reader for pre-SurvivorWorld generic ProjectHoomans roots.
-- Normal runtime services must not write these roots or treat them as authority.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.SurvivorWorldImportSource =
    PNC.SurvivorWorldImportSource or {}

local Source = PNC.SurvivorWorldImportSource
local Reset = PNC.ModDataStore
    or require "PNC/Core/Persistence/PNC_ModDataStore"

-- Frozen input contracts for supported pre-SurvivorWorld saves. Keeping the
-- old keys here prevents normal faction/community/director/discovery services
-- from carrying retired storage ownership.
local specs = {
    factions = {
        key = "PNC_Factions",
        version = 6,
        valid = function(value)
            return type(value.byID) == "table"
        end,
    },
    communities = {
        key = "PNC_Communities",
        version = 2,
        valid = function(value)
            return type(value.byID) == "table"
                and type(value.sitesByID) == "table"
        end,
    },
    abstractWorld = {
        key = "PNC_AbstractWorld_v1",
        version = 1,
        valid = function(value)
            return type(value.groupsByID) == "table"
                and type(value.locationsByID) == "table"
                and type(value.encounters) == "table"
        end,
    },
    discovery = {
        key = "PNC_WorldDiscovery_v1",
        version = 2,
        valid = function(value)
            return type(value.players) == "table"
        end,
    },
}

function Source.Key(kind)
    local spec = specs[tostring(kind or "")]
    return spec and spec.key or nil
end

function Source.Read(kind)
    local spec = specs[tostring(kind or "")]
    if not spec then return nil, "unknown_import_source" end
    local raw = Reset.Read(spec.key)
    local reason = Reset.Check(
        raw,
        spec.version,
        nil,
        spec.valid
    )
    return reason == nil and raw or nil, reason, raw
end

function Source.HasData(kind)
    local spec = specs[tostring(kind or "")]
    if not spec then return false end
    local raw = Reset.Read(spec.key)
    return type(raw) == "table" and not Reset.IsEmpty(raw)
end

function Source.Retire(kind)
    local spec = specs[tostring(kind or "")]
    if not spec then return false, "unknown_import_source" end
    if not Source.HasData(kind) then
        return false, "already_empty"
    end
    return Reset.Write(spec.key, {})
end

function Source.Build()
    local factionRaw = Source.Read("factions")
    local communityRaw = Source.Read("communities")
    local abstractRaw = Source.Read("abstractWorld")
    local discoveryRaw = Source.Read("discovery")
    return {
        factions = factionRaw or {},
        communities = communityRaw or {},
        abstractWorld = abstractRaw or {},
        discovery = discoveryRaw or {},
    }
end

return Source
