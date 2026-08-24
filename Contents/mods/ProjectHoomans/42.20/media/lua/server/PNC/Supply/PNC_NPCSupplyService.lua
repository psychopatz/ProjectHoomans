if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NPCSupplyService = PNC.NPCSupplyService or {}

local Service = PNC.NPCSupplyService
local Request = PNC.SupplyRequest
local Metrics = PNC.SupplyMetrics
local Selector = PNC.SupplySelector
local SupplyInventory = PNC.SupplyInventory
local SupplyCommands = SupplyInventory.Commands or SupplyInventory
local SupplyQueries = SupplyInventory.Queries or SupplyInventory
local Access = PNC.StorageAccessPolicy
local Index = PNC.SupplyIndex
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local Repository = require "PNC/Colony/Storage/PNC_ColonyStorageRepository"
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"

local function worldHour()
    return PNC.NeedsUtils and PNC.NeedsUtils.WorldAgeHours
        and PNC.NeedsUtils.WorldAgeHours() or 0
end

local function runtime(record, kind)
    record.runtime = record.runtime or {}
    record.runtime.supply = record.runtime.supply or { byKind = {} }
    local root = record.runtime.supply
    root.byKind[kind] = root.byKind[kind] or {
        phase = "IDLE", nextRetry = 0,
    }
    return root.byKind[kind], root
end

local function log(record, request, result, details)
    if not ((PNC.NeedsDebug
            and PNC.NeedsDebug.SupplyLoggingEnabled == true)
        or (PNC.Sandbox and PNC.Sandbox.NPCSupplyTransactionLoggingEnabled
            and PNC.Sandbox.NPCSupplyTransactionLoggingEnabled()))
    then return end
    local fields = {
        "[PNC][NPC_SUPPLY]",
        "npc=" .. tostring(record and record.id or "none"),
        "kind=" .. tostring(request and request.resourceKind or "none"),
        "purpose=" .. tostring(request and request.purpose or "none"),
        "priority=" .. tostring(request and request.priority or 0),
        "result=" .. tostring(result or "none"),
        "source=" .. tostring(details and details.source or "none"),
        "storage=" .. tostring(details and details.storageId or "none"),
        "item=" .. tostring(details and details.fullType or "none"),
        "typeId=" .. tostring(details and details.typeId or "none"),
        "quantity=" .. tostring(details and details.quantity or 0),
        "inventoryMode=" .. tostring(PNC.Inventory.GetPersistenceMode(record)),
        "needAfter=" .. tostring(details and details.needAfter or "none"),
        "projectionMissing=" .. tostring(
            details and details.projectionMissing == true
        ),
    }
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(table.concat(fields, " "))
    end
end

local function requestCounter(kind)
    if kind == "FOOD" then return "foodRequests" end
    if kind == "HYDRATION" then return "hydrationRequests" end
    return "medicalRequests"
end

local function retryHours(request)
    local definition = PNC.NeedsDefinitions.SUPPLY[
        request.resourceKind == "FOOD" and "hunger"
            or request.resourceKind == "HYDRATION" and "thirst"
            or "medical"
    ]
    local severe = request.priority >= 90
    return severe and definition.urgentRetryHours or definition.retryHours
end

local function fail(record, request, state, reason, details)
    state.phase = "FAILED"
    state.lastResult = "failed"
    state.lastFailureReason = reason
    state.lastAttemptAt = worldHour()
    state.nextRetry = state.lastAttemptAt + retryHours(request)
    state.reservationState = nil
    Metrics.Increment("supplyRequestsFailed")
    log(record, request, reason, details)
    return false, reason, details
end

local function restoreStorage(storage, records)
    local restored = true
    for index = 1, #(records or {}) do
        local ok = storage.inventory:add(records[index])
        if not ok then restored = false end
    end
    Index.Invalidate(storage)
    return restored
end

local function releaseAll(storage, tokens, first)
    for index = first or 1, #tokens do
        storage.inventory:releaseReservation(tokens[index])
    end
end

