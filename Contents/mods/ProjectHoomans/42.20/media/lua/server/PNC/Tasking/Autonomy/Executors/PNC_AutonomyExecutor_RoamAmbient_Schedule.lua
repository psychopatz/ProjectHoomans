-- Seeded daily eating, drinking, and sleep windows for roaming ambience.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AutonomyExecutors = PNC.AutonomyExecutors or {}
PNC.AutonomyExecutors.RoamAmbient = PNC.AutonomyExecutors.RoamAmbient or {}

local Service = PNC.AutonomyExecutors.RoamAmbient

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

local function nightRemainingHours(timeOfDay)
    local clock = PNC.WorldClock
    if clock and type(clock.NightRemainingHours) == "function" then
        return clock.NightRemainingHours(timeOfDay)
    end
    local endH = tonumber(Service.NIGHT_END_HOUR) or 6
    local startH = tonumber(Service.CAMP_START_HOUR or Service.NIGHT_START_HOUR) or 19
    local tod = (tonumber(timeOfDay) or 0) % 24
    if tod >= startH then
        return (24 - tod) + endH
    end
    if tod < endH then
        return endH - tod
    end
    return 0
end

local function nightCycleKey(hours, timeOfDay)
    local clock = PNC.WorldClock
    if clock and type(clock.NightCycleKey) == "function" then
        return clock.NightCycleKey(hours, timeOfDay)
    end
    local tod = (tonumber(timeOfDay) or 0) % 24
    local remaining = nightRemainingHours(tod)
    local dawnWorldHour = math.floor((hours + remaining) / 24 + 0.5)
    return dawnWorldHour, hours + remaining
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

function Service.GetActionPlan(record, hours, timeOfDayOverride)
    hours = tonumber(hours)
        or (Service.GetWorldAgeHours and Service.GetWorldAgeHours() or 0)
    local tod = tonumber(timeOfDayOverride)
    if tod == nil then
        tod = Service.GetTimeOfDay and Service.GetTimeOfDay(hours) or (hours % 24)
    end
    local day = math.floor(hours / 24)
    local schedule = Service.ScheduleState(record)
    local isNight = Service.IsNightCampHour and Service.IsNightCampHour(tod)
        or (tod >= (tonumber(Service.NIGHT_START_HOUR) or 19)
            or tod < (tonumber(Service.NIGHT_END_HOUR) or 6))
    local remaining = nightRemainingHours(tod)
    if isNight and remaining > (tonumber(Service.NIGHT_MIN_REMAINING_HOURS) or 1) then
        local key, nightEnd = nightCycleKey(hours, tod)
        local sleepKey = "sleep:" .. tostring(key)
        if schedule.lastAttemptKey ~= sleepKey then
            local wakeOffset = seededRange(record,
                "roam_ambient:sleep_wake:" .. tostring(key),
                -Service.SLEEP_WAKE_OFFSET_MINUTES,
                Service.SLEEP_WAKE_OFFSET_MINUTES) / 60
            return {
                action = "sleep", key = sleepKey,
                wakeAt = nightEnd + wakeOffset,
                timeOfDay = tod,
            }
        end
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
