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
local Internal = Factions and Factions.Internal or {}
local Core = PNC.Core

Service.VERSION = 1
Service.MAX_LISTENERS = 16
Service.MAX_RECONCILE = 32
Service.STATES = {
    AT_HOME = Constants.EXCURSION_STATE_AT_HOME,
    PREPARING = Constants.EXCURSION_STATE_PREPARING,
    OUTBOUND = Constants.EXCURSION_STATE_OUTBOUND,
    VISITING = Constants.EXCURSION_STATE_VISITING,
    RETURNING_HOME = Constants.EXCURSION_STATE_RETURNING_HOME,
    FAILED = Constants.EXCURSION_STATE_FAILED,
}
Service.Listeners = Service.Listeners or {}

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
    if Internal and type(Internal.authority) == "function" then
        return Internal.authority() == true
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

local function factionRecord(factionID)
    if Factions and type(Factions.EnsureLoaded) == "function" then
        Factions.EnsureLoaded()
    end
    if Internal and type(Internal.registryRecord) == "function" then
        return Internal.registryRecord(factionID)
    end
    return Factions and Factions.Registry
        and Factions.Registry.byID and Factions.Registry.byID[factionID]
        or nil
end

local function touch(faction, reason)
    if Internal and type(Internal.touchFaction) == "function" then
        Internal.touchFaction(faction)
    else
        faction.revision = math.max(0, math.floor(
            tonumber(faction.revision) or 0
        )) + 1
    end
    if Internal and type(Internal.touchRegistry) == "function" then
        Internal.touchRegistry()
    elseif Factions then
        Factions.Dirty = true
    end
end

local function normalizeTarget(target)
    local normalizer = Types and Types.Internal
        and Types.Internal.NormalizeTargetPoint or nil
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
    local normalizer = Types and Types.Internal
        and Types.Internal.NormalizeExcursion or nil
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

local function notify(factionID, excursion, reason)
    local payload = publicStatus(excursion)
    payload.factionID = factionID
    payload.reason = reason
    for index = 1, #Service.Listeners do
        -- External listeners are an observation boundary. Their failure must
        -- not interrupt authoritative faction state or traversal ownership.
        local ok, listenerReason = pcall(
            Service.Listeners[index], copy(payload))
        if not ok and Core and type(Core.LogWarn) == "function" then
            Core.LogWarn("community excursion listener failed index="
                .. tostring(index) .. " error=" .. tostring(listenerReason))
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

function Service.GetNPCStatus(npcID, viewer)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcID or "")) or nil
    local factionID = record and record.affiliation
        and record.affiliation.factionID or nil
    if not factionID then return nil, "npc_faction_missing" end
    return Service.GetPublicStatus(factionID, viewer)
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

function Service.StartVisiting(factionID, at)
    return Service.SetPhase(
        factionID, Constants.EXCURSION_STATE_VISITING, nil, at)
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

function Service.ReconcileAll(at, budget)
    if not authority() then return 0 end
    if not Factions or not Factions.Registry then return 0 end
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
                    end
                end
            end
        end
    end
    return processed
end

return Service
