-- House alarm world/ambient sound beat hook.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local ALARM_DEDUPE_MS = 65000
local ALARM_BUCKET_TILES = 16
local ALARM_HEAR_RADIUS = 32
local MAX_BUCKETS = 32

local seenBuckets = {}
local seenBucketCount = 0

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

local function markAndCheckBucket(x, y, now)
    local bx = math.floor(x / ALARM_BUCKET_TILES)
    local by = math.floor(y / ALARM_BUCKET_TILES)
    local key = tostring(bx) .. ":" .. tostring(by)
    local last = seenBuckets[key]
    if last ~= nil and now >= last and (now - last) < ALARM_DEDUPE_MS then
        return false
    end
    if last == nil then
        seenBucketCount = seenBucketCount + 1
        if seenBucketCount > MAX_BUCKETS then
            seenBuckets = {}
            seenBucketCount = 1
        end
    end
    seenBuckets[key] = now
    return true
end

function Beats.OnHouseAlarmSignal(x, y, z, now)
    local nx = tonumber(x)
    local ny = tonumber(y)
    if not nx or not ny then
        return false, "alarm_position_invalid"
    end
    now = nowMs(now)
    if not markAndCheckBucket(nx, ny, now) then
        return false, "alarm_deduped"
    end
    local anchor, partner = nil, nil
    if type(Beats.FindCalmSpeakerNearPoint) == "function" then
        anchor, partner = Beats.FindCalmSpeakerNearPoint(nx, ny, ALARM_HEAR_RADIUS, now)
    end
    if not anchor then
        return false, "no_calm_speaker"
    end
    return Beats.Emit("environment.house_alarm", {
        x = nx,
        y = ny,
        z = tonumber(z) or 0,
        anchor = anchor,
        partner = partner,
    }, now)
end

function Beats.ResetHouseAlarmRuntime()
    seenBuckets = {}
    seenBucketCount = 0
end

Beats.RegisterHook("environment.house_alarm", {
    eventTypes = { "environment.house_alarm" },
    priority = 42,
    cooldownMs = 45000,
    evaluate = function(_, payload)
        local a = payload.anchor or payload.speaker
        local b = payload.partner or payload.addressee
        if type(Beats.BuildWorldThread) ~= "function" then return nil end
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "world:house_alarm",
            family = "world_house_alarm",
            poolID = "semantic.world.alarm.react",
            eventType = "world_event_beat",
            topic = "world_event",
            openAct = "WARN",
            replyAct = "REACT",
            openRole = "house_alarm_open",
            replyRole = "house_alarm_reply",
            priority = 42,
            delayMs = 950,
        })
    end,
})

local function onWorldSound(x, y, z, _, _, source)
    if source == nil then return end
    local isAlarm = (type(instanceof) == "function" and instanceof(source, "Alarm") == true)
        or (type(source) == "table" and source.isAlarm == true)
    if isAlarm then
        Beats.OnHouseAlarmSignal(x, y, z, nil)
    end
end

local function onAmbientSound(name, x, y)
    if tostring(name or "") == "burglar2" then
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
