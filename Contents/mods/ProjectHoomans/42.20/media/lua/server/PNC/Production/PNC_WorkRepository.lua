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
        or order.operation == "DECONSTRUCT")
end

local function compactConstruction(order)
    if not construction(order) then return order end
    order.runtime = nil
    order.workerId, order.stationId, order.stationTarget = nil, nil, nil
    order.collectionTarget, order.executionMode = nil, nil
    order.facilityReservationId, order.previousOrder = nil, nil
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
            payload.input = {
                consume = input.consume == true,
                funded = input.funded == true or input.committed == true,
                committed = input.committed == true or input.funded == true,
            }
        end
    end
    return order
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
        order.facilityReservationId, order.previousOrder = nil, nil
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
function Repository.Save()
    Repository.Load()
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
