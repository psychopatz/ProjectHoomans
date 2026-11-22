-- Same-day electricity and water shutoff beat hooks.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local lastPowerState = nil
local lastWaterState = nil
local emittedPowerDay = nil
local emittedWaterDay = nil

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

local function makeUtilityHook(id, eventName, openRole, replyRole, fam, refPrefix)
    Beats.RegisterHook(id, {
        eventTypes = { eventName },
        priority = 36,
        cooldownMs = 180000,
        evaluate = function(_, payload)
            local a = payload.anchor or payload.speaker
            local b = payload.partner or payload.addressee
            if type(Beats.BuildWorldThread) ~= "function" then return nil end
            return Beats.BuildWorldThread(a, b, {
                refPrefix = refPrefix,
                family = fam,
                poolID = "semantic.world.utility.outage",
                eventType = "world_event_beat",
                topic = "world_event",
                openAct = "REACT",
                replyAct = "REACT",
                openRole = openRole,
                replyRole = replyRole,
                priority = 36,
                delayMs = 950,
            })
        end,
    })
end

makeUtilityHook(
    "environment.power_shutoff",
    "environment.power_shutoff",
    "power_shutoff_open",
    "power_shutoff_reply",
    "world_power_shutoff",
    "world:power_shutoff"
)

makeUtilityHook(
    "environment.water_shutoff",
    "environment.water_shutoff",
    "water_shutoff_open",
    "water_shutoff_reply",
    "world_water_shutoff",
    "world:water_shutoff"
)

local function tryEmitUtilityEvent(eventName, day, env, now)
    local a, b = nil, nil
    if type(Beats.FindCalmSpeakerNearPlayer) == "function" then
        a, b = Beats.FindCalmSpeakerNearPlayer(now)
    elseif type(Beats.FindCalmPairNearPlayer) == "function" then
        a, b = Beats.FindCalmPairNearPlayer(now)
    end
    if not a then
        return false
    end
    return Beats.Emit(eventName, {
        currentDay = day,
        anchor = a,
        partner = b,
        env = env,
    }, now)
end

function Beats.CheckUtilities(now)
    now = nowMs(now)
    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    if not BC or type(BC.GetWorldUtilities) ~= "function" then
        return false
    end
    local u = BC.GetWorldUtilities(now)
    if type(u) ~= "table" then
        return false
    end
    local day = tonumber(u.currentDay) or 0
    local emitted = false

    local powerFell = (lastPowerState == true and u.powerOn == false)
        or (u.powerOutToday == true)
    lastPowerState = u.powerOn
    if powerFell and emittedPowerDay ~= day then
        local ok = tryEmitUtilityEvent("environment.power_shutoff", day, u, now)
        if ok then
            emittedPowerDay = day
            emitted = true
        end
    end

    local waterFell = (lastWaterState == true and u.waterOn == false)
        or (u.waterOutToday == true)
    lastWaterState = u.waterOn
    if waterFell and emittedWaterDay ~= day then
        local ok = tryEmitUtilityEvent("environment.water_shutoff", day, u, now)
        if ok then
            emittedWaterDay = day
            emitted = true
        end
    end

    return emitted
end

function Beats.ResetUtilitiesRuntime()
    lastPowerState = nil
    lastWaterState = nil
    emittedPowerDay = nil
    emittedWaterDay = nil
end

local function onElectricityChanged()
    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    local now = nowMs(nil)
    if BC and type(BC.GetWorldUtilities) == "function" then
        BC.GetWorldUtilities(now, true)
    end
    Beats.CheckUtilities(now)
end

if Events and Events.OnElectricityChanged and not Beats._UtilitiesElectricityHooked then
    Events.OnElectricityChanged.Add(onElectricityChanged)
    Beats._UtilitiesElectricityHooked = true
end

return Beats
