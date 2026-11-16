-- Authoritative starter-customization handoff.
--
-- This service owns only the bounded customization handshake.  Spawn,
-- recruitment, relationship, knowledge, and faction/community behavior stay
-- in PNC.StartingCompanions.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.StartingCompanionCustomizationService =
    PNC.StartingCompanionCustomizationService or {}

local Service = PNC.StartingCompanionCustomizationService
local Customization = PNC.StartingCompanionCustomization
local Starting = PNC.StartingCompanions
local Traits = PNC.StartingCompanionTraits
local Registry = PNC.NPCAuthoringFieldRegistry

Service.VERSION = 1
Service.TIMEOUT_MS = 3000
Service.MAX_PENDING = 16
Service.MAX_PUMP_PER_TICK = 8
Service.PHASE_PENDING = "customization_pending"
Service.PHASE_RECEIVED = "customization_received"
Service.PHASE_VALIDATED = "customization_validated"
Service.PHASE_DEFAULTED = "defaulted"
Service.PHASE_GRANTS_COMPLETE = "grants_complete"
Service.Sessions = Service.Sessions or {}
Service.SessionOrder = Service.SessionOrder or {}

local function copy(value)
    return Registry and Registry.Copy and Registry.Copy(value) or value
end

local function now()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function worldAgeHours()
    local time = getGameTime and getGameTime() or nil
    if time and time.getWorldAgeHours then
        return math.max(0, tonumber(time:getWorldAgeHours()) or 0)
    end
    return 0
end

local function characterUUID(player)
    if not player or not PNC.PlayerCharacters
        or not PNC.PlayerCharacters.GetCharacterUUID
    then
        return nil
    end
    return PNC.PlayerCharacters.GetCharacterUUID(player)
end

local function stateSnapshot(state)
    if not state then return nil end
    return {
        characterUUID = state.characterUUID,
        phase = state.phase,
        createdAt = state.createdAt,
        deadlineAt = state.deadlineAt,
        receivedAt = state.receivedAt,
        validatedAt = state.validatedAt,
        defaultedAt = state.defaultedAt,
        grantsCompletedAt = state.grantsCompletedAt,
        reason = state.reason,
        attempts = state.attempts,
        selectedTraitIDs = copy(state.selectedTraitIDs or {}),
        envelopeFingerprint = state.envelopeFingerprint,
    }
end

local function removeFromOrder(characterUUIDValue)
    for index = #Service.SessionOrder, 1, -1 do
        if Service.SessionOrder[index] == characterUUIDValue then
            table.remove(Service.SessionOrder, index)
        end
    end
end

local function trimSessions()
    while #Service.SessionOrder > Service.MAX_PENDING do
        local oldest = table.remove(Service.SessionOrder, 1)
        if oldest then Service.Sessions[oldest] = nil end
    end
end

local function actualSelections(player)
    local selections
    local reason
    if not Traits or not Traits.ResolveSelections then
        return nil, "starting_traits_unavailable"
    end
    selections, reason = Traits.ResolveSelections(player)
    if not selections then return nil, reason or "traits_not_ready" end
    return selections
end

local function sendColonySnapshot(player)
    local builder
    if not player or not PNC.Network
        or not PNC.Network.SendColonyManagement
        or not PNC.ColonyManagement
    then
        return
    end
    builder = PNC.ColonyManagement.BuildBaseSnapshot
        or PNC.ColonyManagement.BuildSnapshot
    if not builder then return end
    PNC.Network.SendColonyManagement(
        player,
        builder(player),
        PNC.ColonyManagement.BuildBaseSnapshot and "base" or nil
    )
end

local function actualSelectionSet(selections)
    local output = {}
    for index = 1, #(selections or {}) do
        output[selections[index].id] = true
    end
    return output
end

