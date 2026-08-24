if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkRepository = PNC.WorkRepository or {}

local Repository = PNC.WorkRepository
Repository.SCHEMA_VERSION = 1
Repository.MODDATA_KEY = "PNC_WorkOrders_V1"
Repository.State = Repository.State or { schemaVersion = 1, nextId = 1, byId = {} }
Repository.Loaded = Repository.Loaded == true
Repository.Dirty = Repository.Dirty == true

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function construction(order)
    return order and (order.operation == "CONSTRUCT"
        or order.operation == "RECONSTRUCT"
        or order.operation == "DECONSTRUCT"
        or order.operation == "BUILD_OBJECT")
end

local function compactConstruction(order)
    if not construction(order) then return order end
    order.runtime = nil
    order.workerId, order.stationId, order.stationTarget = nil, nil, nil
    order.collectionTarget, order.executionMode = nil, nil
    order.facilityReservationId = nil
    order.lastAbstractAt, order.blockedReason = nil, nil
    if order.status ~= "PAUSED" and order.status ~= "CANCELLING"
        and order.status ~= "COMPLETED"
        and order.status ~= "CANCELLED"
    then
        order.status = "WAITING_FOR_WORKER"
    end
    local payload = order.payload
    if type(payload) == "table" then
        payload.requirements = nil
        local input = payload.input
        if type(input) == "table" then
            local funded = order.funded == true
                or input.funded == true or input.committed == true
            payload.input = {
                consume = input.consume == true,
                funded = funded,
                committed = funded,
            }
        end
    end
    return order
end

-- Older saves compacted construction inputs down to `consume`, even after
-- the project had made progress.  That left the scheduler looking for a
-- runtime-only reservation that can no longer exist after a reload.
local function recoverCompactedConstructionInput(order)
    local input = order and order.payload and order.payload.input or nil
    local progress = order and tonumber(order.progress) or nil
    if type(input) ~= "table" or not progress or progress <= 0
        or order.funded == true
        or input.funded == true or input.committed == true
    then return end
    if (input.storageId == nil or input.storageId == "")
        and (input.reservationId == nil or input.reservationId == "")
    then
        order.funded = true
        input.funded, input.committed = true, true
        input.legacyRecovered = true
    end
end

local function recover(order)
    order.revision = math.max(0, math.floor(tonumber(order.revision) or 0))
    order.progress = math.max(0, tonumber(order.progress) or 0)
    order.requiredWork = math.max(1, tonumber(order.requiredWork) or 100)
    order.runtime = nil
    order.reservationId = nil
    order.stationId = nil
    order.stationTarget = nil
    order.executionMode = nil
    order.facilityReservationId = nil
    if construction(order) then
        order.workerId, order.stationId, order.stationTarget = nil, nil, nil
        order.collectionTarget, order.executionMode = nil, nil
        order.facilityReservationId = nil
        order.lastAbstractAt, order.blockedReason = nil, nil
        if order.status ~= "PAUSED" and order.status ~= "CANCELLING"
            and order.status ~= "COMPLETED"
            and order.status ~= "CANCELLED"
        then order.status = "WAITING_FOR_WORKER" end
        if order.payload and order.payload.input then
            order.payload.requirements = nil
            order.payload.input = {
                consume = order.payload.input.consume == true,
                funded = order.payload.input.funded == true
                    or order.payload.input.committed == true,
                committed = order.payload.input.committed == true
                    or order.payload.input.funded == true,
            }
            recoverCompactedConstructionInput(order)
        end
    elseif order.status == "CLAIMED" or order.status == "TRAVEL_TO_STOCKPILE"
        or order.status == "TRAVEL_TO_STATION"
        or order.status == "WORKING"
    then
        order.status = "WAITING_FOR_WORKER"
        order.workerId = nil
        order.blockedReason = "RECOVERED_AFTER_LOAD"
    end
    if order.status == "COMPLETED" or order.status == "CANCELLED" then
        order.terminalPersisted = true
    end
    return order
end

function Repository.Import(raw)
    local state = { schemaVersion = Repository.SCHEMA_VERSION, nextId = 1, byId = {} }
    if type(raw) == "table"
        and tonumber(raw.schemaVersion) == Repository.SCHEMA_VERSION
    then
        state.nextId = math.max(1, math.floor(tonumber(raw.nextId) or 1))
        for id, order in pairs(raw.byId or {}) do
            if type(order) == "table" then
                id = tostring(id)
                order = recover(copy(order))
                order.id = id
                state.byId[id] = order
            end
        end
    end
    Repository.State, Repository.Loaded, Repository.Dirty = state, true, false
    return state
end

function Repository.Load(force)
    if Repository.Loaded and force ~= true then return Repository.State end
    local raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Repository.MODDATA_KEY) or nil
    return Repository.Import(raw)
end

function Repository.NextId()
    Repository.Load()
    local id = "work:" .. tostring(Repository.State.nextId)
    Repository.State.nextId = Repository.State.nextId + 1
    Repository.Dirty = true
    return id
end
function Repository.Get(id) Repository.Load(); return Repository.State.byId[tostring(id or "")] end
function Repository.Put(order)
    Repository.Load(); Repository.State.byId[order.id] = order
    Repository.Dirty = true; return order
end
function Repository.Remove(id)
    Repository.Load()
    id = tostring(id or "")
    if not Repository.State.byId[id] then return false end
    Repository.State.byId[id] = nil
    Repository.Dirty = true
    return true
end
function Repository.MarkDirty() Repository.Dirty = true end

local function checkpointConstructionInputs()
    for _, order in pairs(Repository.State.byId or {}) do
        local input = order and order.payload and order.payload.input or nil
        if construction(order) and order.operation ~= "DECONSTRUCT"
            and order.status ~= "COMPLETED"
            and order.status ~= "CANCELLED"
            and type(input) == "table"
            and input.committed ~= true and input.funded ~= true
            and PNC.WorkInputService
            and PNC.WorkInputService.Commit
        then
            local committed = PNC.WorkInputService.Commit(
                order, "construction_save_checkpoint")
            if committed ~= true and tonumber(order.progress) > 0
                and (input.storageId == nil or input.storageId == "")
                and (input.reservationId == nil or input.reservationId == "")
                and input.staged ~= true and input.itemIds == nil
            then
                -- A pre-fix save may already have discarded the reservation.
                -- In-progress construction has already crossed the material
                -- boundary, so preserve that fact instead of re-blocking it.
                order.funded = true
                input.funded, input.committed = true, true
                input.legacyRecovered = true
                Repository.Dirty = true
            end
        end
    end
end

function Repository.Save()
    Repository.Load()
    checkpointConstructionInputs()
    if not Repository.Dirty then return false, "not_dirty" end
    local target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Repository.MODDATA_KEY) or nil
    if not target then return false, "moddata_unavailable" end
    local payload = copy(Repository.State)
    for _, order in pairs(payload.byId) do compactConstruction(order) end
    for key, _ in pairs(target) do target[key] = nil end
    for key, value in pairs(payload) do target[key] = value end
    Repository.Dirty = false
    for _, order in pairs(Repository.State.byId) do
        if order.status == "COMPLETED" or order.status == "CANCELLED" then
            order.terminalPersisted = true
        end
    end
    return true, "saved"
end
if Events and Events.OnInitGlobalModData and not Repository.LoadHookRegistered then
    Events.OnInitGlobalModData.Add(function() Repository.Load(true) end)
    Repository.LoadHookRegistered = true
end
return Repository
