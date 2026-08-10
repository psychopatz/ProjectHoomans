PNC = PNC or {}
PNC.Scheduler = PNC.Scheduler or {}

local Scheduler = PNC.Scheduler
local Const = PNC.Const
local LOD = PNC.SimulationLOD

Scheduler.SLOT_MS = 50
Scheduler.Buckets = Scheduler.Buckets or {}
Scheduler.SlotByID = Scheduler.SlotByID or {}
Scheduler.Initialized = Scheduler.Initialized or false
Scheduler.LastSlot = Scheduler.LastSlot or nil
Scheduler.Jobs = Scheduler.Jobs or {}
Scheduler.JobOrder = Scheduler.JobOrder or {}

function Scheduler.GetCadence(record)
    if LOD and LOD.GetCadence then
        return LOD.GetCadence(record)
    end
    if record.runtime and record.runtime.vehiclePassenger
        and record.runtime.vehiclePassenger.active == true
    then
        return math.min(
            tonumber(Const.FOLLOW_VEHICLE_TICK_MS) or 100,
            tonumber(Const.TICK_LIVE_WARM_MS) or 250
        )
    end
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
        if record.runtime and record.runtime.forcePresenceCheck then
            Scheduler.Schedule(
                record,
                (tonumber(now) or 0) + Scheduler.SLOT_MS
            )
        else
            Scheduler.Schedule(record, (tonumber(now) or 0) + (PNC.Identity.MixSeed(record.identitySeed, "schedule") % math.max(1, cadence)))
        end
    end
    Scheduler.Initialized = true
end

function Scheduler.PopDue(records, now)
    local output = {}
    local deferred = {}
    local maxRecords = math.max(1, math.floor(
        tonumber(Const.SCHEDULER_MAX_RECORDS_PER_TICK) or 24
    ))
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
                    if #output < maxRecords then
                        output[#output + 1] = records[id]
                    else
                        deferred[#deferred + 1] = records[id]
                    end
                end
            end
            Scheduler.Buckets[slot] = nil
        end
    end
    Scheduler.LastSlot = currentSlot
    for i = 1, #deferred do
        Scheduler.Schedule(
            deferred[i],
            (tonumber(now) or 0) + Scheduler.SLOT_MS
        )
    end
    return output
end

function Scheduler.Remove(id)
    if id ~= nil then
        Scheduler.SlotByID[tostring(id)] = nil
    end
end

-- Register a lightweight periodic system job. Strategic jobs use world hours;
-- callers provide the current value to PumpJobs so no wall-clock conversion is
-- hidden in the scheduler. Re-registering a name updates it in place.
function Scheduler.RegisterJob(name, interval, callback, options)
    name = tostring(name or "")
    interval = tonumber(interval)
    options = type(options) == "table" and options or {}
    if name == "" or not interval or interval <= 0
        or type(callback) ~= "function"
    then return false, "invalid_job" end
    local job = Scheduler.Jobs[name]
    if not job then
        job = { name = name, runs = 0, errors = 0 }
        Scheduler.Jobs[name] = job
        Scheduler.JobOrder[#Scheduler.JobOrder + 1] = name
        table.sort(Scheduler.JobOrder)
    end
    job.interval = interval
    job.callback = callback
    job.budget = math.max(1, math.floor(tonumber(options.budget) or 1))
    job.enabled = options.enabled ~= false
    job.nextRun = tonumber(options.startAt) or job.nextRun
    return true, job
end

function Scheduler.UnregisterJob(name)
    name = tostring(name or "")
    if not Scheduler.Jobs[name] then return false end
    Scheduler.Jobs[name] = nil
    for index = #Scheduler.JobOrder, 1, -1 do
        if Scheduler.JobOrder[index] == name then
            table.remove(Scheduler.JobOrder, index)
        end
    end
    return true
end

function Scheduler.SetJobEnabled(name, enabled)
    local job = Scheduler.Jobs[tostring(name or "")]
    if not job then return false end
    job.enabled = enabled == true
    return true
end

function Scheduler.PumpJobs(now)
    now = tonumber(now) or 0
    local ran = 0
    for _, name in ipairs(Scheduler.JobOrder) do
        local job = Scheduler.Jobs[name]
        if job and job.enabled ~= false then
            if job.nextRun == nil then job.nextRun = now + job.interval end
            if now >= job.nextRun then
                local ok, result = pcall(job.callback, now, job.budget, job)
                job.lastRun = now
                job.nextRun = now + job.interval
                job.runs = (tonumber(job.runs) or 0) + 1
                job.lastResult = ok and result or nil
                job.lastError = ok and nil or tostring(result)
                if not ok then job.errors = (tonumber(job.errors) or 0) + 1 end
                ran = ran + 1
            end
        end
    end
    return ran
end

function Scheduler.GetJobs()
    local output = {}
    for _, name in ipairs(Scheduler.JobOrder) do
        local job = Scheduler.Jobs[name]
        if job then
            output[#output + 1] = {
                name = name, interval = job.interval,
                nextRun = job.nextRun, lastRun = job.lastRun,
                runs = job.runs, errors = job.errors,
                enabled = job.enabled ~= false,
                lastError = job.lastError,
            }
        end
    end
    return output
end
