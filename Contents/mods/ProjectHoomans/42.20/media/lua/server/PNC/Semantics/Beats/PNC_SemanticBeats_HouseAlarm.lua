-- House alarm world/ambient sound beat hook.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local ALARM_DEDUPE_MS = 65000
local ALARM_RETRY_MS = 3000
local ALARM_SILENCE_END_MS = 7000
local ALARM_AMBIENT_DURATION_MS = 50000
local ALARM_BUCKET_TILES = 16
local ALARM_HEAR_RADIUS = 32
local MAX_BUCKETS = 32

local seenBuckets = {}
local seenBucketCount = 0
local retryBuckets = {}
local retryBucketCount = 0
local activeAlarms = {}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    if type(getTimestampMs) == "function" then
        return tonumber(getTimestampMs()) or 0
    end
    return 0
end

local function bucketKey(x, y)
    local bx = math.floor(x / ALARM_BUCKET_TILES)
    local by = math.floor(y / ALARM_BUCKET_TILES)
    return tostring(bx) .. ":" .. tostring(by)
end

local function isBucketRecent(map, key, now, windowMs)
    local last = map[key]
    return last ~= nil and now >= last and (now - last) < windowMs
end

local function markBucket(map, count, key, now)
    if map[key] == nil then
        count = count + 1
        if count > MAX_BUCKETS then
            map = {}
            count = 1
        end
    end
    map[key] = now
    return map, count
end

local function isAlarmSource(source)
    if source == nil then return false end
    if type(instanceof) == "function" and instanceof(source, "Alarm") == true then
        return true
    end
    -- In SP, zombie.iso.Alarm is not registered in LuaManager.exposer.typeMap,
    -- so instanceof(source, "Alarm") always returns false. typeof and
    -- getClassSimpleName read Object.getClass().getSimpleName() directly.
    if type(typeof) == "function" and typeof(source) == "Alarm" then
        return true
    end
    if type(getClassSimpleName) == "function" and getClassSimpleName(source) == "Alarm" then
        return true
    end
    if type(source) == "table" and (source._class == "Alarm" or source.isAlarm == true) then
        return true
    end
    return false
end

function Beats.GetHouseAlarmAuditState()
    return {
        dedupeMs = ALARM_DEDUPE_MS,
        retryMs = ALARM_RETRY_MS,
        hearRadius = ALARM_HEAR_RADIUS,
        bucketTiles = ALARM_BUCKET_TILES,
        seenBucketCount = seenBucketCount,
        retryBucketCount = retryBucketCount,
    }
end

local function describeSourceType(source)
    if source == nil then return "nil" end
    if type(typeof) == "function" then
        local ok, t = pcall(typeof, source)
        if ok and t ~= nil then return tostring(t) end
    end
    if type(getClassSimpleName) == "function" then
        local ok, n = pcall(getClassSimpleName, source)
        if ok and n ~= nil then return tostring(n) end
    end
    if type(source) == "table" and source._class ~= nil then
        return tostring(source._class)
    end
    return type(source)
end