local function acquireInstant(record, storage, request, selected, state)
    local tokens = {}
    state.phase = "RESERVE"
    for index = 1, #selected do
        local token, reason = storage.inventory:reserve(
            selected[index].query,
            selected[index].quantity,
            "npc_supply:" .. record.id
        )
        if not token then
            releaseAll(storage, tokens)
            Metrics.Increment("reservationFailures")
            return false, reason
        end
        tokens[#tokens + 1] = token
        Metrics.Increment("reservationsCreated")
    end
    state.reservationState = "reserved"
    state.phase = "ACQUIRE"
    local source = { revision = storage.inventory.revision }
    function source:remove()
        local removed = {}
        for index = 1, #tokens do
            local ok, records = storage.inventory:commitReservation(tokens[index])
            if not ok then
                releaseAll(storage, tokens, index)
                restoreStorage(storage, removed)
                return false, records
            end
            for itemIndex = 1, #records do
                removed[#removed + 1] = records[itemIndex]
            end
        end
        return true, removed
    end
    function source:restoreRemoved(records)
        return restoreStorage(storage, records)
    end
    local destination = SupplyCommands.CreateDestination(
        record, "colony_supply_instant"
    )
    local quantity = 0
    for index = 1, #selected do
        quantity = quantity + selected[index].quantity
    end
    local added, reason = CoreInventory.transfer(
        source, destination, nil, quantity
    )
    if not added then return false, reason end
    storage.revision = math.max(0, tonumber(storage.revision) or 0) + 1
    Repository.MarkDirty()
    local activityItems = {}
    for index = 1, #selected do
        activityItems[#activityItems + 1] = {
            typeId = selected[index].descriptor.typeId,
            quantity = selected[index].quantity,
        }
    end
    for index = 1, #activityItems do
        Events.emit(EventTypes.STORAGE_ITEM_WITHDRAWN, storage.id,
            tostring(record.name or record.id), activityItems[index].typeId,
            activityItems[index].quantity, "provision")
    end
    Index.AfterRemoval(storage)
    if PNC.ColonyStorageService and PNC.ColonyStorageService.Metrics then
        PNC.ColonyStorageService.Metrics.withdrawals =
            (PNC.ColonyStorageService.Metrics.withdrawals or 0) + 1
    end
    state.reservationState = "committed"
    Metrics.Increment("instantAcquisitions")
    return true, "acquired", {
        physicalItems = destination.physicalItems,
        physicalProjectionMissing =
            destination.physicalProjectionMissing == true,
    }
end

local function updateNeed(record, request, effect)
    if request.resourceKind == "FOOD" then
        return PNC.IndividualNeeds.Commands.ApplyFood(
            record, effect, "consumed_food")
    end
    if request.resourceKind == "HYDRATION" then
        return PNC.IndividualNeeds.Commands.ApplyDrink(
            record, effect, "consumed_hydration")
    end
    return nil
end

local function usePersonal(record, request, state, options)
    local required = request.resourceKind == "FOOD"
        and tonumber(request.required.hunger)
        or request.resourceKind == "HYDRATION"
            and tonumber(request.required.thirst) or 1
    required = math.max(0.001, required or 0.001)
    if SupplyCommands.EnsurePersonalInventory then
        SupplyCommands.EnsurePersonalInventory(record)
    end
    local candidates = SupplyQueries.FindPersonal(record, request, required)
    state.personalCandidateCount = #candidates
    state.personalCandidates = {}
    for index = 1, math.min(#candidates, 8) do
        state.personalCandidates[index] = {
            itemID = candidates[index].itemID,
            fullType = candidates[index].descriptor.fullType,
            score = candidates[index].score,
        }
    end
    if #candidates <= 0 then return false, "personal_missing", required end
    if options.acquireOnly then return true, "personal_available", required end
    if request.resourceKind == "MEDICAL" then
        local partID = request.required and request.required.partId
        local ok, reason = PNC.Treatment.TryNPCBandage(record, partID)
        return ok, reason, ok and 0 or required
    end
    local remaining = required
    local used = 0
    local maxUses = request.resourceKind == "HYDRATION"
        and (tonumber(PNC.NeedsDefinitions.SUPPLY_MAX_USES) or 8)
        or PNC.NeedsDefinitions.SUPPLY_MAX_SELECTIONS
    for index = 1, #candidates do
        if used >= maxUses
            or remaining <= 0
        then break end
        local availableUses = request.resourceKind == "HYDRATION"
            and math.max(1, candidates[index].descriptor.remainingUses)
            or math.max(1, math.floor(
                tonumber(candidates[index].stack) or 1
            ))
        local candidateUses = 0
        while candidateUses < availableUses
            and used < maxUses
            and remaining > 0
        do
            local ok, reason, effect = SupplyCommands.Consume(
                record, candidates[index].itemID, request
            )
            if not ok then
                state.lastUseFailure = reason
                break
            end
            updateNeed(record, request, effect)
            local contribution = request.resourceKind == "FOOD"
                and effect.hunger or effect.thirst
            remaining = remaining - contribution
            used = used + 1
            candidateUses = candidateUses + 1
            state.lastUsedItem = effect
        end
    end
    return used > 0, used > 0 and "personal_used" or "personal_use_failed",
        math.max(0, remaining)
end

function Service.HasPersonalSupply(record, resourceKind, required)
    if not record or record.alive == false then return false end
    local request = Request.Create({
        requesterId = record.id,
        purpose = "NEED",
        resourceKind = resourceKind,
        required = type(required) == "table" and required or {},
        fulfillment = "INSTANT",
    })
    if not request then return false end
    local amount = request.resourceKind == "FOOD"
        and tonumber(request.required.hunger)
        or request.resourceKind == "HYDRATION"
            and tonumber(request.required.thirst) or 1
    local candidates = SupplyQueries.FindPersonal(
        record, request, math.max(0.001, amount or 0.001))
    return #candidates > 0,
        candidates[1] and candidates[1].descriptor
            and candidates[1].descriptor.fullType or nil
end

function Service.Process(rawRequest, options)
    options = type(options) == "table" and options or {}
    local request, reason = Request.Create(rawRequest)
    if not request then return false, reason end
    if not (PNC.Core and PNC.Core.IsAuthority and PNC.Core.IsAuthority()) then
        return false, "server_authority_required"
    end
    local record = PNC.Registry and PNC.Registry.Get(request.requesterId) or nil
    if not record or record.alive == false then return false, "npc_missing" end
    local state, root = runtime(record, request.resourceKind)
    local materiallyWorse = request.priority
        >= ((tonumber(state.lastPriority) or request.priority) + 15)
    if not options.force and not materiallyWorse
        and worldHour() < (tonumber(state.nextRetry) or 0)
    then
        Metrics.Increment("supplyRetriesSuppressed")
        return false, "retry_suppressed"
    end
    Metrics.Increment("supplyRequests")
    Metrics.Increment(requestCounter(request.resourceKind))
    state.phase = "CHECK_PERSONAL"
    state.request = request
    state.lastPriority = request.priority
    state.lastAttemptAt = worldHour()
    state.lastFailureReason = nil
    root.currentKind = request.resourceKind

    local personalOK, personalReason, remaining
    if options.ignorePersonal then
        state.personalCandidateCount = 0
        state.personalCandidates = {}
        personalOK = false
        personalReason = "personal_already_measured"
        remaining = request.resourceKind == "FOOD"
            and math.max(0.001, tonumber(request.required.hunger) or 0.001)
            or request.resourceKind == "HYDRATION"
                and math.max(0.001, tonumber(request.required.thirst) or 0.001)
                or math.max(1, tonumber(request.required.count) or 1)
    else
        personalOK, personalReason, remaining = usePersonal(
            record, request, state, options
        )
    end
    if personalOK and (options.acquireOnly or remaining <= 0
        or request.resourceKind == "MEDICAL")
    then
        state.phase = options.acquireOnly and "NPC_INVENTORY" or "REEVALUATE"
        state.lastResult = personalReason
        state.nextRetry = 0
        Metrics.Increment("supplyRequestsSatisfiedFromPersonalInventory")
        Metrics.Increment("supplyRequestsSucceeded")
        log(record, request, personalReason, {
            source = "personal",
            fullType = state.lastUsedItem and state.lastUsedItem.fullType,
            typeId = state.lastUsedItem and state.lastUsedItem.typeId,
            projectionMissing = state.lastUsedItem
                and state.lastUsedItem.physicalProjectionMissing == true,
            needAfter = request.resourceKind == "FOOD"
                and PNC.IndividualNeeds.Get(record, "hunger")
                or request.resourceKind == "HYDRATION"
                    and PNC.IndividualNeeds.Get(record, "thirst") or nil,
        })
        return true, personalReason
    end
    if #state.personalCandidates > 0 and not personalOK then
        return fail(record, request, state, personalReason, {
            source = "personal",
        })
    end

    -- Need fulfillment consumes only an already-issued provision.  Fetching
    -- from colony storage is the provision scheduler's responsibility, not a
    -- side effect of becoming hungry or thirsty.
    if options.personalOnly then
        if personalOK then
            state.phase = "REEVALUATE"
            state.lastResult = personalReason
            state.nextRetry = remaining > 0
                and (worldHour() + retryHours(request)) or 0
            Metrics.Increment("supplyRequestsSatisfiedFromPersonalInventory")
            Metrics.Increment("supplyRequestsSucceeded")
            return true, personalReason
        end
        return fail(record, request, state, personalReason, {
            source = "personal",
        })
    end

    state.phase = "REQUEST_SUPPLY"
    Metrics.Increment("supplyRequestsSentToStorage")
    local storage
    storage, reason = Access.Resolve(record)
    if not storage then return fail(record, request, state, reason) end
    state.sourceStorageId = storage.id
    local storageRequest = {}
    for key, value in pairs(request) do storageRequest[key] = value end
    storageRequest.required = {}
    for key, value in pairs(request.required) do storageRequest.required[key] = value end
    if request.resourceKind == "FOOD" then storageRequest.required.hunger = remaining end
    if request.resourceKind == "HYDRATION" then storageRequest.required.thirst = remaining end
    state.phase = "SELECT_CANDIDATE"
    local selected, candidateCount, scored = Selector.SelectFromStorage(
        storage, storageRequest
    )
    state.storageCandidateCount = candidateCount
    state.selected = {}
    state.candidateScores = {}
    for index = 1, math.min(#scored, 24) do
        state.candidateScores[index] = {
            fullType = scored[index].descriptor.fullType,
            typeId = scored[index].descriptor.typeId,
            score = scored[index].score,
            expiry = scored[index].descriptor.expiry,
            unsafe = scored[index].descriptor.unsafe,
        }
    end
    for index = 1, #selected do
        state.selected[index] = {
            fullType = selected[index].descriptor.fullType,
            typeId = selected[index].descriptor.typeId,
            quantity = selected[index].quantity,
            score = selected[index].score,
        }
    end
    if #selected <= 0 then return fail(record, request, state, "no_supply", {
        source = "storage", storageId = storage.id,
    }) end
    if request.fulfillment ~= "INSTANT" then
        return fail(record, request, state, "physical_fulfillment_unavailable", {
            source = "storage", storageId = storage.id,
        })
    end
    local acquired, acquireReason, acquireDetails = acquireInstant(
        record, storage, request, selected, state
    )
    if not acquired then
        Metrics.Increment("acquisitionFailures")
        return fail(record, request, state, acquireReason, {
            source = "storage", storageId = storage.id,
        })
    end
    state.phase = "NPC_INVENTORY"
    local postUseRemaining = 0
    if not options.acquireOnly then
        local used, useReason, remainingAfterUse = usePersonal(
            record, request, state, options
        )
        if not used then
            return fail(record, request, state, useReason, {
                source = "storage", storageId = storage.id,
            })
        end
        postUseRemaining = remainingAfterUse or 0
    end
    state.phase = options.acquireOnly and "NPC_INVENTORY" or "REEVALUATE"
    state.lastResult = options.acquireOnly and "acquired" or "acquired_and_used"
    state.nextRetry = postUseRemaining > 0
        and (worldHour() + retryHours(request)) or 0
    Metrics.Increment("supplyRequestsSucceeded")
    log(record, request, state.lastResult, {
        source = "storage",
        storageId = storage.id,
        fullType = selected[1].descriptor.fullType,
        typeId = selected[1].descriptor.typeId,
        quantity = selected[1].quantity,
        projectionMissing = state.lastUsedItem
            and state.lastUsedItem.physicalProjectionMissing == true
            or acquireDetails
                and acquireDetails.physicalProjectionMissing == true,
        needAfter = request.resourceKind == "FOOD"
            and PNC.IndividualNeeds.Get(record, "hunger")
            or request.resourceKind == "HYDRATION"
                and PNC.IndividualNeeds.Get(record, "thirst") or nil,
    })
    return true, state.lastResult, acquireDetails
end

function Service.ClearRetry(record, kind)
    if not record then return false end
    local state = runtime(record, string.upper(tostring(kind or "FOOD")))
    state.nextRetry = 0
    return true
end

function Service.GetDebugState(record)
    local root = record and record.runtime and record.runtime.supply or nil
    return root and PNC.Core.DeepCopy(root) or { byKind = {} }
end

function Service.HasRecentNeedRequest(record, kind, withinHours)
    local root = record and record.runtime and record.runtime.supply
    local state = root and root.byKind
        and root.byKind[string.upper(tostring(kind or ""))] or nil
    local request = state and state.request or nil
    if not request or request.purpose ~= "NEED" then return false end
    return worldHour() - (tonumber(state.lastAttemptAt) or -math.huge)
        <= math.max(0, tonumber(withinHours) or 0)
end

return Service
