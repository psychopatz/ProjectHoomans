-- Seeded daily eating, drinking, and sleep windows.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RoamAmbient = PNC.RoamAmbient or {}

local Service = PNC.RoamAmbient

local function identitySeed(record)
    local identity = record and record.identity or nil
    return record and (record.identitySeed
        or identity and identity.seed or record.id) or "roam_ambient"
end

local function seededRange(record, salt, low, high)
    local identity = PNC.Identity
    if identity and identity.Range then
        return identity.Range(identitySeed(record), salt, low, high)
    end
    local span = math.max(1, (tonumber(high) or 0) - (tonumber(low) or 0) + 1)
    local seed = math.abs(math.floor(tonumber(identitySeed(record)) or 1))
    return (tonumber(low) or 0) + (seed % span)
end

local function nightKey(hours)
    return math.floor((hours - Service.NIGHT_START_HOUR) / 24)
end

local function nightBounds(key)
    local startAt = key * 24 + Service.NIGHT_START_HOUR
    local endAt = key * 24 + 24 + Service.NIGHT_END_HOUR
    return startAt, endAt
end

local function addSlotPlan(record, hours, day, slot, action)
    local minutes = math.abs(tonumber(slot.offsetMinutes) or 0)
    local offset = seededRange(record,
        "roam_ambient:" .. tostring(action) .. ":" .. tostring(slot.id),
        -minutes, minutes) / 60
    local scheduledAt = day * 24 + tonumber(slot.hour or 0) + offset
    local key = tostring(day) .. ":" .. tostring(action) .. ":"
        .. tostring(slot.id)
    if hours >= scheduledAt
        and hours < scheduledAt + Service.SCHEDULE_WINDOW_HOURS
        and Service.ScheduleState(record).lastAttemptKey ~= key
    then
        return {
            action = action, key = key, scheduledAt = scheduledAt,
            windowUntil = scheduledAt + Service.SCHEDULE_WINDOW_HOURS,
        }
    end
    return nil
end

function Service.GetActionPlan(record, hours)
    hours = tonumber(hours)
        or (Service.GetWorldAgeHours and Service.GetWorldAgeHours() or 0)
    local day = math.floor(hours / 24)
    local key = nightKey(hours)
    local nightStart, nightEnd = nightBounds(key)
    local schedule = Service.ScheduleState(record)
    local sleepKey = "sleep:" .. tostring(key)
    if hours >= nightStart
        and hours < nightEnd - Service.NIGHT_MIN_REMAINING_HOURS
        and schedule.lastAttemptKey ~= sleepKey
    then
        local wakeOffset = seededRange(record,
            "roam_ambient:sleep_wake:" .. tostring(key),
            -Service.SLEEP_WAKE_OFFSET_MINUTES,
            Service.SLEEP_WAKE_OFFSET_MINUTES) / 60
        return {
            action = "sleep", key = sleepKey,
            wakeAt = nightEnd + wakeOffset,
        }
    end
    local slots = Service.EAT_SLOTS or {}
    local index
    local plan
    for index = 1, #slots do
        plan = addSlotPlan(record, hours, day, slots[index], "eat")
        if plan then return plan end
    end
    slots = Service.DRINK_SLOTS or {}
    for index = 1, #slots do
        plan = addSlotPlan(record, hours, day, slots[index], "drink")
        if plan then return plan end
    end
    return nil
end

return Service
