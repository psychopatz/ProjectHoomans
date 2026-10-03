-- Settlement arrival admission policy for eligible mobile groups.
-- Hostile groups may use the deferred arrival handoff, but never enter the
-- admission path; the existing encounter system remains authoritative.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.MobileSettlementVisitService = PNC.MobileSettlementVisitService or {}

local Service = PNC.MobileSettlementVisitService
local Constants = PNC.FactionConstants
local Config = PNC.DirectorConfig
local Factions = PNC.Factions
local Communities = PNC.Communities
local Store = PNC.AbstractWorldStore

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value)
        or value
end

local function hasEntries(value)
    for _, present in pairs(type(value) == "table" and value or {}) do
        if present == true then return true end
    end
    return false
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

local function factionIDFor(record)
    if not record then return nil end
    if Factions and Factions.GetFactionID then
        return Factions.GetFactionID(record)
    end
    return record.affiliation and record.affiliation.factionID or nil
end

local function targetCommunity(target)
    local community
    local base
    if not target then return nil, "settlement_target_missing" end
    if target.communityID and Communities and Communities.Get then
        community = Communities.Get(target.communityID)
        if community then return community end
    end
    if target.baseID and PNC.BaseService and PNC.BaseService.Get then
        base = PNC.BaseService.Get(target.baseID)
        if base and base.colonyId and Communities
            and Communities.Get
        then
            community = Communities.Get(base.colonyId)
            if community then return community end
        end
    end
    return nil, "settlement_community_missing"
end

local function targetFaction(target, community)
    local factionID = target and target.factionID
        or community and community.factionID
    if not factionID or not Factions or not Factions.Get then
        return nil
    end
    return Factions.Get(factionID)
end

local function relationFor(source, destination, at)
    if not source or not destination
        or source.id == destination.id
    then
        return nil, "same_faction"
    end
    local relation = Factions.GetRelation
        and Factions.GetRelation(source.id, destination.id)
        or source.relations and source.relations[destination.id]
    if not relation then return nil, "unknown" end
    local state = relation.state
    if PNC.FactionDiplomacyMath
        and PNC.FactionDiplomacyMath.ResolveState
    then
        state = PNC.FactionDiplomacyMath.ResolveState(relation, at)
    end
    return relation, tostring(state or "unknown")
end

local function relationIsHostile(relation, state)
    return relation and (
        relation.atWar == true
        or state == "war"
        or state == "hostile"
    ) or false
end

local function isHostileToSettlement(source, destination, at)
    if source and source.archetypeID == "looter" then return true end
    local relation, state = relationFor(source, destination, at)
    if relationIsHostile(relation, state) then return true end
    -- Treat either side's explicit war/hostile state as unsafe. This keeps a
    -- stale or asymmetric relation from opening a recruitment visit.
    local reverse, reverseState = relationFor(destination, source, at)
    return relationIsHostile(reverse, reverseState)
end

local function hasPlayerMembers(faction)
    if not faction then return false end
    for _, present in pairs(faction.playerMemberKeys or {}) do
        if present == true then return true end
    end
    return faction.ownerPlayerKey ~= nil
        and tostring(faction.ownerPlayerKey) ~= ""
end

function Service.IsAdmissionEligible(factionOrID, target, at)
    local faction = type(factionOrID) == "table" and factionOrID
        or Factions and Factions.Get and Factions.Get(factionOrID)
    local community
    local destination
    if not faction or not faction.mobile
        or faction.mobile.active ~= true
    then
        return false, "not_mobile_group"
    end
    if faction.archetypeID == "looter" then
        return false, "hostile_mobile_group"
    end
    if not target or (target.kind ~= "ai_settlement"
        and target.kind ~= "player_colony")
    then
        return false, "not_admission_target"
    end
    community = targetCommunity(target)
    if not community then return false, "settlement_community_missing" end
    destination = targetFaction(target, community)
    if not destination or destination.status ~= "active" then
        return false, "settlement_faction_missing"
    end
    if target.kind == "player_colony"
        and not hasPlayerMembers(destination)
    then
        return false, "player_settlement_owner_missing"
    end
    if tostring(community.factionID or "") ~= tostring(destination.id) then
        return false, "settlement_faction_mismatch"
    end
    if isHostileToSettlement(faction, destination, worldAge(at)) then
        return false, "hostile_settlement_relationship"
    end
    return true, "eligible", community, destination
end

function Service.IsVisitActive(visit, at)
    return type(visit) == "table"
        and tostring(visit.kind or "") == "settlement_admission"
        and (tonumber(visit.expiresAt) or 0) > worldAge(at)
end


Service.Internal = Service.Internal or {}
local Internal = Service.Internal
Internal.copy = copy
Internal.hasEntries = hasEntries
Internal.worldAge = worldAge
Internal.factionIDFor = factionIDFor
Internal.targetCommunity = targetCommunity
Internal.targetFaction = targetFaction
Internal.relationFor = relationFor
Internal.relationIsHostile = relationIsHostile
Internal.isHostileToSettlement = isHostileToSettlement
Internal.hasPlayerMembers = hasPlayerMembers
Internal.Constants = Constants
Internal.Config = Config
Internal.Factions = Factions
Internal.Communities = Communities
Internal.Store = Store

return Service