function Beats.OnHouseAlarmSignal(x, y, z, now)
    local audit = type(Beats.IsAuditEnabled) == "function" and Beats.IsAuditEnabled() == true
    local nx = tonumber(x)
    local ny = tonumber(y)
    if not nx or not ny then
        if audit then
            Beats.AuditLog("house_alarm_signal", {
                "x=" .. tostring(x),
                "y=" .. tostring(y),
                "ok=false",
                "reason=alarm_position_invalid",
            })
        end
        return false, "alarm_position_invalid"
    end
    now = nowMs(now)
    local key = bucketKey(nx, ny)
    if activeAlarms[key] then
        activeAlarms[key].lastPulseAt = now
    end
    if isBucketRecent(seenBuckets, key, now, ALARM_DEDUPE_MS) then
        if audit then
            Beats.AuditLog("house_alarm_signal", {
                "x=" .. tostring(math.floor(nx)),
                "y=" .. tostring(math.floor(ny)),
                "bucket=" .. key,
                "ok=false",
                "reason=alarm_deduped",
            })
        end
        return false, "alarm_deduped"
    end
    if isBucketRecent(retryBuckets, key, now, ALARM_RETRY_MS) then
        return false, "alarm_retry_cooldown"
    end
    local coreAdapter = PsychopatzCore and PsychopatzCore.WorldEventAdapter or nil
    if type(coreAdapter) == "table" and type(coreAdapter.OnAmbientSound) == "function" then
        coreAdapter.OnAmbientSound("burglar2", nx, ny)
    end
    local ok, result, groupCount = false, "no_calm_speaker", 0
    if type(Beats.EmitForNearbyGroups) == "function" then
        ok, result, groupCount = Beats.EmitForNearbyGroups("environment.house_alarm", {
            x = nx,
            y = ny,
            z = tonumber(z) or 0,
        }, now, ALARM_HEAR_RADIUS, 3)
    else
        local anchor, partner = nil, nil
        if type(Beats.FindCalmSpeakerNearPoint) == "function" then
            anchor, partner = Beats.FindCalmSpeakerNearPoint(nx, ny, ALARM_HEAR_RADIUS, now)
        end
        if anchor then
            ok, result = Beats.Emit("environment.house_alarm", {
                x = nx, y = ny, z = tonumber(z) or 0, anchor = anchor, partner = partner,
            }, now)
            groupCount = ok and 1 or 0
        end
    end
    if ok then
        seenBuckets, seenBucketCount = markBucket(seenBuckets, seenBucketCount, key, now)
        retryBuckets[key] = nil
        activeAlarms[key] = {
            x = nx,
            y = ny,
            z = tonumber(z) or 0,
            startedAt = now,
            lastPulseAt = now,
            expectedEndAt = now + ALARM_AMBIENT_DURATION_MS,
        }
    else
        retryBuckets, retryBucketCount = markBucket(retryBuckets, retryBucketCount, key, now)
    end
    if audit then
        Beats.AuditLog("house_alarm_signal", {
            "x=" .. tostring(math.floor(nx)),
            "y=" .. tostring(math.floor(ny)),
            "bucket=" .. key,
            "hearRadius=" .. tostring(ALARM_HEAR_RADIUS),
            "groups=" .. tostring(groupCount or 0),
            "ok=" .. tostring(ok == true),
            "result=" .. tostring(result or "nil"),
        })
    end
    return ok, result
end

function Beats.CheckHouseAlarmEnded(at)
    local now = nowMs(at)
    local endedAny = false
    local doneKeys = {}
    for key, info in pairs(activeAlarms) do
        local silentMs = now - (tonumber(info.lastPulseAt) or now)
        if silentMs >= ALARM_SILENCE_END_MS or now >= (tonumber(info.expectedEndAt) or math.huge) then
            doneKeys[#doneKeys + 1] = key
        end
    end
    for i = 1, #doneKeys do
        local key = doneKeys[i]
        local info = activeAlarms[key]
        activeAlarms[key] = nil
        if info and type(Beats.EmitForNearbyGroups) == "function" then
            local ok, res, count = Beats.EmitForNearbyGroups("environment.house_alarm_ended", {
                x = info.x,
                y = info.y,
                z = info.z,
            }, now, ALARM_HEAR_RADIUS, 3)
            if ok then endedAny = true end
            if type(Beats.IsAuditEnabled) == "function" and Beats.IsAuditEnabled() == true then
                Beats.AuditLog("house_alarm_ended", {
                    "bucket=" .. tostring(key),
                    "groups=" .. tostring(count or 0),
                    "ok=" .. tostring(ok == true),
                    "result=" .. tostring(res or "nil"),
                })
            end
        end
    end
    return endedAny
end

function Beats.ResetHouseAlarmRuntime()
    seenBuckets = {}
    seenBucketCount = 0
    retryBuckets = {}
    retryBucketCount = 0
    activeAlarms = {}
end

Beats.RegisterHook("environment.house_alarm", {
    eventTypes = { "environment.house_alarm" },
    priority = 42,
    cooldownMs = 0,
    evaluate = function(_, payload)
        local a = payload.anchor or payload.speaker
        local b = payload.partner or payload.addressee
        if type(Beats.BuildWorldThread) ~= "function" then return nil end
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "world:house_alarm:" .. tostring(payload.groupIndex or 1),
            family = "world_house_alarm",
            poolID = "semantic.world.alarm.react",
            eventType = "world_event_beat",
            domain = "world",
            channel = "world",
            topic = "world_event",
            openAct = "WARN",
            replyAct = "REACT",
            openRole = "house_alarm_open",
            replyRole = "house_alarm_reply",
            chimeRole = "house_alarm_chime",
            third = payload.third,
            openingDelayMs = payload.openingDelayMs,
            priority = 42,
            delayMs = 950,
            chimeDelayMs = 2100,
        })
    end,
})

