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
local Core = PNC.Core
local MAX_ARRIVAL_LISTENER_DIAGNOSTICS = 32

Service.ArrivalListeners = Service.ArrivalListeners or {}
Service.ArrivalListenerDiagnostics = Service.ArrivalListenerDiagnostics or {}

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

-- The generic temporary-visit gate intentionally reuses the same bounded
-- settlement/relationship safety checks as admission, but its caller owns no
-- membership transfer and therefore never consults the AI join chance.
function Service.IsSettlementVisitEligible(factionOrID, target, at)
    return Service.IsAdmissionEligible(factionOrID, target, at)
end

function Service.NormalizeSettlementVisitIntent(value)
    local maximum = Constants
        and Constants.MOBILE_SETTLEMENT_VISIT_INTENT_MAX_LENGTH or 96
    value = tostring(value or "")
    if value == "" then
        return Constants and Constants.MOBILE_SETTLEMENT_VISIT_INTENT_GENERAL
            or "general"
    end
    if #value > maximum then value = string.sub(value, 1, maximum) end
    return value
end

function Service.IsVisitActive(visit, at)
    return type(visit) == "table"
        and (tostring(visit.kind or "") == "settlement_admission"
            or tostring(visit.kind or "") == "settlement_visit")
        and (tonumber(visit.expiresAt) or 0) > worldAge(at)
end

-- Persist only a bounded, normalized recent-visit ledger on the mobile group.
-- It is generic Hoomans travel memory: consumers may use it for cooldowns,
-- but it never chooses a destination or transfers membership.
function Service.RecordSettlementVisit(factionOrID, target, at)
    local faction = type(factionOrID) == "table" and factionOrID
        or Factions and Factions.Get and Factions.Get(factionOrID)
    local mobile = faction and faction.mobile or nil
    local history = {}
    local entry
    local key
    local index
    local existing
    local limit = Constants.MOBILE_SETTLEMENT_HISTORY_LIMIT or 8
    local cooldown = Constants.MOBILE_SETTLEMENT_REVISIT_COOLDOWN_HOURS
        or 24
    local visitedAt = worldAge(at)
    if not faction or not mobile or type(target) ~= "table"
        or not Factions or not Factions.UpdateMobileGroup
    then
        return false, "mobile_visit_history_unavailable"
    end
    entry = {
        communityID = target.communityID,
        locationID = target.locationID or target.id,
        siteID = target.siteID,
        visitedAt = visitedAt,
        cooldownUntil = visitedAt + cooldown,
    }
    key = tostring(entry.communityID or entry.locationID or "")
    for index = 1, #(mobile.settlementHistory or {}) do
        existing = mobile.settlementHistory[index]
        if type(existing) == "table"
            and tostring(existing.communityID or existing.locationID or "")
                ~= key
        then
            history[#history + 1] = copy(existing)
        end
    end
    table.insert(history, 1, entry)
    while #history > limit do table.remove(history) end
    return Factions.UpdateMobileGroup(
        faction.id,
        { settlementHistory = history },
        "mobile_settlement_visit_history"
    )
end

-- Generic settlement-arrival notification for server integrations. The
-- mobile-settlement service remains authoritative for eligibility, movement,
-- admission, and persistent visit state; listeners only observe an accepted
-- arrival and must not mutate the supplied snapshot.
function Service.RegisterArrivalListener(listener)
    local listeners = Service.ArrivalListeners
    local index
    if type(listener) ~= "function" then return false end
    for index = 1, #listeners do
        if listeners[index] == listener then return true end
    end
    listeners[#listeners + 1] = listener
    return true
end

function Service.UnregisterArrivalListener(listener)
    local listeners = Service.ArrivalListeners
    local index
    if type(listener) ~= "function" then return false end
    for index = #listeners, 1, -1 do
        if listeners[index] == listener then
            table.remove(listeners, index)
            return true
        end
    end
    return false
end

local function listenerDiagnostic(index, reason, kind)
    local diagnostics = Service.ArrivalListenerDiagnostics
    local value = tostring(reason or "arrival_listener_failed")
    if #value > 256 then value = string.sub(value, 1, 256) end
    diagnostics[#diagnostics + 1] = {
        index = index,
        kind = kind or "rejected",
        reason = value,
        at = worldAge(),
    }
    while #diagnostics > MAX_ARRIVAL_LISTENER_DIAGNOSTICS do
        table.remove(diagnostics, 1)
    end
end

-- Runtime diagnostics are intentionally bounded and non-persistent. They
-- make a clean `false, reason` consumer result visible without allowing a
-- listener failure to interrupt Hoomans' authoritative arrival lifecycle.
function Service.GetArrivalListenerDiagnostics(limit)
    local diagnostics = Service.ArrivalListenerDiagnostics
    local output = {}
    local count = #diagnostics
    local requested = math.floor(tonumber(limit) or count)
    local first
    if requested < 1 then return output end
    requested = math.min(requested, MAX_ARRIVAL_LISTENER_DIAGNOSTICS)
    first = math.max(1, count - requested + 1)
    for index = first, count do
        output[#output + 1] = copy(diagnostics[index])
    end
    return output
end

function Service.NotifySettlementArrival(details)
    local listeners = Service.ArrivalListeners
    local index
    local ok
    local accepted
    local reason
    local summary = {
        notified = 0,
        rejected = 0,
        failed = 0,
    }
    if type(details) ~= "table" then return false end
    for index = 1, #listeners do
        -- This pcall is the external observer callback boundary. A consumer
        -- must never break the Hoomans-owned arrival transition.
        ok, accepted, reason = pcall(listeners[index], copy(details))
        summary.notified = summary.notified + 1
        if not ok then
            summary.failed = summary.failed + 1
            listenerDiagnostic(index, accepted, "error")
        elseif accepted == false then
            summary.rejected = summary.rejected + 1
            listenerDiagnostic(index, reason, "rejected")
        end
        if (not ok or accepted == false)
            and Core and type(Core.LogWarn) == "function"
        then
            Core.LogWarn(
                "PNC settlement arrival listener failed index="
                    .. tostring(index) .. " kind="
                    .. tostring(not ok and "error" or "rejected")
                    .. " reason=" .. tostring(not ok and accepted or reason)
            )
        end
    end
    return true, summary
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
