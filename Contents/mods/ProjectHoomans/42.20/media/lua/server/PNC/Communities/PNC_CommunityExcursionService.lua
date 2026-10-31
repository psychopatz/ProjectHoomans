-- Generic, purpose-agnostic community excursion state owned by Project
-- Hoomans. It persists on the authoritative faction record; movement and
-- abstract traversal remain separate services that advance this lifecycle.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.CommunityExcursionService = PNC.CommunityExcursionService or {}

local Service = PNC.CommunityExcursionService
local Factions = PNC.Factions
local Communities = PNC.Communities
local Types = PNC.FactionTypes
local Constants = PNC.FactionConstants
local Store = PNC.AbstractWorldStore
local Repository = Factions and Factions.Repository or {}
local Core = PNC.Core

Service.VERSION = 1
Service.MAX_LISTENERS = 16
Service.MAX_POLICIES = 8
Service.MAX_REQUEST_EVALUATORS = 8
Service.MAX_RECONCILE = 32
Service.MAX_POLICY_DIAGNOSTICS = 32
Service.MAX_REQUEST_DIAGNOSTICS = 32
Service.STATES = {
    AT_HOME = Constants.EXCURSION_STATE_AT_HOME,
    PREPARING = Constants.EXCURSION_STATE_PREPARING,
    OUTBOUND = Constants.EXCURSION_STATE_OUTBOUND,
    VISITING = Constants.EXCURSION_STATE_VISITING,
    RETURNING_HOME = Constants.EXCURSION_STATE_RETURNING_HOME,
    FAILED = Constants.EXCURSION_STATE_FAILED,
}
Service.Listeners = Service.Listeners or {}
Service.Policies = Service.Policies or {}
Service.PolicyDiagnostics = Service.PolicyDiagnostics or {}
Service.ListenerDiagnostics = Service.ListenerDiagnostics or {}
Service.RequestEvaluators = Service.RequestEvaluators or {}
Service.RequestDiagnostics = Service.RequestDiagnostics or {}

local EXCURSION_SETTLEMENT_ARRIVAL = "community_excursion_settlement"
local EXCURSION_HOME_ARRIVAL = "community_excursion_home"

local TRANSITIONS = {
    AT_HOME = { PREPARING = true },
    PREPARING = { OUTBOUND = true, FAILED = true, AT_HOME = true },
    OUTBOUND = { VISITING = true, FAILED = true },
    VISITING = { RETURNING_HOME = true, FAILED = true },
    RETURNING_HOME = { AT_HOME = true, FAILED = true },
    FAILED = { PREPARING = true, AT_HOME = true },
}

local function copy(value)
    if Core and type(Core.DeepCopy) == "function" then
        return Core.DeepCopy(value)
    end
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

local function authority()
    if Repository and type(Repository.IsAuthority) == "function" then
        return Repository.IsAuthority() == true
    end
    return Core and type(Core.IsAuthority) == "function"
        and Core.IsAuthority() == true
end

local function worldAge(value)
    value = tonumber(value)
    if value and value == value and value ~= math.huge
        and value ~= -math.huge
    then
        return math.max(0, value)
    end
    if Store and type(Store.WorldAgeHours) == "function" then
        return math.max(0, tonumber(Store.WorldAgeHours()) or 0)
    end
    local gameTime = getGameTime and getGameTime() or nil
    if gameTime and type(gameTime.getWorldAgeHours) == "function" then
        return math.max(0, tonumber(gameTime:getWorldAgeHours()) or 0)
    end
    return 0
end

local function safeText(value, maximum)
    if type(value) ~= "string" or value == "" then return nil end
    if string.find(value, "%c") then return nil end
    if #value > maximum then return string.sub(value, 1, maximum) end
    return value
end

local function diagnostic(kind, name, reason)
    local diagnostics = Service.PolicyDiagnostics
    diagnostics[#diagnostics + 1] = {
        kind = tostring(kind or "unknown"),
        name = tostring(name or ""),
        reason = tostring(reason or ""),
        at = worldAge(),
    }
    while #diagnostics > Service.MAX_POLICY_DIAGNOSTICS do
        table.remove(diagnostics, 1)
    end
end

local function listenerDiagnostic(index, reason)
    local diagnostics = Service.ListenerDiagnostics
    diagnostics[#diagnostics + 1] = {
        index = index,
        reason = tostring(reason or "excursion_listener_rejected"),
        at = worldAge(),
    }
    while #diagnostics > Service.MAX_POLICY_DIAGNOSTICS do
        table.remove(diagnostics, 1)
    end
end

local function requestDiagnostic(kind, name, reason)
    local diagnostics = Service.RequestDiagnostics
    diagnostics[#diagnostics + 1] = {
        kind = tostring(kind or "unknown"),
        name = tostring(name or ""),
        reason = tostring(reason or ""),
        at = worldAge(),
    }
    while #diagnostics > Service.MAX_REQUEST_DIAGNOSTICS do
        table.remove(diagnostics, 1)
    end
end

local function factionRecord(factionID)
    if Repository and type(Repository.GetRecord) == "function" then
        return Repository.GetRecord(factionID)
    end
    if Factions and type(Factions.EnsureLoaded) == "function" then
        Factions.EnsureLoaded()
    end
    return Factions and Factions.Registry
        and Factions.Registry.byID and Factions.Registry.byID[factionID]
        or nil
end

local function touch(faction, reason)
    if Repository and type(Repository.MarkChanged) == "function" then
        Repository.MarkChanged(faction)
        return
    end
    faction.revision = math.max(0, math.floor(
        tonumber(faction.revision) or 0
    )) + 1
    if Factions then Factions.Dirty = true end
end

local function normalizeTarget(target)
    local normalizer = Types and Types.NormalizeTargetPoint or nil
    if type(normalizer) == "function" then
        return normalizer(target, "location")
    end
    if type(target) ~= "table" then return nil end
    local locationID = safeText(target.locationID, Constants.ID_MAX_LENGTH)
    if not locationID then return nil end
    return {
        kind = safeText(target.kind, Constants.TAG_VALUE_MAX_LENGTH)
            or "location",
        locationID = locationID,
        communityID = safeText(target.communityID, Constants.ID_MAX_LENGTH),
        siteID = safeText(target.siteID, Constants.ID_MAX_LENGTH),
        x = tonumber(target.x),
        y = tonumber(target.y),
        z = tonumber(target.z) or 0,
    }
end

