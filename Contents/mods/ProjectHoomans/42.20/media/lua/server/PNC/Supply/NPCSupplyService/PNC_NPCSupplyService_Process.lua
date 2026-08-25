-- Authoritative NPC supply request orchestration.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NPCSupplyService = PNC.NPCSupplyService or {}
local Service = PNC.NPCSupplyService
local Internal = Service.Internal
local Request = PNC.SupplyRequest
local Metrics = PNC.SupplyMetrics
local Selector = PNC.SupplySelector
local Access = PNC.StorageAccessPolicy
local runtime = Internal.Runtime
local worldHour = Internal.WorldHour
local requestCounter = Internal.RequestCounter
local retryHours = Internal.RetryHours
local fail = Internal.Fail
local log = Internal.Log
local usePersonal = Internal.UsePersonal
local acquireInstant = Internal.AcquireInstant

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
    local live = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    if request.purpose == "PROVISION" and live
        and PNC.ProvisionScheduler
        and PNC.ProvisionScheduler.QueueLivePickup
    then
        local queued, queueReason, queueDetails =
            PNC.ProvisionScheduler.QueueLivePickup(
                record, storage, request, selected, state)
        if queueReason == "provision_pickup_queued" then
            return queued, queueReason, queueDetails
        end
        -- The production work service is loaded after Supply in the server
        -- composition root. During that bootstrap window, retain the
        -- existing immediate path rather than dropping a valid provision.
        if queued ~= nil or queueReason ~= "work_service_unavailable" then
            return false, queueReason or "provision_pickup_failed", queueDetails
        end
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

return Service
