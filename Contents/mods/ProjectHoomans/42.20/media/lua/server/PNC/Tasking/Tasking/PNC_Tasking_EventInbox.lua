if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local H = Tasking.Internal
local Inbox = Tasking.Inbox
local Events = Tasking.Events
local Dirty = Tasking.Dirty

-- These are task wake-up events, not a replacement for the domain EventBus.
-- Domain events can remain broad; task events are deliberately normalized to
-- the information required to schedule one NPC.
Events.Types = Events.Types or {
    TASKING_INITIALIZED = "TASKING_INITIALIZED",
    NPC_NEEDS_CHANGED = "NPC_NEEDS_CHANGED",
    NPC_INVENTORY_CHANGED = "NPC_INVENTORY_CHANGED",
    WORK_REQUEST_CHANGED = "WORK_REQUEST_CHANGED",
    FACILITY_SLOT_RELEASED = "FACILITY_SLOT_RELEASED",
    FACILITY_COMPONENT_REMOVED = "FACILITY_COMPONENT_REMOVED",
    TASK_EXECUTOR_INVALID = "TASK_EXECUTOR_INVALID",
    TASK_EXECUTOR_FAILED = "TASK_EXECUTOR_FAILED",
    TASK_REEVALUATION_FAILED = "TASK_REEVALUATION_FAILED",
    TASK_LEASE_CREATED = "TASK_LEASE_CREATED",
    TASK_LEASE_PHASE_CHANGED = "TASK_LEASE_PHASE_CHANGED",
    TASK_LEASE_RELEASED = "TASK_LEASE_RELEASED",
}
Events._listeners = Events._listeners or {}

Inbox.queue = Dirty.queue or Inbox.queue or {}
Inbox.byNPC = Dirty.byNPC or Inbox.byNPC or {}
Inbox.head = Dirty.head or Inbox.head or 1
Inbox.tail = Dirty.tail or Inbox.tail or #Inbox.queue
Inbox.pendingCount = Dirty.pendingCount or Inbox.pendingCount or 0
Inbox.highWaterMark = Inbox.highWaterMark or Inbox.pendingCount
Tasking.Dirty = Inbox

local sequence = 0
local MAX_CAUSES_PER_ENTRY = 16

local function now()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function nextID()
    if PNC.Core and PNC.Core.GenerateID then
        return PNC.Core.GenerateID("task_event")
    end
    sequence = sequence + 1
    return "task_event:" .. tostring(now()) .. ":" .. tostring(sequence)
end

local function addRecentEvent(event)
    local recent = Tasking.Diagnostics.recentEvents
    recent[#recent + 1] = {
        id = event.id, type = event.type, source = event.source,
        npcId = event.npcId, entityId = event.entityId, at = event.at,
    }
    while #recent > 64 do table.remove(recent, 1) end
end

local function addCause(entry, event)
    local cause = tostring(event.cause or event.type)
    if not entry.causes[cause] then
        entry.causes[cause] = true
        if entry.causeCount < MAX_CAUSES_PER_ENTRY then
            entry.causeCount = entry.causeCount + 1
            entry.causeList[entry.causeCount] = cause
        end
    end
    entry.cause = cause
end

function Inbox.Enqueue(event)
    if type(event) ~= "table" or tostring(event.npcId or "") == "" then
        Tasking.Diagnostics.counters.eventRetries =
            Tasking.Diagnostics.counters.eventRetries + 1
        return false, "TASK_EVENT_NPC_REQUIRED"
    end
    local npcId = tostring(event.npcId)
    local entry = Inbox.byNPC[npcId]
    if entry then
        addCause(entry, event)
        entry.latestEvent = event
        entry.latestEventId = event.id
        entry.lastQueuedAt = event.at
        entry.revision = math.max(entry.revision, tonumber(event.revision) or 0)
        Tasking.Diagnostics.counters.eventCoalesces =
            Tasking.Diagnostics.counters.eventCoalesces + 1
        return true, entry
    end
    entry = {
        npcId = npcId, cause = tostring(event.cause or event.type),
        causes = {}, causeList = {}, causeCount = 0,
        firstQueuedAt = event.at, lastQueuedAt = event.at,
        latestEvent = event, latestEventId = event.id,
        revision = math.max(0, tonumber(event.revision) or 0),
    }
    addCause(entry, event)
    Inbox.tail = Inbox.tail + 1
    Inbox.queue[Inbox.tail] = entry
    Inbox.byNPC[npcId] = entry
    Inbox.pendingCount = Inbox.pendingCount + 1
    Inbox.highWaterMark = math.max(Inbox.highWaterMark, Inbox.pendingCount)
    return true, entry
