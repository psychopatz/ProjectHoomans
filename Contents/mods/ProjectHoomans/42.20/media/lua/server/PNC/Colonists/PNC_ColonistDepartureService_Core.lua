-- Authoritative relationship-triggered colonist departure.
-- This is deliberately separate from FollowerAbandonment: that service
-- records combat-range exits, while this service changes faction identity.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.ColonistDeparture = PNC.ColonistDeparture or {}

local Service = PNC.ColonistDeparture
local Core = PNC.Core
local Const = PNC.Const
local FactionConstants = PNC.FactionConstants
local Factions = PNC.Factions
local Registry = PNC.Registry
local Relationships = PNC.Relationships
local Graph = PNC.RelationshipGraph
local Policy = PNC.ColonistDeparturePolicy
local EntityRef = PNC.EntityRef
local PlayerCharacters = PNC.PlayerCharacters
local Mobile = PNC.MobileGroupDirector
local MobileInternal = PNC.MobileGroupDirectorInternal
local Resolver = PNC.CommunitySiteResolver

Service.PUMP_INTERVAL_HOURS = 1
Service.DEFAULT_PUMP_BUDGET = 8
Service.MANUAL_PENALTY_APPROVAL = -50
Service.MANUAL_PENALTY_RESPECT = -50

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

local function worldAge(value)
    value = tonumber(value)
    if value and value == value
        and value ~= math.huge and value ~= -math.huge
    then
        return math.max(0, value)
    end
    local time = getGameTime and getGameTime() or nil
    return time and time.getWorldAgeHours
        and math.max(0, tonumber(time:getWorldAgeHours()) or 0) or 0
end

local function markDirty(record, reason)
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, reason or "colonist_departure")
    end
end

local function log(message)
    if Core and Core.LogInfo then
        Core.LogInfo("[PNC ColonistDeparture] " .. tostring(message))
    end
end

local function playerKeyFor(player, at)
    local key
    local ok
    if not player then return nil end
    if PlayerCharacters and PlayerCharacters.GetEntityKey then
        ok, key = pcall(
            PlayerCharacters.GetEntityKey,
            player,
            { callback = "colonist_departure", worldAgeHours = at }
        )
        if ok and key and tostring(key) ~= "" then
            return tostring(key)
        end
    end
    local internal = Factions and Factions.Internal
    if internal and internal.playerKeyFor then
        ok, key = pcall(
            internal.playerKeyFor,
            player,
            "colonist_departure",
            false
        )
        if ok and key and tostring(key) ~= "" then
            return tostring(key)
        end
    end
    return nil
end

local function relationshipFor(record, playerKey)
    if not Relationships or not Relationships.Get then return nil end
    return Relationships.Get(record.id, playerKey)
end

function Service.Evaluate(record, relationship, context)
    if not Policy or not Policy.Evaluate then return nil end
    local personality = Graph and Graph.ResolveNPCPersonality
        and Graph.ResolveNPCPersonality(record) or {}
    return Policy.Evaluate(
        relationship and relationship.approval,
        relationship and relationship.respect,
        personality,
        context
    )
end

function Service.GetPreview(record, relationship)
    local evaluation = Service.Evaluate(record, relationship)
    return Policy and Policy.CopyPreview
        and Policy.CopyPreview(evaluation) or evaluation
end

local function sourceFaction(record)
    local factionID = record and record.affiliation
        and record.affiliation.factionID or nil
    local faction = factionID and Factions and Factions.Get
        and Factions.Get(factionID) or nil
    if not faction or Factions.IsMobileGroup(faction) then
        return nil, "not_player_colonist"
    end
    if not faction.ownerPlayerKey
        or not EntityRef or not EntityRef.IsPlayer
        or not EntityRef.IsPlayer(faction.ownerPlayerKey)
    then
        return nil, "not_player_faction"
    end
    return faction
end

function Service.CanPlayerManage(player, record, suppliedKey)
    if not record or record.alive == false then
        return false, "npc_not_found"
    end
    if record.recruited ~= true then return false, "npc_not_recruited" end
    local at = worldAge()
    local key = suppliedKey or playerKeyFor(player, at)
    if not key then return false, "player_identity_unavailable" end
    local faction, factionReason = sourceFaction(record)
    if not faction then return false, factionReason end
    if faction.ownerPlayerKey ~= key then
        return false, "not_colonist_owner"
    end
    return true, nil, key, faction
end

local Internal = Service.Internal or {}
Service.Internal = Internal
Internal.Finite = finite
Internal.WorldAge = worldAge
Internal.MarkDirty = markDirty
Internal.Log = log
Internal.RelationshipFor = relationshipFor
Internal.PlayerKeyFor = playerKeyFor
Internal.SourceFaction = sourceFaction

return Service
