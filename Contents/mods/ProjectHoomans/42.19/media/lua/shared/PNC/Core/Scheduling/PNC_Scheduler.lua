PNC = PNC or {}
PNC.Scheduler = PNC.Scheduler or {}

local Scheduler = PNC.Scheduler
local Const = PNC.Const

Scheduler.SLOT_MS = 50
Scheduler.Buckets = Scheduler.Buckets or {}
Scheduler.SlotByID = Scheduler.SlotByID or {}
Scheduler.Initialized = Scheduler.Initialized or false
Scheduler.LastSlot = Scheduler.LastSlot or nil

function Scheduler.GetCadence(record)
    if record.presenceState == Const.PRESENCE_ABSTRACT then
        return Const.TICK_ABSTRACT_MS
    end
    if record.health and record.health.state == "incapacitated" then
        return math.min(Const.TICK_LIVE_WARM_MS, 100)
    end
    if record.runtime and record.runtime.attackAction then
        return 50
    end
    if record.runtime and record.runtime.target then
        return math.min(Const.TICK_LIVE_HOT_MS, 75)
    end
    if record.runtime and record.runtime.pathing and (record.runtime.pathing.phase == "requested" or record.runtime.pathing.phase == "active") then
        return math.min(Const.TICK_LIVE_WARM_MS, 100)
    end
    if tostring(record.activeJob or "") == "PatrolRoute" or tostring(record.activeJob or "") == "FollowOwner" then
        return math.min(Const.TICK_LIVE_WARM_MS, 100)
    end
    return math.min(Const.TICK_LIVE_COLD_MS, 500)
end

function Scheduler.Schedule(record, dueAt)
    local slot
    local bucket
    if not record or not record.id then
        return
    end
    slot = math.floor((tonumber(dueAt) or 0) / Scheduler.SLOT_MS)
    if Scheduler.LastSlot and slot <= Scheduler.LastSlot then
        slot = Scheduler.LastSlot + 1
    end
    Scheduler.SlotByID[record.id] = slot
    bucket = Scheduler.Buckets[slot]
    if not bucket then
        bucket = {}
        Scheduler.Buckets[slot] = bucket
    end
    bucket[#bucket + 1] = record.id
end

function Scheduler.Initialize(records, now)
    local id
    local record
    local cadence
    Scheduler.Buckets = {}
    Scheduler.SlotByID = {}
    Scheduler.LastSlot = math.floor((tonumber(now) or 0) / Scheduler.SLOT_MS) - 1
    for id, record in pairs(records or {}) do
        cadence = Scheduler.GetCadence(record)
        Scheduler.Schedule(record, (tonumber(now) or 0) + (PNC.Identity.MixSeed(record.identitySeed, "schedule") % math.max(1, cadence)))
    end
    Scheduler.Initialized = true
end

function Scheduler.PopDue(records, now)
    local output = {}
    local currentSlot = math.floor((tonumber(now) or 0) / Scheduler.SLOT_MS)
    local slot = Scheduler.LastSlot or (currentSlot - 1)
    local bucket
    local i
    local id
    if not Scheduler.Initialized then
        Scheduler.Initialize(records, now)
        slot = Scheduler.LastSlot
    end
    while slot < currentSlot do
        slot = slot + 1
        bucket = Scheduler.Buckets[slot]
        if bucket then
            for i = 1, #bucket do
                id = bucket[i]
                if Scheduler.SlotByID[id] == slot and records[id] then
                    Scheduler.SlotByID[id] = nil
                    output[#output + 1] = records[id]
                end
            end
            Scheduler.Buckets[slot] = nil
        end
    end
    Scheduler.LastSlot = currentSlot
    return output
end

function Scheduler.Remove(id)
    if id ~= nil then
        Scheduler.SlotByID[tostring(id)] = nil
    end
end