local function newState(player, uuid, at)
    local state = {
        player = player,
        characterUUID = uuid,
        phase = Service.PHASE_PENDING,
        createdAt = at,
        deadlineAt = at + Service.TIMEOUT_MS,
        receivedAt = 0,
        validatedAt = 0,
        defaultedAt = 0,
        grantsCompletedAt = 0,
        reason = nil,
        attempts = 0,
        envelope = nil,
        decoded = nil,
        selectedTraitIDs = {},
        validatedBlueprints = nil,
        envelopeFingerprint = nil,
    }
    Service.Sessions[uuid] = state
    Service.SessionOrder[#Service.SessionOrder + 1] = uuid
    trimSessions()
    return state
end

local function defaultState(state, reason)
    if not state or state.phase == Service.PHASE_GRANTS_COMPLETE then
        return false, "grants_complete"
    end
    state.phase = Service.PHASE_DEFAULTED
    state.defaultedAt = now()
    state.reason = tostring(reason or "customization_defaulted")
    state.envelope = nil
    state.decoded = nil
    state.validatedBlueprints = nil
    return true, state.reason
end

local function validateReceived(state)
    local selections
    local reason
    local selectedSet
    local decoded
    local blueprints = {}
    local report
    local sanitized
    local slot
    local spec
    local traitID
    if not state or state.phase ~= Service.PHASE_RECEIVED then
        return false, "customization_not_received"
    end
    selections, reason = actualSelections(state.player)
    if not selections then return false, reason or "traits_not_ready" end
    selectedSet = actualSelectionSet(selections)
    decoded = state.decoded
    if not decoded then return false, "customization_payload_missing" end
    for index = 1, #decoded.selectedTraitIDs do
        traitID = decoded.selectedTraitIDs[index]
        if not selectedSet[traitID] then
            defaultState(state, "trait_not_selected:" .. tostring(traitID))
            return false, "trait_not_selected"
        end
    end
    for index = 1, #decoded.selectedTraitIDs do
        traitID = decoded.selectedTraitIDs[index]
        slot = decoded.blueprints[traitID]
        spec = Traits.GetDefinition(traitID)
        sanitized, report = Customization.SanitizeBlueprint(slot, spec)
        if not sanitized then
            defaultState(state, "blueprint_rejected:" .. tostring(report))
            return false, tostring(report)
        end
        blueprints[traitID] = sanitized
    end
    state.selectedTraitIDs = {}
    for index = 1, #selections do
        state.selectedTraitIDs[index] = selections[index].id
    end
    state.validatedBlueprints = blueprints
    state.phase = Service.PHASE_VALIDATED
    state.validatedAt = now()
    state.reason = "validated"
    return true, "validated"
end

local function ingest(state, envelope)
    local decoded
    local reason
    if not state then return false, "customization_state_missing" end
    decoded, reason = Customization.DecodeEnvelope(envelope)
    if not decoded then
        defaultState(state, "payload_rejected:" .. tostring(reason))
        return false, reason
    end
    state.envelope = copy(envelope)
    state.decoded = decoded
    state.envelopeFingerprint = decoded.fingerprint
    state.receivedAt = now()
    state.phase = Service.PHASE_RECEIVED
    state.reason = "received"
    local valid, validationReason = validateReceived(state)
    if valid then return true, "validated" end
    if validationReason == "traits_not_ready"
        or validationReason == "starting_traits_unavailable"
    then
        return true, "received"
    end
    return false, validationReason
end

function Service.Begin(player, uuid, at)
    local state
    local localEnvelope
    -- `at` belongs to StartingCompanionService's world-age clock. The
    -- customization deadline uses the monotonic millisecond clock used by
    -- the server tick, so never mix the two units here.
    local clockAt = now()
    uuid = uuid or characterUUID(player)
    if not player or not uuid then return nil, "invalid_player" end
    state = Service.Sessions[uuid]
    if state then
        state.player = player
        if state.phase == Service.PHASE_PENDING
            or state.phase == Service.PHASE_RECEIVED
        then
            validateReceived(state)
        end
        return state
    end
    state = newState(player, uuid, clockAt)
    -- SP and listen-server creation use the same semantic service.  The
    -- local envelope is only a handoff buffer; final authority still comes
    -- from this server-side state and the actual player below.
    localEnvelope = Customization.TakeLocalEnvelope()
    if localEnvelope then ingest(state, localEnvelope) end
    return state
end

function Service.Receive(player, envelope)
    local uuid = characterUUID(player)
    local state
    if not uuid then return false, "character_uuid_unavailable" end
    state = Service.Begin(player, uuid, now())
    if not state then return false, "customization_state_unavailable" end
    if state.phase == Service.PHASE_GRANTS_COMPLETE then
        return false, "grants_complete"
    end
    if state.phase == Service.PHASE_DEFAULTED then
        return false, "already_defaulted"
    end
    return ingest(state, envelope)
end

function Service.Default(player, uuid, reason)
    local state = Service.Begin(player, uuid, now())
    if not state then return false, "customization_state_unavailable" end
    return defaultState(state, reason)
end

function Service.Ensure(player, uuid, at)
    local state
    local nowValue
    local granted
    local reason
    local details
    at = tonumber(at) or now()
    state = Service.Begin(player, uuid, at)
    if not state then return false, "customization_state_unavailable" end
    if state.phase == Service.PHASE_GRANTS_COMPLETE then
        return true, "grants_complete", stateSnapshot(state)
    end
    if state.phase == Service.PHASE_RECEIVED then
        validateReceived(state)
    end
    nowValue = now()
    if state.phase == Service.PHASE_PENDING
        or state.phase == Service.PHASE_RECEIVED
    then
        if nowValue < state.deadlineAt then
            return false, "customization_pending", stateSnapshot(state)
        end
        defaultState(state, "customization_timeout")
    end
    if state.phase ~= Service.PHASE_VALIDATED
        and state.phase ~= Service.PHASE_DEFAULTED
    then
        return false, "customization_state_invalid", stateSnapshot(state)
    end
    state.attempts = state.attempts + 1
    granted, reason, details = Starting.Ensure(
        player,
        uuid,
        at,
        { blueprints = state.validatedBlueprints }
    )
    if granted == true or reason == "granted" or reason == "none" then
        state.phase = Service.PHASE_GRANTS_COMPLETE
        state.grantsCompletedAt = now()
        state.reason = reason or "grants_complete"
        removeFromOrder(uuid)
        if granted == true then sendColonySnapshot(player) end
        return granted, reason, details or stateSnapshot(state)
    end
    return granted, reason, details or stateSnapshot(state)
end

function Service.Pump(at)
    local processed = 0
    local index
    local uuid
    local state
    at = tonumber(at) or now()
    for index = #Service.SessionOrder, 1, -1 do
        if processed >= Service.MAX_PUMP_PER_TICK then break end
        uuid = Service.SessionOrder[index]
        state = Service.Sessions[uuid]
        if not state or state.phase == Service.PHASE_GRANTS_COMPLETE then
            table.remove(Service.SessionOrder, index)
        elseif state.player then
            processed = processed + 1
            Service.Ensure(state.player, uuid, worldAgeHours())
            if state.phase == Service.PHASE_GRANTS_COMPLETE then
                table.remove(Service.SessionOrder, index)
            end
        end
    end
    return processed
end

function Service.GetState(uuid)
    return stateSnapshot(Service.Sessions[uuid])
end

function Service.Reset()
    Service.Sessions = {}
    Service.SessionOrder = {}
end

return Service
