-- Event-driven vehicle & road-trip banter beats (zero polling).
-- Hooks PZ's native Events.OnEnterVehicle / Events.OnExitVehicle and checks
-- BaseVehicle.getRemainingFuelPercentage() for low-fuel warnings.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local ENTER_COOLDOWN_MS = 120000
local EXIT_COOLDOWN_MS = 150000
local LOW_FUEL_COOLDOWN_MS = 180000
local LOW_FUEL_THRESHOLD_PCT = 15

local nextEnterAt = 0
local nextExitAt = 0
local nextLowFuelAt = 0

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

local function safeCall(obj, methodName, ...)
    local fn = obj and obj[methodName]
    if type(fn) ~= "function" then return nil end
    local ok, val = pcall(fn, obj, ...)
    return ok and val or nil
end

local function auditEnabled()
    return type(Beats.IsAuditEnabled) == "function" and Beats.IsAuditEnabled() == true
end

Beats.RegisterHook("world.vehicle_banter", {
    eventTypes = { "world.vehicle_banter" },
    priority = 30,
    cooldownMs = 0,
    evaluate = function(_, payload)
        local kind = tostring(payload.kind or "vehicle_enter")
        local a = payload.anchor or payload.speaker
        if type(a) ~= "table" or a.alive == false then return nil end
        local b = payload.partner or payload.addressee
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "vehicle:" .. kind .. ":" .. tostring(payload.groupIndex or 1),
            family = "world_vehicle_" .. kind,
            poolID = "semantic.world.vehicle.banter",
            eventType = "world_vehicle_beat",
            domain = "travel",
            channel = "travel",
            topic = "road_morale",
            openAct = kind == "vehicle_low_fuel" and "WARN" or "CHAT",
            replyAct = "AGREE",
            openRole = kind .. "_open",
            replyRole = kind .. "_reply",
            chimeRole = kind .. "_chime",
            third = payload.third,
            openingDelayMs = payload.openingDelayMs,
            priority = kind == "vehicle_low_fuel" and 34 or 29,
            delayMs = 950,
            chimeDelayMs = 2150,
        })
    end,
})

function Beats.OnVehicleEntered(character, at)
    local now = nowMs(at)
    local vehicle = safeCall(character, "getVehicle")
    local fuelPct = vehicle and tonumber(safeCall(vehicle, "getRemainingFuelPercentage")) or nil

    local kind = "vehicle_enter"
    local nextAllowed = nextEnterAt
    if fuelPct ~= nil and fuelPct <= LOW_FUEL_THRESHOLD_PCT and now >= nextLowFuelAt then
        kind = "vehicle_low_fuel"
        nextAllowed = nextLowFuelAt
    elseif now < nextEnterAt then
        if auditEnabled() then
            Beats.AuditLog("vehicle_event", {
                "action=enter",
                "kind=" .. kind,
                "fuelPct=" .. tostring(fuelPct and math.floor(fuelPct) or "nil"),
                "decision=skip",
                "reason=cooldown:" .. tostring(math.floor(nextEnterAt - now)) .. "ms",
            })
        end
        return false
    end

    if now < nextAllowed then return false end

    local ok, reason, count = Beats.EmitForNearbyGroups("world.vehicle_banter", {
        kind = kind,
        fuelPct = fuelPct,
        usePlayerProximity = true,
    }, now, 18, 1)
    if ok then
        if kind == "vehicle_low_fuel" then
            nextLowFuelAt = now + LOW_FUEL_COOLDOWN_MS
        else
            nextEnterAt = now + ENTER_COOLDOWN_MS
        end
    end
    if auditEnabled() then
        Beats.AuditLog("vehicle_event", {
            "action=enter",
            "kind=" .. kind,
            "fuelPct=" .. tostring(fuelPct and math.floor(fuelPct) or "nil"),
            "decision=" .. (ok and "emit" or "skip"),
            "reason=" .. tostring(ok and "ok" or (reason or "no_groups")),
            "groups=" .. tostring(count or 0),
        })
    end
    return ok == true, reason
end

function Beats.OnVehicleExited(character, at)
    local now = nowMs(at)
    if now < nextExitAt then
        if auditEnabled() then
            Beats.AuditLog("vehicle_event", {
                "action=exit",
                "decision=skip",
                "reason=cooldown:" .. tostring(math.floor(nextExitAt - now)) .. "ms",
            })
        end
        return false
    end
    local ok, reason, count = Beats.EmitForNearbyGroups("world.vehicle_banter", {
        kind = "vehicle_exit",
        usePlayerProximity = true,
    }, now, 18, 1)
    if ok then
        nextExitAt = now + EXIT_COOLDOWN_MS
    end
    if auditEnabled() then
        Beats.AuditLog("vehicle_event", {
            "action=exit",
            "kind=vehicle_exit",
            "decision=" .. (ok and "emit" or "skip"),
            "reason=" .. tostring(ok and "ok" or (reason or "no_groups")),
            "groups=" .. tostring(count or 0),
        })
    end
    return ok == true, reason
end

function Beats.ResetVehicleBeatsRuntime()
    nextEnterAt = 0
    nextExitAt = 0
    nextLowFuelAt = 0
end

if Events and not Beats._VehicleEventsHooked then
    if Events.OnEnterVehicle and type(Events.OnEnterVehicle.Add) == "function" then
        Events.OnEnterVehicle.Add(function(character)
            Beats.OnVehicleEntered(character)
        end)
    end
    if Events.OnExitVehicle and type(Events.OnExitVehicle.Add) == "function" then
        Events.OnExitVehicle.Add(function(character)
            Beats.OnVehicleExited(character)
        end)
    end
    Beats._VehicleEventsHooked = true
end

return Beats