Beats.RegisterHook("environment.house_alarm_ended", {
    eventTypes = { "environment.house_alarm_ended" },
    priority = 40,
    cooldownMs = 0,
    evaluate = function(_, payload)
        local a = payload.anchor or payload.speaker
        local b = payload.partner or payload.addressee
        if type(Beats.BuildWorldThread) ~= "function" then return nil end
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "world:house_alarm_ended:" .. tostring(payload.groupIndex or 1),
            family = "world_house_alarm_ended",
            poolID = "semantic.world.alarm.react",
            eventType = "world_event_beat",
            domain = "world",
            channel = "world",
            topic = "world_event",
            openAct = "REACT",
            replyAct = "REACT",
            openRole = "house_alarm_ended_open",
            replyRole = "house_alarm_ended_reply",
            chimeRole = "house_alarm_ended_chime",
            third = payload.third,
            openingDelayMs = payload.openingDelayMs,
            priority = 40,
            delayMs = 1050,
            chimeDelayMs = 2250,
        })
    end,
})

local function onWorldSound(x, y, z, radius, volume, source)
    if source == nil then return end
    local matched = isAlarmSource(source)
    if not matched then
        if (tonumber(radius) or 0) >= 400
            and type(Beats.IsAuditEnabled) == "function"
            and Beats.IsAuditEnabled() == true
        then
            Beats.AuditLog("house_alarm_world_sound", {
                "x=" .. tostring(x),
                "y=" .. tostring(y),
                "z=" .. tostring(z),
                "radius=" .. tostring(radius),
                "volume=" .. tostring(volume),
                "sourceType=" .. describeSourceType(source),
                "isAlarm=false",
            })
        end
        return
    end
    if type(Beats.IsAuditEnabled) == "function" and Beats.IsAuditEnabled() == true then
        Beats.AuditLog("house_alarm_world_sound", {
            "x=" .. tostring(x),
            "y=" .. tostring(y),
            "z=" .. tostring(z),
            "radius=" .. tostring(radius),
            "volume=" .. tostring(volume),
            "sourceType=" .. describeSourceType(source),
            "isAlarm=true",
        })
    end
    Beats.OnHouseAlarmSignal(x, y, z, nil)
end

local function onAmbientSound(name, x, y)
    local matched = tostring(name or "") == "burglar2"
    if type(Beats.IsAuditEnabled) == "function" and Beats.IsAuditEnabled() == true then
        Beats.AuditLog("house_alarm_ambient_sound", {
            "name=" .. tostring(name or ""),
            "x=" .. tostring(x),
            "y=" .. tostring(y),
            "matched=" .. tostring(matched),
        })
    end
    if matched then
        Beats.OnHouseAlarmSignal(x, y, 0, nil)
    end
end

if Events and Events.OnWorldSound and not Beats._HouseAlarmWorldSoundHooked then
    Events.OnWorldSound.Add(onWorldSound)
    Beats._HouseAlarmWorldSoundHooked = true
end

if Events and Events.OnAmbientSound and not Beats._HouseAlarmAmbientSoundHooked then
    Events.OnAmbientSound.Add(onAmbientSound)
    Beats._HouseAlarmAmbientSoundHooked = true
end

return Beats