end

function Inbox.Remove(npcId)
    npcId = tostring(npcId or "")
    local entry = Inbox.byNPC[npcId]
    if not entry then return false end
    Inbox.byNPC[npcId] = nil
    Inbox.pendingCount = math.max(0, Inbox.pendingCount - 1)
    entry.removed = true
    return true, entry
end

local function compact()
    if Inbox.head <= 128 or Inbox.head <= Inbox.tail / 2 then return end
    local output, index = {}, 0
    for cursor = Inbox.head, Inbox.tail do
        local entry = Inbox.queue[cursor]
        if entry and not entry.removed then
            index = index + 1
            output[index] = entry
        end
    end
    Inbox.queue, Inbox.head, Inbox.tail = output, 1, index
end

function Inbox.Pop()
    while Inbox.head <= Inbox.tail do
        local entry = Inbox.queue[Inbox.head]
        Inbox.queue[Inbox.head] = nil
        Inbox.head = Inbox.head + 1
        if entry and not entry.removed then
            if Inbox.byNPC[entry.npcId] == entry then
                Inbox.byNPC[entry.npcId] = nil
                Inbox.pendingCount = math.max(0, Inbox.pendingCount - 1)
                entry.removed = true
                compact()
                return entry
            end
        end
    end
    Inbox.queue, Inbox.head, Inbox.tail = {}, 1, 0
    Inbox.pendingCount = 0
    return nil
end

function Inbox.Count()
    return Inbox.pendingCount
end

function Inbox.Causes(entry)
    local output = {}
    for index = 1, tonumber(entry and entry.causeCount) or 0 do
        output[index] = entry.causeList[index]
    end
    return output
end

function Events.Subscribe(eventType, listener, ownerToken)
    eventType = tostring(eventType or "")
    if eventType == "" or type(listener) ~= "function" then return false end
    local list = Events._listeners[eventType]
    if not list then list = {}; Events._listeners[eventType] = list end
    for index = 1, #list do
        if list[index][1] == listener and list[index][2] == ownerToken then
            return true
        end
    end
    list[#list + 1] = { listener, ownerToken }
    return true
end

function Events.Unsubscribe(eventType, listener)
    local list = Events._listeners[tostring(eventType or "")]
    if not list then return false end
    for index = #list, 1, -1 do
        if list[index][1] == listener then
            table.remove(list, index)
            if #list == 0 then
                Events._listeners[tostring(eventType or "")] = nil
            end
            return true
        end
    end
    return false
end

function Events.ClearOwner(ownerToken)
    local removed = 0
    for eventType, list in pairs(Events._listeners) do
        for index = #list, 1, -1 do
            if list[index][2] == ownerToken then
                table.remove(list, index)
                removed = removed + 1
            end
        end
        if #list == 0 then Events._listeners[eventType] = nil end
    end
    return removed
end

local function notify(event)
    local list = Events._listeners[event.type]
    if not list then return end
    local snapshot = {}
    for index = 1, #list do snapshot[index] = list[index] end
    for index = 1, #snapshot do
        H.SafeCall("task_event_listener", snapshot[index][1], {
            npcId = event.npcId, eventId = event.id,
            domain = event.source,
        }, event)
    end
end

function Events.Emit(eventType, details, options)
    details = type(details) == "table" and details or {}
    options = type(options) == "table" and options or {}
    eventType = tostring(eventType or "")
    if eventType == "" then return false, "TASK_EVENT_TYPE_REQUIRED" end
    local record = details.record
    local npcId = tostring(details.npcId
        or record and record.id or "")
    local event = {
        id = nextID(), type = eventType, at = tonumber(details.at) or now(),
        source = tostring(details.source or "tasking"), npcId = npcId,
        entityId = details.entityId,
        revision = tonumber(details.revision) or 0,
        cause = tostring(details.cause or eventType),
        payload = H.Copy(details.payload or {}),
    }
    Tasking.Diagnostics.counters.eventEmits =
        Tasking.Diagnostics.counters.eventEmits + 1
    Tasking.Diagnostics.lastEvent = event
    addRecentEvent(event)
    notify(event)
    if npcId == "" or options.enqueue == false then return true, event end
    local queued, result = Inbox.Enqueue(event)
    if not queued then return false, result end
    if options.immediate == true and Tasking.Commands.ReevaluateNow then
        return Tasking.Commands.ReevaluateNow(event)
    end
    return true, event
end

return Tasking