local function normalizeParticipants(values)
    local output = {}
    local seen = {}
    local validator = Types and Types.IsValidNPCID
    values = type(values) == "table" and values or {}
    for index = 1, math.min(
        Constants.EXCURSION_MAX_PARTICIPANTS or 24, #values
    ) do
        local npcID = values[index]
        local valid = validator and validator(npcID)
            or type(npcID) == "string" and npcID ~= ""
        if valid and not seen[npcID] then
            seen[npcID] = true
            output[#output + 1] = npcID
        end
    end
    return output
end

local function normalizeItinerary(values)
    local output = {}
    values = type(values) == "table" and values or {}
    for index = 1, math.min(
        Constants.EXCURSION_MAX_ITINERARY or 16, #values
    ) do
        local target = normalizeTarget(values[index])
        if target then output[#output + 1] = target end
    end
    return output
end

local function normalizeExcursion(value)
    local normalizer = Types and Types.NormalizeExcursion or nil
    if type(normalizer) == "function" then return normalizer(value) end
    if type(value) ~= "table" then return nil end
    local homeFactionID = safeText(value.homeFactionID, Constants.ID_MAX_LENGTH)
    local homeCommunityID = safeText(
        value.homeCommunityID, Constants.ID_MAX_LENGTH)
    if not homeFactionID or not homeCommunityID then return nil end
    return {
        schemaVersion = Constants.EXCURSION_SCHEMA_VERSION or 1,
        id = safeText(value.id, Constants.ID_MAX_LENGTH * 2),
        homeFactionID = homeFactionID,
        homeCommunityID = homeCommunityID,
        state = Constants.EXCURSION_STATES[value.state]
            and value.state or Constants.EXCURSION_STATE_AT_HOME,
        purpose = safeText(value.purpose,
            Constants.EXCURSION_MAX_PURPOSE_LENGTH or 96) or "general",
        visitIntent = safeText(value.visitIntent or value.intent,
            Constants.EXCURSION_MAX_INTENT_LENGTH
                or Constants.MOBILE_SETTLEMENT_VISIT_INTENT_MAX_LENGTH
                or 96)
            or Constants.MOBILE_SETTLEMENT_VISIT_INTENT_GENERAL,
        publicReason = safeText(value.publicReason,
            Constants.EXCURSION_MAX_REASON_LENGTH or 128),
        participants = normalizeParticipants(value.participants),
        itinerary = normalizeItinerary(value.itinerary),
        currentLeg = math.max(0, math.floor(tonumber(value.currentLeg) or 0)),
        destination = normalizeTarget(value.destination),
        createdAt = worldAge(value.createdAt),
        stateAt = worldAge(value.stateAt),
        preparedAt = worldAge(value.preparedAt),
        departedAt = worldAge(value.departedAt),
        visitedAt = worldAge(value.visitedAt),
        returnStartedAt = worldAge(value.returnStartedAt),
        expectedReturnAt = worldAge(value.expectedReturnAt),
        completedAt = worldAge(value.completedAt),
        failure = nil,
        revision = math.max(0, math.floor(tonumber(value.revision) or 0)),
    }
end

local function activeHome(excursion)
    local community = Communities and Communities.Get
        and Communities.Get(excursion.homeCommunityID) or nil
    if type(community) ~= "table" then return nil, "home_community_missing" end
    if community.status ~= "active" then
        return nil, "home_community_inactive"
    end
    if tostring(community.factionID or "")
        ~= tostring(excursion.homeFactionID or "")
    then
        return nil, "home_faction_mismatch"
    end
    return community
end

local function publicDestination(target)
    if type(target) ~= "table" then return nil end
    return {
        kind = target.kind,
        communityID = target.communityID,
        siteID = target.siteID,
        locationID = target.locationID,
    }
end

local function publicStatus(excursion)
    local state = excursion.state
    return {
        active = state ~= Constants.EXCURSION_STATE_AT_HOME,
        id = excursion.id,
        state = state,
        purpose = excursion.purpose,
        visitIntent = excursion.visitIntent,
        publicReason = excursion.publicReason,
        homeFactionID = excursion.homeFactionID,
        homeCommunityID = excursion.homeCommunityID,
        participantCount = #excursion.participants,
        destination = publicDestination(excursion.destination),
        expectedReturnAt = excursion.expectedReturnAt,
        createdAt = excursion.createdAt,
        stateAt = excursion.stateAt,
        preparedAt = excursion.preparedAt,
        departedAt = excursion.departedAt,
        visitedAt = excursion.visitedAt,
        returnStartedAt = excursion.returnStartedAt,
        completedAt = excursion.completedAt,
        failure = copy(excursion.failure),
        revision = excursion.revision,
    }
end

local function viewerFactionID(viewer)
    if type(viewer) ~= "table" then return nil end
    if viewer.factionID ~= nil then return tostring(viewer.factionID) end
    if viewer.homeFactionID ~= nil then
        return tostring(viewer.homeFactionID)
    end
    local affiliation = viewer.affiliation
    if type(affiliation) == "table" and affiliation.factionID ~= nil then
        return tostring(affiliation.factionID)
    end
    return nil
end

local function routeDisclosure(excursion, viewer)
    local factionID = viewerFactionID(viewer)
    if not factionID then return false end
    if factionID == tostring(excursion.homeFactionID or "") then
        return true
    end
    if type(viewer) == "table" and viewer.isLeader == true
        and viewer.homeFactionID == excursion.homeFactionID
    then
        return true
    end
    return false
end

local function socialStatus(excursion, viewer)
    local output = publicStatus(excursion)
    local knowsRoute = routeDisclosure(excursion, viewer)
    output.status = output.state == Constants.EXCURSION_STATE_AT_HOME
        and "home"
        or output.state == Constants.EXCURSION_STATE_PREPARING
        and "preparing"
        or output.state == Constants.EXCURSION_STATE_RETURNING_HOME
        and "returning"
        or output.state == Constants.EXCURSION_STATE_FAILED
        and "failed"
        or "away"
    output.phase = output.state
    output.reason = output.publicReason
    output.destinationKnown = knowsRoute and output.destination ~= nil
    output.expectedReturnKnown = knowsRoute
        and output.expectedReturnAt ~= nil
        and output.expectedReturnAt > 0
    output.locationState = output.state == Constants.EXCURSION_STATE_AT_HOME
        and "home"
        or output.state == Constants.EXCURSION_STATE_VISITING
        and "visiting"
        or output.state == Constants.EXCURSION_STATE_RETURNING_HOME
        and "returning"
        or output.state == Constants.EXCURSION_STATE_PREPARING
        and "preparing"
        or output.state == Constants.EXCURSION_STATE_OUTBOUND
        and "away"
        or "unknown"
    if not knowsRoute then
        output.destination = nil
        output.expectedReturnAt = nil
    elseif output.destination then
        output.destinationCommunityID = output.destination.communityID
    end
    return output
end

local function notify(factionID, excursion, reason)
    local payload = publicStatus(excursion)
    payload.factionID = factionID
    payload.reason = reason
    for index = 1, #Service.Listeners do
        -- External listeners are an observation boundary. Their failure must
        -- not interrupt authoritative faction state or traversal ownership.
        local ok, listenerAccepted, listenerReason = pcall(
            Service.Listeners[index], copy(payload))
        if ok and listenerAccepted == false then
            listenerDiagnostic(index, listenerReason)
        elseif not ok and Core and type(Core.LogWarn) == "function" then
            Core.LogWarn("community excursion listener failed index="
                .. tostring(index) .. " error=" .. tostring(listenerReason))
            listenerDiagnostic(index, listenerReason)
        end
    end
    if Store and type(Store.Emit) == "function" then
        Store.Emit("COMMUNITY_EXCURSION_CHANGED", copy(payload))
    end
end

function Service.RegisterListener(listener)
    if type(listener) ~= "function" then return false end
    for index = 1, #Service.Listeners do
        if Service.Listeners[index] == listener then return true end
    end
    if #Service.Listeners >= Service.MAX_LISTENERS then return false end
    Service.Listeners[#Service.Listeners + 1] = listener
    return true
end

function Service.UnregisterListener(listener)
    if type(listener) ~= "function" then return false end
    for index = #Service.Listeners, 1, -1 do
        if Service.Listeners[index] == listener then
            table.remove(Service.Listeners, index)
            return true
        end
    end
    return false
end

local function policyIndex(name)
    for index = 1, #Service.Policies do
        if Service.Policies[index].name == name then return index end
    end
    return nil
end

-- External systems may contribute a bounded departure policy. The callback
-- returns a generic excursion specification; Hoomans remains responsible for
-- home identity, participant safety, travel, arrival, and return.
function Service.RegisterDeparturePolicy(name, policy)
    name = tostring(name or "")
    if name == "" or #name > 96 or type(policy) ~= "function" then
        return false, "policy_invalid"
    end
    local index = policyIndex(name)
    if index then
        Service.Policies[index].policy = policy
        return true, "policy_replaced"
    end
    if #Service.Policies >= Service.MAX_POLICIES then
        diagnostic("registration", name, "policy_limit")
        return false, "policy_limit"
    end
    Service.Policies[#Service.Policies + 1] = {
        name = name,
        policy = policy,
    }
    return true, "policy_registered"
end

function Service.UnregisterDeparturePolicy(name)
    local index = policyIndex(tostring(name or ""))
    if not index then return false end
    table.remove(Service.Policies, index)
    return true
end

function Service.GetPolicyDiagnostics(limit)
    local output = {}
    local requested = math.max(0, math.floor(tonumber(limit)
        or #Service.PolicyDiagnostics))
    local first = math.max(1, #Service.PolicyDiagnostics - requested + 1)
    for index = first, #Service.PolicyDiagnostics do
        output[#output + 1] = copy(Service.PolicyDiagnostics[index])
    end
    return output
end

function Service.GetListenerDiagnostics(limit)
    local output = {}
    local requested = math.max(0, math.floor(tonumber(limit)
        or #Service.ListenerDiagnostics))
    local first = math.max(1, #Service.ListenerDiagnostics - requested + 1)
    for index = first, #Service.ListenerDiagnostics do
        output[#output + 1] = copy(Service.ListenerDiagnostics[index])
    end
    return output
end

function Service.Get(factionID)
    local faction = factionRecord(factionID)
    local excursion = faction and faction.excursion
    if not excursion then return nil, "excursion_not_found" end
    return copy(excursion)
end

function Service.GetPublicStatus(factionID, _viewer)
    local excursion, reason = Service.Get(factionID)
    if not excursion then return nil, reason end
    return publicStatus(excursion)
end

-- Semantic and social consumers use this projection instead of receiving the
-- authoritative route record. Home-faction members may know the rough
-- destination and expected return; outsiders receive only the public phase,
-- purpose, and reason, never privileged route data.
function Service.GetSocialStatus(factionID, viewer)
    local excursion, reason = Service.Get(factionID)
    if not excursion then return nil, reason end
    return socialStatus(excursion, viewer)
end

function Service.GetNPCSocialStatus(npcID, viewer)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcID or "")) or nil
    local factionID = record and record.affiliation
        and record.affiliation.factionID or nil
    if not factionID then return nil, "npc_faction_missing" end
    return Service.GetSocialStatus(factionID, viewer)
end

-- Bounded community-level social projection for local knowledge systems. It
-- reports only active excursions whose persisted home is this community; it
-- never scans settlements or resolves routes on behalf of the caller.
function Service.GetCommunityAbsences(communityID, viewer, limit)
    local output = {}
    local requested = math.max(1, math.min(
        Service.MAX_RECONCILE,
        math.floor(tonumber(limit) or Service.MAX_RECONCILE)
    ))
    local registry = Factions and Factions.Registry
        and Factions.Registry.byID or {}
    for factionID, faction in pairs(registry) do
        if #output >= requested then break end
        local excursion = faction and faction.excursion
        if excursion
            and tostring(excursion.homeCommunityID or "")
                == tostring(communityID or "")
            and excursion.state ~= Constants.EXCURSION_STATE_AT_HOME
            and excursion.state ~= Constants.EXCURSION_STATE_FAILED
        then
            local normalized = normalizeExcursion(excursion)
            if normalized then
                local status = socialStatus(normalized, viewer)
                status.factionID = factionID
                output[#output + 1] = status
            end
        end
    end
    table.sort(output, function(left, right)
        return tostring(left.factionID) < tostring(right.factionID)
    end)
    return output
end

-- A bounded semantic context keeps wording in the semantic realization layer:
-- this service exposes facts, not a Dynamic Trading sentence or a movement
-- command.
function Service.GetSemanticContext(factionID, viewer)
    local status, reason = Service.GetSocialStatus(factionID, viewer)
    if not status then return nil, reason end
    return {
        source = "community_excursion",
        authoritative = true,
        status = status.status,
        phase = status.phase,
        state = status.state,
        locationState = status.locationState,
        purpose = status.purpose,
        visitIntent = status.visitIntent,
        reason = status.reason,
        publicReason = status.publicReason,
        destination = status.destination,
        destinationCommunityID = status.destinationCommunityID,
        destinationKnown = status.destinationKnown,
        expectedReturnAt = status.expectedReturnAt,
        expectedReturnKnown = status.expectedReturnKnown,
        homeCommunityID = status.homeCommunityID,
        revision = status.revision,
    }
end

local function requestEvaluatorIndex(name)
    for index = 1, #Service.RequestEvaluators do
        if Service.RequestEvaluators[index].name == name then
            return index
        end
    end
    return nil
end

function Service.RegisterRequestEvaluator(name, evaluator)
    name = tostring(name or "")
    if name == "" or #name > 96 or type(evaluator) ~= "function" then
        return false, "request_evaluator_invalid"
    end
    local index = requestEvaluatorIndex(name)
    if index then
        Service.RequestEvaluators[index].evaluator = evaluator
        return true, "request_evaluator_replaced"
    end
    if #Service.RequestEvaluators >= Service.MAX_REQUEST_EVALUATORS then
        requestDiagnostic("registration", name, "request_evaluator_limit")
        return false, "request_evaluator_limit"
    end
    Service.RequestEvaluators[#Service.RequestEvaluators + 1] = {
        name = name,
        evaluator = evaluator,
    }
    return true, "request_evaluator_registered"
end

function Service.UnregisterRequestEvaluator(name)
    local index = requestEvaluatorIndex(tostring(name or ""))
    if not index then return false end
    table.remove(Service.RequestEvaluators, index)
    return true
end

function Service.GetRequestDiagnostics(limit)
    local output = {}
    local requested = math.max(0, math.floor(tonumber(limit)
        or #Service.RequestDiagnostics))
    local first = math.max(1, #Service.RequestDiagnostics - requested + 1)
    for index = first, #Service.RequestDiagnostics do
        output[#output + 1] = copy(Service.RequestDiagnostics[index])
    end
    return output
end

-- Submit a suggestion/request for AI evaluation. No evaluator is allowed to
-- start travel directly: it returns only accepted/rejected/deferred status,
-- leaving a separate departure policy to decide whether a later excursion is
-- worthwhile, safe, and available.
function Service.SubmitRequest(request, at, context)
    local normalized
    local factionID
    local faction
    local target
    local evaluator
    local ok
    local result
    local reason
    local status
    request = type(request) == "table" and request or {}
    factionID = safeText(request.homeFactionID or request.factionID,
        Constants.ID_MAX_LENGTH)
    if not factionID then return nil, "home_faction_required" end
    faction = factionRecord(factionID)
    if not faction or faction.status ~= "active" then
        return nil, "home_faction_missing"
    end
    target = normalizeTarget(request.destination or request.target)
    if not target or not target.communityID then
        return nil, "destination_required"
    end
    normalized = {
        id = safeText(request.id, Constants.ID_MAX_LENGTH * 2),
        homeFactionID = factionID,
        homeCommunityID = safeText(
            request.homeCommunityID, Constants.ID_MAX_LENGTH),
        requesterFactionID = safeText(
            request.requesterFactionID, Constants.ID_MAX_LENGTH),
        purpose = safeText(request.purpose,
            Constants.EXCURSION_MAX_PURPOSE_LENGTH or 96) or "general",
        visitIntent = safeText(request.visitIntent or request.intent,
            Constants.EXCURSION_MAX_INTENT_LENGTH
                or Constants.MOBILE_SETTLEMENT_VISIT_INTENT_MAX_LENGTH
                or 96)
            or Constants.MOBILE_SETTLEMENT_VISIT_INTENT_GENERAL,
        destination = target,
        submittedAt = worldAge(at),
    }
    evaluator = requestEvaluatorIndex(normalized.visitIntent)
    if not evaluator then
        return {
            status = "deferred",
            reason = "no_request_evaluator",
            request = copy(normalized),
        }, "deferred"
    end
    evaluator = Service.RequestEvaluators[evaluator]
    ok, result, reason = pcall(
        evaluator.evaluator, copy(normalized), normalized.submittedAt, context)
    if not ok then
        requestDiagnostic("evaluation", evaluator.name, result)
        return {
            status = "deferred",
            reason = "request_evaluation_failed",
            request = copy(normalized),
        }, "deferred"
    end
    if result == false then
        return {
            status = "rejected",
            reason = tostring(reason or "request_rejected"),
            request = copy(normalized),
        }, "rejected"
    end
    if type(result) == "table" then
        result.request = result.request or copy(normalized)
        status = result.status
        if status ~= "accepted" and status ~= "rejected"
            and status ~= "deferred"
        then
            status = "deferred"
        end
        result.status = status
        return result, status
    end
    return {
        status = "deferred",
        reason = "request_deferred",
        request = copy(normalized),
    }, "deferred"
end

function Service.GetNPCStatus(npcID, viewer)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcID or "")) or nil
    local factionID = record and record.affiliation
        and record.affiliation.factionID or nil
    if not factionID then return nil, "npc_faction_missing" end
    return Service.GetSocialStatus(factionID, viewer)
end

function Service.ResolveHome(factionID)
    local excursion, reason = Service.Get(factionID)
    if not excursion then return nil, reason end
    return activeHome(excursion)
end

function Service.Create(spec, at)
    if not authority() then return nil, "not_authority" end
    spec = type(spec) == "table" and spec or {}
    local homeFactionID = safeText(spec.homeFactionID,
        Constants.ID_MAX_LENGTH)
    local homeCommunityID = safeText(spec.homeCommunityID,
        Constants.ID_MAX_LENGTH)
    local faction
    local community
    local participants
    local itinerary
    local excursion
    local existing
    if not homeFactionID or not homeCommunityID then
        return nil, "home_identity_required"
    end
    faction = factionRecord(homeFactionID)
    if not faction then return nil, "home_faction_missing" end
    community = Communities and Communities.Get
        and Communities.Get(homeCommunityID) or nil
    if type(community) ~= "table" then
        return nil, "home_community_missing"
    end
    if community.status ~= "active"
        or tostring(community.factionID or "") ~= homeFactionID
    then
        return nil, "home_identity_invalid"
    end
    existing = faction.excursion
    if existing then
        return copy(existing), "excursion_exists"
    end
    participants = normalizeParticipants(spec.participants)
    if #participants < 1 then return nil, "participants_required" end
    if Factions and type(Factions.IsMember) == "function" then
        for index = 1, #participants do
            if not Factions.IsMember(homeFactionID, participants[index]) then
                return nil, "participant_not_home_member"
            end
        end
    end
    itinerary = normalizeItinerary(spec.itinerary)
    excursion = normalizeExcursion({
        id = safeText(spec.id, Constants.ID_MAX_LENGTH * 2)
            or homeFactionID .. ":excursion:"
                .. tostring((tonumber(faction.revision) or 0) + 1),
        homeFactionID = homeFactionID,
        homeCommunityID = homeCommunityID,
        state = Constants.EXCURSION_STATE_AT_HOME,
        purpose = safeText(spec.purpose,
            Constants.EXCURSION_MAX_PURPOSE_LENGTH or 96) or "general",
        visitIntent = safeText(spec.visitIntent or spec.intent,
            Constants.EXCURSION_MAX_INTENT_LENGTH
                or Constants.MOBILE_SETTLEMENT_VISIT_INTENT_MAX_LENGTH
                or 96)
            or Constants.MOBILE_SETTLEMENT_VISIT_INTENT_GENERAL,
        publicReason = safeText(spec.publicReason,
            Constants.EXCURSION_MAX_REASON_LENGTH or 128),
        participants = participants,
        itinerary = itinerary,
        createdAt = worldAge(at),
        stateAt = worldAge(at),
        revision = 1,
    })
    if not excursion then return nil, "excursion_normalization_failed" end
    faction.excursion = excursion
    touch(faction, "community_excursion_created")
    notify(homeFactionID, excursion, "created")
    return copy(excursion), "created"
end

local function applyPreparation(excursion, patch)
    patch = type(patch) == "table" and patch or {}
    if patch.purpose ~= nil then
        excursion.purpose = safeText(patch.purpose,
            Constants.EXCURSION_MAX_PURPOSE_LENGTH or 96)
            or excursion.purpose
    end
    if patch.visitIntent ~= nil or patch.intent ~= nil then
        excursion.visitIntent = safeText(
            patch.visitIntent or patch.intent,
            Constants.EXCURSION_MAX_INTENT_LENGTH
                or Constants.MOBILE_SETTLEMENT_VISIT_INTENT_MAX_LENGTH
                or 96
        ) or excursion.visitIntent
    end
    if patch.publicReason ~= nil then
        excursion.publicReason = safeText(patch.publicReason,
            Constants.EXCURSION_MAX_REASON_LENGTH or 128)
    end
    if patch.participants ~= nil then
        excursion.participants = normalizeParticipants(patch.participants)
    end
    if patch.itinerary ~= nil then
        excursion.itinerary = normalizeItinerary(patch.itinerary)
    end
end

local function transitionAllowed(current, nextState)
    return TRANSITIONS[current] and TRANSITIONS[current][nextState] == true
end

function Service.SetPhase(factionID, nextState, patch, at)
    if not authority() then return false, "not_authority" end
    if not Constants.EXCURSION_STATES[nextState] then
        return false, "invalid_excursion_state"
    end
    local faction = factionRecord(factionID)
    local excursion = faction and faction.excursion
    if not faction or not excursion then return false, "excursion_not_found" end
    local current = excursion.state
    if current == nextState then
        return true, "unchanged", publicStatus(excursion)
    end
    if not transitionAllowed(current, nextState) then
        return false, "invalid_excursion_transition"
    end
    patch = type(patch) == "table" and patch or {}
    if (current == Constants.EXCURSION_STATE_AT_HOME
        or current == Constants.EXCURSION_STATE_FAILED)
        and nextState == Constants.EXCURSION_STATE_PREPARING
    then
        applyPreparation(excursion, patch)
        if #excursion.participants < 1 then
            return false, "participants_required"
        end
    end
    if nextState == Constants.EXCURSION_STATE_OUTBOUND then
        local destination = normalizeTarget(patch.destination
            or excursion.destination
            or excursion.itinerary[excursion.currentLeg + 1])
        if not destination then return false, "destination_required" end
        excursion.destination = destination
        if patch.expectedReturnAt ~= nil then
            excursion.expectedReturnAt = worldAge(patch.expectedReturnAt)
        end
    elseif patch.expectedReturnAt ~= nil then
        excursion.expectedReturnAt = worldAge(patch.expectedReturnAt)
    elseif patch.destination ~= nil then
        excursion.destination = normalizeTarget(patch.destination)
    end
    if patch.currentLeg ~= nil then
        excursion.currentLeg = math.max(0, math.floor(
            tonumber(patch.currentLeg) or excursion.currentLeg
        ))
    end
    excursion.state = nextState
    excursion.stateAt = worldAge(at)
    excursion.revision = math.max(0, math.floor(
        tonumber(excursion.revision) or 0
    )) + 1
    if nextState == Constants.EXCURSION_STATE_PREPARING then
        excursion.preparedAt = excursion.stateAt
        excursion.failure = nil
    elseif nextState == Constants.EXCURSION_STATE_OUTBOUND then
        excursion.departedAt = excursion.stateAt
    elseif nextState == Constants.EXCURSION_STATE_VISITING then
        excursion.visitedAt = excursion.stateAt
    elseif nextState == Constants.EXCURSION_STATE_RETURNING_HOME then
        excursion.returnStartedAt = excursion.stateAt
        excursion.destination = nil
    elseif nextState == Constants.EXCURSION_STATE_AT_HOME then
        excursion.completedAt = excursion.stateAt
        excursion.destination = nil
        excursion.expectedReturnAt = 0
        excursion.currentLeg = 0
        excursion.failure = nil
    elseif nextState == Constants.EXCURSION_STATE_FAILED then
        excursion.failure = {
            code = safeText(patch.failureReason or patch.reason,
                Constants.EXCURSION_MAX_REASON_LENGTH or 128)
                or "excursion_failed",
            at = excursion.stateAt,
            retryAt = worldAge(patch.retryAt),
        }
    end
    excursion.publicReason = patch.publicReason ~= nil
        and safeText(patch.publicReason,
            Constants.EXCURSION_MAX_REASON_LENGTH or 128)
        or excursion.publicReason
    excursion = normalizeExcursion(excursion)
    if not excursion then return false, "excursion_normalization_failed" end
    faction.excursion = excursion
    touch(faction, "community_excursion_phase_changed")
    notify(factionID, excursion, "phase_changed")
    return true, "phase_changed", publicStatus(excursion)
end

function Service.Begin(factionID, spec, at)
    local existing = factionRecord(factionID)
    local created
    local reason
    if not existing or not existing.excursion then
        spec = type(spec) == "table" and copy(spec) or {}
        spec.homeFactionID = spec.homeFactionID or factionID
        created, reason = Service.Create(spec, at)
        if not created then return nil, reason end
    end
    local prepared, prepareReason = Service.SetPhase(
        factionID,
        Constants.EXCURSION_STATE_PREPARING,
        spec,
        at
    )
    if not prepared then return nil, prepareReason end
    return Service.Get(factionID)
end

function Service.StartOutbound(factionID, destination, at, expectedReturnAt)
    return Service.SetPhase(factionID, Constants.EXCURSION_STATE_OUTBOUND, {
        destination = destination,
        expectedReturnAt = expectedReturnAt,
    }, at)
end

function Service.StartVisiting(factionID, at, patch)
    return Service.SetPhase(
        factionID, Constants.EXCURSION_STATE_VISITING, patch, at)
end

function Service.StartReturningHome(factionID, at)
    return Service.SetPhase(
        factionID, Constants.EXCURSION_STATE_RETURNING_HOME, nil, at)
end

function Service.CompleteReturn(factionID, at)
    local excursion, reason = Service.Get(factionID)
    if not excursion then return false, reason end
    local home, homeReason = activeHome(excursion)
    if not home then
        return Service.Fail(factionID, homeReason, at)
    end
    return Service.SetPhase(
        factionID, Constants.EXCURSION_STATE_AT_HOME, nil, at)
end

function Service.Fail(factionID, reason, at, retryAt)
    return Service.SetPhase(factionID, Constants.EXCURSION_STATE_FAILED, {
        failureReason = reason,
        retryAt = retryAt,
    }, at)
end

function Service.Retry(factionID, at, patch)
    local excursion, reason = Service.Get(factionID)
    if not excursion then return false, reason end
    if excursion.state ~= Constants.EXCURSION_STATE_FAILED then
        return false, "excursion_not_failed"
    end
    return Service.SetPhase(
        factionID,
        Constants.EXCURSION_STATE_PREPARING,
        patch,
        at
    )
end

local function travelAPI()
    return PNC.API and PNC.API.Travel or nil
end

local function npcRecord(npcID)
    return PNC.Registry and type(PNC.Registry.Get) == "function"
        and PNC.Registry.Get(tostring(npcID or "")) or nil
end

local function activeTravel(record)
    local model = PNC.Travel and PNC.Travel.Model or nil
    if model and type(model.IsActive) == "function" then
        return model.IsActive(record and record.travel)
    end
    local state = record and record.travel and record.travel.state
    return state == "planned" or state == "en_route"
        or state == "waiting" or state == "paused"
end

local function participantAtHome(record, excursion, community)
    local affiliation = record and record.affiliation or nil
    local home = community and community.home or nil
    local radius = tonumber(home and home.radius) or 16
    local dx = tonumber(record and record.x or 0)
        - tonumber(home and home.x or 0)
    local dy = tonumber(record and record.y or 0)
        - tonumber(home and home.y or 0)
    if not record or record.alive == false then
        return false, "participant_unavailable"
    end
    if tostring(affiliation and affiliation.factionID or "")
        ~= tostring(excursion.homeFactionID or "")
    then
        return false, "participant_faction_changed"
    end
    if tostring(affiliation and affiliation.communityID or "")
        ~= tostring(excursion.homeCommunityID or "")
    then
        return false, "participant_home_community_changed"
    end
    if activeTravel(record) then return false, "participant_already_traveling" end
    if dx * dx + dy * dy > radius * radius * 4 then
        return false, "participant_not_at_home"
    end
    return true
end

local function protectedTask(record)
    local runtime = record and record.runtime or nil
    local order = record and record.orderSpec or nil
    if PNC.Travel and PNC.Travel.Service
        and type(PNC.Travel.Service.IsFollowOwned) == "function"
        and PNC.Travel.Service.IsFollowOwned(record)
    then
        return "FOLLOWING_PLAYER"
    end
    if order and (order.kind == "facility_activity"
        or order.kind == "work"
        or order.kind == "task"
    ) then
        return "PROTECTED_TASK"
    end
    if runtime and (runtime.facilityActivity
        or runtime.workOrderId
        or runtime.taskLeaseId
        or runtime.attackAction
        or runtime.combatTarget
    ) then
        return "PROTECTED_TASK"
    end
    if record and (record.activeJob or record.activeBehavior) then
        return "PROTECTED_TASK"
    end
    return nil
end

function Service.CanParticipantDepart(factionID, npcID)
    local excursion = Service.Get(factionID)
    if not excursion then return false, "excursion_not_found" end
    return Service.CanParticipantDepartForCommunity(
        factionID, npcID, excursion.homeCommunityID)
end

-- Preflight for a departure policy before an excursion record exists. The
-- policy receives no authority to move the NPC; it only asks Hoomans whether
-- the participant is at its exact home and free of protected obligations.
function Service.CanParticipantDepartForCommunity(
    factionID, npcID, communityID
)
    local home = Communities and Communities.Get
        and Communities.Get(communityID) or nil
    local faction = factionRecord(factionID)
    local record = npcRecord(npcID)
    local synthetic
    local allowed
    local reason
    if not faction or faction.status ~= "active" then
        return false, "home_faction_missing"
    end
    if not home or home.status ~= "active"
        or tostring(home.factionID or "") ~= tostring(factionID or "")
    then
        return false, "home_community_invalid"
    end
    synthetic = {
        homeFactionID = factionID,
        homeCommunityID = communityID,
    }
    allowed, reason = participantAtHome(record, synthetic, home)
    if not allowed then return false, reason end
    reason = protectedTask(record)
    if reason then return false, reason end
    return true, "eligible"
end

local function homeTarget(community)
    local home = community and community.home or nil
    if type(home) ~= "table"
        or tonumber(home.x) == nil or tonumber(home.y) == nil
    then
        return nil, "home_location_missing"
    end
    return {
        kind = "settlement",
        locationID = community.siteID or community.id,
        communityID = community.id,
        siteID = community.siteID,
        factionID = community.factionID,
        x = tonumber(home.x),
        y = tonumber(home.y),
        z = tonumber(home.z) or 0,
        radius = tonumber(home.radius) or 16,
    }
end

local function destinationTarget(excursion, destination)
    local target = normalizeTarget(destination
        or excursion and excursion.destination
        or excursion and excursion.itinerary
            and excursion.itinerary[(excursion.currentLeg or 0) + 1])
    if not target then return nil, "destination_required" end
    if not target.communityID then return nil, "destination_community_required" end
    if target.x == nil or target.y == nil then
        local community = Communities and Communities.Get
            and Communities.Get(target.communityID) or nil
        local resolved, reason = homeTarget(community)
        if not resolved then return nil, reason end
        target.x = resolved.x
        target.y = resolved.y
        target.z = resolved.z
        target.locationID = target.locationID or resolved.locationID
    end
    return target
end

local function participantTravelRequest(excursion, target, npcID, actionType)
    return {
        destination = {
            x = target.x,
            y = target.y,
            z = target.z,
        },
        ownerMod = "ProjectHoomans",
        ownerRef = "community_excursion:" .. tostring(excursion.homeFactionID),
        visibility = "all",
        metadata = {
            excursionID = excursion.id,
            homeCommunityID = excursion.homeCommunityID,
            destinationCommunityID = target.communityID,
            participantID = tostring(npcID),
        },
        arrivalAction = {
            type = actionType,
            excursionID = excursion.id,
            homeFactionID = excursion.homeFactionID,
            homeCommunityID = excursion.homeCommunityID,
            destinationCommunityID = target.communityID,
            destinationLocationID = target.locationID,
            intent = excursion.visitIntent,
        },
    }
end

local function excursionTarget(factionID, excursion, action)
    local target = {
        kind = "settlement",
        locationID = action and action.destinationLocationID
            or excursion.destination and excursion.destination.locationID,
        communityID = action and action.destinationCommunityID
            or excursion.destination and excursion.destination.communityID,
        x = excursion.destination and excursion.destination.x,
        y = excursion.destination and excursion.destination.y,
        z = excursion.destination and excursion.destination.z,
    }
    return destinationTarget(excursion, target)
end

local function exactHomeArrival(excursion, action, journey)
    local community = activeHome(excursion)
    local destination = journey and journey.destination or nil
    if not community then return false, "home_community_missing" end
    if tostring(action and action.homeCommunityID or "")
        ~= tostring(excursion.homeCommunityID or "")
    then
        return false, "home_identity_mismatch"
    end
    if tostring(action and action.destinationCommunityID or "")
        ~= tostring(excursion.homeCommunityID or "")
    then
        return false, "home_destination_mismatch"
    end
    if type(destination) ~= "table" then
        return false, "home_destination_missing"
    end
    return true, community
end

function Service.StartParticipantOutbound(factionID, destination, at, options)
    local excursion = Service.Get(factionID)
    local target
    local api = travelAPI()
    local stateResult
    local stateReason
    local expectedReturnAt
    local started
    local reason
    local index
    local npcID
    local record
    local canDepart
    if not excursion then return false, "excursion_not_found" end
    if excursion.state ~= Constants.EXCURSION_STATE_PREPARING
        and excursion.state ~= Constants.EXCURSION_STATE_OUTBOUND
    then
        return false, "excursion_not_preparing"
    end
    target, reason = destinationTarget(excursion, destination)
    if not target then return false, reason end
    options = type(options) == "table" and options or {}
    expectedReturnAt = tonumber(options.expectedReturnAt)
        or tonumber(excursion.expectedReturnAt)
        or worldAge(at) + (tonumber(options.visitHours) or 12)
    for index = 1, #excursion.participants do
        npcID = excursion.participants[index]
        record = npcRecord(npcID)
        if not activeTravel(record) then
            canDepart, reason = Service.CanParticipantDepart(factionID, npcID)
            if not canDepart then return false, reason end
        end
    end
    if excursion.state == Constants.EXCURSION_STATE_PREPARING then
        stateResult, stateReason = Service.StartOutbound(
            factionID, target, at, expectedReturnAt)
        if not stateResult then return false, stateReason end
        excursion = Service.Get(factionID)
    end
    if not api or type(api.Start) ~= "function" then
        Service.Fail(factionID, "travel_api_unavailable", at)
        return false, "travel_api_unavailable"
    end
    for index = 1, #excursion.participants do
        npcID = excursion.participants[index]
        record = npcRecord(npcID)
        if not activeTravel(record) then
            started, reason = api.Start(
                npcID,
                participantTravelRequest(
                    excursion,
                    target,
                    npcID,
                    EXCURSION_SETTLEMENT_ARRIVAL
                )
            )
            if not started then
                Service.Fail(factionID, reason or "travel_start_failed", at)
                return false, reason or "travel_start_failed"
            end
        end
    end
    return true, "participant_excursion_outbound", Service.Get(factionID)
end

function Service.StartParticipantReturn(factionID, at)
    local excursion = Service.Get(factionID)
    local home
    local target
    local api = travelAPI()
    local stateResult
    local stateReason
    local started
    local reason
    local index
    local npcID
    local record
    if not excursion then return false, "excursion_not_found" end
    home = activeHome(excursion)
    if not home then return false, "home_community_missing" end
    target, reason = homeTarget(home)
    if not target then return false, reason end
    if excursion.state == Constants.EXCURSION_STATE_VISITING then
        stateResult, stateReason = Service.StartReturningHome(factionID, at)
        if not stateResult then return false, stateReason end
        excursion = Service.Get(factionID)
    elseif excursion.state ~= Constants.EXCURSION_STATE_RETURNING_HOME then
        return false, "excursion_not_visiting"
    end
    if not api or type(api.Start) ~= "function" then
        Service.Fail(factionID, "travel_api_unavailable", at)
        return false, "travel_api_unavailable"
    end
    for index = 1, #excursion.participants do
        npcID = excursion.participants[index]
        record = npcRecord(npcID)
        if not activeTravel(record) then
            started, reason = api.Start(
                npcID,
                participantTravelRequest(
                    excursion,
                    target,
                    npcID,
                    EXCURSION_HOME_ARRIVAL
                )
            )
            if not started then
                Service.Fail(factionID, reason or "home_travel_failed", at)
                return false, reason or "home_travel_failed"
            end
        end
    end
    return true, "participant_excursion_returning", Service.Get(factionID)
end

function Service.BeginParticipantExcursion(spec, at)
    spec = type(spec) == "table" and copy(spec) or {}
    local factionID = spec.homeFactionID
    local started, reason
    local target
    if not factionID then return false, "home_faction_required" end
    target, reason = destinationTarget({
        destination = spec.destination,
        itinerary = spec.itinerary,
        currentLeg = 0,
    }, spec.destination)
    if not target then return false, reason end
    spec.destination = target
    spec.itinerary = spec.itinerary or { target }
    started, reason = Service.Begin(factionID, spec, at)
    if not started then return false, reason end
    return Service.StartParticipantOutbound(
        factionID,
        target,
        at,
        { expectedReturnAt = spec.expectedReturnAt }
    )
end

local function onSettlementArrival(record, journey, action)
    local factionID = action and action.homeFactionID
    local excursion = factionID and Service.Get(factionID) or nil
    local target
    local eligible
    local reason
    local visitService = PNC.MobileSettlementVisitService
    local at = journey and (journey.arrivedWorldHour
        or journey.lastAdvancedWorldHour) or worldAge()
    if not excursion then return false, "excursion_not_found" end
    if excursion.id ~= action.excursionID then
        return false, "excursion_identity_mismatch"
    end
    if excursion.state == Constants.EXCURSION_STATE_VISITING then
        return true, "excursion_visit_duplicate"
    end
    if excursion.state ~= Constants.EXCURSION_STATE_OUTBOUND then
        return false, "excursion_not_outbound"
    end
    target, reason = excursionTarget(factionID, excursion, action)
    if not target then
        Service.Fail(factionID, reason, at)
        return true, "excursion_visit_failed"
    end
    if not visitService
        or type(visitService.IsSettlementVisitEligible) ~= "function"
    then
        Service.Fail(factionID, "settlement_visit_service_unavailable", at)
        return true, "excursion_visit_failed"
    end
    eligible, reason = visitService.IsSettlementVisitEligible(
        factionID,
        target,
        at,
        { allowResident = true }
    )
    if not eligible then
        Service.Fail(factionID, reason, at)
        return true, "excursion_visit_failed"
    end
    local visiting, visitingReason = Service.StartVisiting(
        factionID,
        at,
        {
            expectedReturnAt = math.max(
                at + 0.01,
                tonumber(excursion.expectedReturnAt) or at + 12
            ),
        }
    )
    if not visiting then return false, visitingReason end
    return true, "excursion_visit_started"
end

local function onHomeArrival(record, journey, action)
    local factionID = action and action.homeFactionID
    local excursion = factionID and Service.Get(factionID) or nil
    local valid
    local result
    local reason
    if not excursion then return false, "excursion_not_found" end
    if excursion.id ~= action.excursionID then
        return false, "excursion_identity_mismatch"
    end
    if excursion.state == Constants.EXCURSION_STATE_AT_HOME then
        return true, "excursion_home_duplicate"
    end
    if excursion.state ~= Constants.EXCURSION_STATE_RETURNING_HOME then
        return false, "excursion_not_returning"
    end
    valid, reason = exactHomeArrival(excursion, action, journey)
    if not valid then
        Service.Fail(factionID, reason, worldAge())
        return true, "excursion_home_failed"
    end
    result, reason = Service.CompleteReturn(factionID, worldAge())
    return result, reason
end

function Service.RegisterTravelHandlers()
    local arrivals = PNC.Travel and PNC.Travel.Arrivals or nil
    if not arrivals or type(arrivals.RegisterHandler) ~= "function" then
        return false, "travel_arrival_api_unavailable"
    end
    if not Service.TravelHandlersRegistered then
        arrivals.RegisterHandler(EXCURSION_SETTLEMENT_ARRIVAL,
            onSettlementArrival)
        arrivals.RegisterHandler(EXCURSION_HOME_ARRIVAL, onHomeArrival)
        if type(arrivals.StrictActionTypes) == "table" then
            arrivals.StrictActionTypes[EXCURSION_SETTLEMENT_ARRIVAL] = true
            arrivals.StrictActionTypes[EXCURSION_HOME_ARRIVAL] = true
        end
        Service.TravelHandlersRegistered = true
    end
    return true
end

function Service.PumpPolicies(at, budget)
    local factionIDs = {}
    local processed = 0
    local started = 0
    local scanLimit
    if not authority() or not Factions or not Factions.Registry then return 0 end
    budget = math.max(1, math.min(
        Service.MAX_RECONCILE,
        math.floor(tonumber(budget) or 4)
    ))
    scanLimit = math.max(budget, budget * 4)
    for factionID, faction in pairs(Factions.Registry.byID or {}) do
        if #factionIDs >= scanLimit then break end
        if faction.status == "active" and not faction.mobile then
            factionIDs[#factionIDs + 1] = factionID
        end
    end
    table.sort(factionIDs)
    for index = 1, #factionIDs do
        if processed >= budget then break end
        local faction = factionRecord(factionIDs[index])
        for policyIndexValue = 1, #Service.Policies do
            if started >= budget then break end
            local registration = Service.Policies[policyIndexValue]
            local ok, result, policyReason = pcall(
                registration.policy,
                copy(faction),
                worldAge(at)
            )
            if not ok then
                diagnostic("policy", registration.name, result)
            elseif result == false then
                diagnostic("policy", registration.name, policyReason)
            elseif type(result) == "table" and result.start == true then
                local excursionStarted, startReason =
                    Service.BeginParticipantExcursion(result, at)
                if excursionStarted then
                    started = started + 1
                else
                    diagnostic("policy_start", registration.name, startReason)
                end
            end
        end
        processed = processed + 1
    end
    return started
end

function Service.ReconcileAll(at, budget)
    if not authority() then return 0 end
    if not Factions or not Factions.Registry then return 0 end
    Service.RegisterTravelHandlers()
    budget = math.max(1, math.min(
        Service.MAX_RECONCILE,
        math.floor(tonumber(budget) or Service.MAX_RECONCILE)
    ))
    local processed = 0
    for factionID, faction in pairs(Factions.Registry.byID or {}) do
        if processed >= budget then break end
        if faction.excursion then
            processed = processed + 1
            local excursion = normalizeExcursion(faction.excursion)
            if not excursion then
                Service.Fail(factionID, "excursion_state_invalid", at)
            else
                faction.excursion = excursion
                if excursion.state ~= Constants.EXCURSION_STATE_AT_HOME
                    and excursion.state ~= Constants.EXCURSION_STATE_FAILED
                then
                    local _, homeReason = activeHome(excursion)
                    if homeReason then
                        Service.Fail(factionID, homeReason, at)
                    elseif excursion.state
                        == Constants.EXCURSION_STATE_VISITING
                        and (tonumber(excursion.expectedReturnAt) or 0)
                            <= worldAge(at)
                    then
                        Service.StartParticipantReturn(factionID, at)
                    elseif excursion.state
                        == Constants.EXCURSION_STATE_OUTBOUND
                    then
                        local hasTravel = false
                        for participantIndex = 1, #excursion.participants do
                            if activeTravel(npcRecord(
                                excursion.participants[participantIndex]
                            )) then
                                hasTravel = true
                                break
                            end
                        end
                        if not hasTravel then
                            Service.StartParticipantOutbound(
                                factionID,
                                excursion.destination,
                                at
                            )
                        end
                    elseif excursion.state
                        == Constants.EXCURSION_STATE_RETURNING_HOME
                    then
                        local hasTravel = false
                        for participantIndex = 1, #excursion.participants do
                            if activeTravel(npcRecord(
                                excursion.participants[participantIndex]
                            )) then
                                hasTravel = true
                                break
                            end
                        end
                        if not hasTravel then
                            Service.StartParticipantReturn(factionID, at)
                        end
                    end
                end
            end
        end
    end
    return processed
end

Service.RegisterTravelHandlers()

return Service
