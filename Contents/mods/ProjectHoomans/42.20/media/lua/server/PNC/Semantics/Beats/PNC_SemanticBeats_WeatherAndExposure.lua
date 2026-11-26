-- Reactive weather, thunder/lightning, and player exposure suggestion beats.
-- Event-driven for Events.OnThunderEvent (zero polling) and data-driven for all
-- Build 42 ClimateManager/WeatherPeriod conditions and player outdoor exposure.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local THUNDER_STRIKE_COOLDOWN_MS = 45000
local THUNDER_RUMBLE_COOLDOWN_MS = 75000
local THUNDER_STRIKE_MAX_DIST = 4500
local THUNDER_RUMBLE_MAX_DIST = 6500
local WEATHER_CONDITION_COOLDOWN_MS = 180000
local EXPOSURE_GLOBAL_COOLDOWN_MS = 95000
local EXPOSURE_CONDITION_COOLDOWN_MS = 180000
local RAIN_OUTDOOR_DWELL_MS = 15000

local nextThunderStrikeAt = 0
local nextThunderRumbleAt = 0
local nextExposureGlobalAt = 0
local lastWeatherByKey = {}
local lastExposureByCondition = {}
local outdoorRainSinceAt = nil
local lastEvaluatedCondition = "none"

local WEATHER_HOOK_SPECS = {
    blizzard = {
        poolID = "semantic.world.weather.snow",
        family = "environment_weather_blizzard",
        openRole = "weather_blizzard_open",
        replyRole = "weather_blizzard_reply",
        chimeRole = "weather_blizzard_chime",
        priority = 36,
    },
    tropical_storm = {
        poolID = "semantic.world.weather.rain",
        family = "environment_weather_storm",
        openRole = "weather_storm_open",
        replyRole = "weather_storm_reply",
        chimeRole = "weather_storm_chime",
        priority = 35,
    },
    thunderstorm = {
        poolID = "semantic.world.weather.rain",
        family = "environment_weather_storm",
        openRole = "weather_storm_open",
        replyRole = "weather_storm_reply",
        chimeRole = "weather_storm_chime",
        priority = 34,
    },
    storm = {
        poolID = "semantic.world.weather.rain",
        family = "environment_weather_storm",
        openRole = "weather_storm_open",
        replyRole = "weather_storm_reply",
        chimeRole = "weather_storm_chime",
        priority = 33,
    },
    rain = {
        poolID = "semantic.world.weather.rain",
        family = "environment_weather_rain",
        openRole = "weather_rain_open",
        replyRole = "weather_rain_reply",
        chimeRole = "weather_rain_chime",
        priority = 30,
    },
    snow = {
        poolID = "semantic.world.weather.snow",
        family = "environment_weather_snow",
        openRole = "weather_snow_open",
        replyRole = "weather_snow_reply",
        chimeRole = "weather_snow_chime",
        priority = 30,
    },
    fog = {
        poolID = "semantic.world.weather.fog",
        family = "environment_weather_fog",
        openRole = "weather_fog_open",
        replyRole = "weather_fog_reply",
        chimeRole = "weather_fog_chime",
        priority = 29,
    },
    wind = {
        poolID = "semantic.world.weather.wind",
        family = "environment_weather_wind",
        openRole = "weather_wind_open",
        replyRole = "weather_wind_reply",
        chimeRole = "weather_wind_chime",
        priority = 28,
    },
    cold = {
        poolID = "semantic.world.weather.temperature",
        family = "environment_weather_cold",
        openRole = "weather_cold_open",
        replyRole = "weather_cold_reply",
        chimeRole = "weather_cold_chime",
        priority = 28,
    },
    heat = {
        poolID = "semantic.world.weather.temperature",
        family = "environment_weather_heat",
        openRole = "weather_heat_open",
        replyRole = "weather_heat_reply",
        chimeRole = "weather_heat_chime",
        priority = 28,
    },
}

local EXPOSURE_PRIORITY = {
    "soaking_wet_rain",
    "freezing_exposure",
    "overheating_exposure",
    "catching_cold",
    "exposed_rain",
    "exposed_harsh_weather",
}

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

local function auditEnabled()
    return type(Beats.IsAuditEnabled) == "function" and Beats.IsAuditEnabled() == true
end

local function nearestPlayerDist(x, y)
    local best = nil
    local function checkPlayer(p)
        if not p then return end
        local okX, px = pcall(p.getX, p)
        local okY, py = pcall(p.getY, p)
        if not okX or not okY then return end
        px, py = tonumber(px), tonumber(py)
        if not px or not py then return end
        local dx, dy = px - x, py - y
        local d = math.sqrt(dx * dx + dy * dy)
        if best == nil or d < best then best = d end
    end
    if type(getPlayer) == "function" then
        local ok, p = pcall(getPlayer)
        if ok and p then checkPlayer(p) end
    end
    if best == nil and type(getOnlinePlayers) == "function" then
        local ok, list = pcall(getOnlinePlayers)
        if ok and list and type(list.size) == "function" then
            for i = 0, list:size() - 1 do
                checkPlayer(list:get(i))
            end
        end
    end
    return best
end

local function resolveExposureCondition(env, exp, now)
    if type(exp) ~= "table" or exp.hasPlayer ~= true then
        outdoorRainSinceAt = nil
        return nil, "no_player"
    end
    local isRain = env and env.isRaining == true
    if exp.isOutside and isRain then
        if outdoorRainSinceAt == nil then outdoorRainSinceAt = now end
    else
        outdoorRainSinceAt = nil
    end

    if exp.isOutside and exp.isSoakingWet then
        return "soaking_wet_rain", "soaking_wet_outside"
    end
    if exp.isOutside and (exp.isFreezing or (exp.isChilly and env and (env.isSnowing or env.isCold))) then
        return "freezing_exposure", "freezing_outside"
    end
    if exp.isOutside and (exp.isOverheating or (exp.isHot and env and env.isHot)) then
        return "overheating_exposure", "overheating_outside"
    end
    if exp.hasCold and (exp.isOutside or exp.isSoakingWet) then
        return "catching_cold", "player_has_cold"
    end
    if exp.isOutside and isRain and outdoorRainSinceAt ~= nil
        and (now - outdoorRainSinceAt) >= RAIN_OUTDOOR_DWELL_MS
    then
        return "exposed_rain", "outdoor_rain_dwell"
    end
    if exp.isOutside and env and env.isHarshWeather == true then
        local w = tostring(env.weather or "")
        if w == "blizzard" or w == "tropical_storm" or w == "thunderstorm"
            or w == "storm" or w == "fog" or w == "wind"
        then
            return "exposed_harsh_weather", "outside_" .. w
        end
    end
    return nil, exp.isOutside and "comfortable_outside" or "indoors"
end

-- Hook: all non-rain weather transitions (snow, blizzard, fog, wind, cold, heat, storm).
-- Rain itself continues to work through environment.weather_rain or this generalized hook.
Beats.RegisterHook("environment.weather_condition", {
    eventTypes = { "environment.weather_condition_changed" },
    priority = 32,
    cooldownMs = 0,
    evaluate = function(_, payload, ctx)
        local w = tostring(payload.weather or (ctx and ctx.env and ctx.env.weather) or "")
        local spec = WEATHER_HOOK_SPECS[w]
        if not spec then return nil end
        local a, b = payload.anchor or payload.speaker, payload.partner or payload.addressee
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "weather:" .. w .. ":" .. tostring(payload.groupIndex or 1),
            family = spec.family,
            poolID = spec.poolID,
            eventType = "world_weather_beat",
            domain = "weather",
            channel = "weather",
            topic = "weather",
            openAct = "REACT",
            replyAct = "REACT",
            openRole = spec.openRole,
            replyRole = spec.replyRole,
            chimeRole = spec.chimeRole,
            third = payload.third,
            openingDelayMs = payload.openingDelayMs,
            priority = spec.priority,
            delayMs = 950,
            chimeDelayMs = 2200,
        })
    end,
})

-- Hook: startled thunderclap / distant lightning rumble (event-driven via Events.OnThunderEvent).
Beats.RegisterHook("environment.weather_thunder", {
    eventTypes = { "environment.thunder_event" },
    priority = 41,
    cooldownMs = 0,
    evaluate = function(_, payload)
        local isStrike = payload.isStrike == true
        local prefix = isStrike and "thunder_strike" or "thunder_rumble"
        local a, b = payload.anchor or payload.speaker, payload.partner or payload.addressee
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "weather:thunder:" .. prefix .. ":" .. tostring(payload.groupIndex or 1),
            family = isStrike and "environment_thunder_strike" or "environment_thunder_rumble",
            poolID = "semantic.world.weather.thunder",
            eventType = "world_weather_thunder_beat",
            domain = "weather",
            channel = "weather",
            topic = "weather",
            openAct = isStrike and "WARN" or "REACT",
            replyAct = "REACT",
            openRole = prefix .. "_open",
            replyRole = prefix .. "_reply",
            chimeRole = prefix .. "_chime",
            third = payload.third,
            openingDelayMs = payload.openingDelayMs,
            priority = isStrike and 41 or 33,
            delayMs = isStrike and 750 or 1050,
            chimeDelayMs = 2100,
        })
    end,
})

-- Hook: reactive character exposure + actionable shelter/shade/warmth suggestion.
Beats.RegisterHook("environment.player_exposure", {
    eventTypes = { "environment.player_exposure" },
    priority = 31,
    cooldownMs = 0,
    evaluate = function(_, payload)
        local condition = tostring(payload.condition or "")
        if condition == "" then return nil end
        local a, b = payload.anchor or payload.speaker, payload.partner or payload.addressee
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "exposure:" .. condition .. ":" .. tostring(payload.groupIndex or 1),
            family = "environment_exposure_" .. condition,
            poolID = "semantic.world.exposure.suggest",
            eventType = "world_exposure_beat",
            domain = "weather",
            channel = "weather",
            topic = "weather",
            openAct = "SUGGEST",
            replyAct = "AGREE",
            openRole = condition .. "_open",
            replyRole = condition .. "_reply",
            chimeRole = condition .. "_chime",
            third = payload.third,
            openingDelayMs = payload.openingDelayMs,
            priority = 31,
            delayMs = 1050,
            chimeDelayMs = 2300,
        })
    end,
})

function Beats.OnThunderEvent(x, y, doStrike, doLightning, doRumble, at)
    local now = nowMs(at)
    local isStrike = doStrike == true
    local isLightning = doLightning == true
    local isRumble = doRumble == true
    if not isStrike and not isLightning and not isRumble then return false end

    local tx, ty = tonumber(x) or 0, tonumber(y) or 0
    local dist = nearestPlayerDist(tx, ty)
    local maxDist = isStrike and THUNDER_STRIKE_MAX_DIST or THUNDER_RUMBLE_MAX_DIST
    if dist ~= nil and dist > maxDist then
        if auditEnabled() then
            Beats.AuditLog("thunder_event", {
                "x=" .. tostring(math.floor(tx)),
                "y=" .. tostring(math.floor(ty)),
                "dist=" .. tostring(math.floor(dist)),
                "strike=" .. tostring(isStrike),
                "lightning=" .. tostring(isLightning),
                "rumble=" .. tostring(isRumble),
                "decision=skip",
                "reason=too_far",
            })
        end
        return false
    end

    local nextAllowed = isStrike and nextThunderStrikeAt or nextThunderRumbleAt
    if now < nextAllowed then
        if auditEnabled() then
            Beats.AuditLog("thunder_event", {
                "x=" .. tostring(math.floor(tx)),
                "y=" .. tostring(math.floor(ty)),
                "dist=" .. tostring(dist and math.floor(dist) or "nil"),
                "strike=" .. tostring(isStrike),
                "lightning=" .. tostring(isLightning),
                "rumble=" .. tostring(isRumble),
                "decision=skip",
                "reason=cooldown:" .. tostring(math.floor(nextAllowed - now)) .. "ms",
            })
        end
        return false
    end

    local ok, reason, count = Beats.EmitForNearbyGroups("environment.thunder_event", {
        x = tx,
        y = ty,
        isStrike = isStrike,
        isLightning = isLightning,
        isRumble = isRumble,
        usePlayerProximity = true,
    }, now, 18, 2)
    if ok then
        if isStrike then
            nextThunderStrikeAt = now + THUNDER_STRIKE_COOLDOWN_MS
            if nextThunderRumbleAt < now + 20000 then
                nextThunderRumbleAt = now + 20000
            end
        else
            nextThunderRumbleAt = now + THUNDER_RUMBLE_COOLDOWN_MS
        end
    end
    if auditEnabled() then
        Beats.AuditLog("thunder_event", {
            "x=" .. tostring(math.floor(tx)),
            "y=" .. tostring(math.floor(ty)),
            "dist=" .. tostring(dist and math.floor(dist) or "nil"),
            "strike=" .. tostring(isStrike),
            "lightning=" .. tostring(isLightning),
            "rumble=" .. tostring(isRumble),
            "decision=" .. (ok and "emit" or "skip"),
            "reason=" .. tostring(ok and "ok" or (reason or "no_groups")),
            "groups=" .. tostring(count or 0),
        })
    end
    return ok, reason
end

function Beats.CheckWeatherAndExposure(now, frame)
    now = nowMs(now)
    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    if not BC or type(BC.GetWorldWeather) ~= "function" then return false end

    local env = (type(frame) == "table" and type(frame.env) == "table")
        and frame.env or BC.GetWorldWeather(now)
    local cur = tostring(env and env.weather or "clear")
    local prev = Beats.LastWeather
    Beats.LastWeather = cur

    local emitted = false
    if prev ~= nil and prev ~= cur and WEATHER_HOOK_SPECS[cur] then
        local lastAt = tonumber(lastWeatherByKey[cur]) or -math.huge
        if now >= lastAt + WEATHER_CONDITION_COOLDOWN_MS then
            local eventName = (cur == "rain" or cur == "storm")
                and "environment.weather_changed" or "environment.weather_condition_changed"
            local ok, reason, count = Beats.EmitForNearbyGroups(eventName, {
                weather = cur,
                previous = prev,
                env = env,
                usePlayerProximity = true,
            }, now, 16, 2)
            if ok then
                lastWeatherByKey[cur] = now
                emitted = true
            end
            if auditEnabled() then
                Beats.AuditLog("weather_eval", {
                    "prev=" .. tostring(prev),
                    "cur=" .. tostring(cur),
                    "decision=" .. (ok and "emit" or "skip"),
                    "reason=" .. tostring(ok and "transition" or (reason or "no_groups")),
                    "groups=" .. tostring(count or 0),
                })
            end
        elseif auditEnabled() then
            Beats.AuditLog("weather_eval", {
                "prev=" .. tostring(prev),
                "cur=" .. tostring(cur),
                "decision=skip",
                "reason=cooldown:" .. tostring(math.floor(lastAt + WEATHER_CONDITION_COOLDOWN_MS - now)) .. "ms",
            })
        end
    end

    if emitted then return true end
    if type(BC.GetPlayerExposure) ~= "function" then return false end

    local exp = BC.GetPlayerExposure(nil, now)
    local condition, evalReason = resolveExposureCondition(env, exp, now)
    lastEvaluatedCondition = condition or evalReason or "none"
    if not condition then
        return false
    end

    if now < nextExposureGlobalAt then
        if auditEnabled() then
            Beats.AuditLog("exposure_eval", {
                "condition=" .. condition,
                "isOutside=" .. tostring(exp.isOutside == true),
                "wetLevel=" .. tostring(exp.wetLevel or 0),
                "wetness=" .. tostring(math.floor(tonumber(exp.wetness) or 0)),
                "decision=skip",
                "reason=global_cd:" .. tostring(math.floor(nextExposureGlobalAt - now)) .. "ms",
            })
        end
        return false
    end

    local condLastAt = tonumber(lastExposureByCondition[condition]) or -math.huge
    if now < condLastAt + EXPOSURE_CONDITION_COOLDOWN_MS then
        if auditEnabled() then
            Beats.AuditLog("exposure_eval", {
                "condition=" .. condition,
                "isOutside=" .. tostring(exp.isOutside == true),
                "wetLevel=" .. tostring(exp.wetLevel or 0),
                "wetness=" .. tostring(math.floor(tonumber(exp.wetness) or 0)),
                "decision=skip",
                "reason=cond_cd:" .. tostring(math.floor(condLastAt + EXPOSURE_CONDITION_COOLDOWN_MS - now)) .. "ms",
            })
        end
        return false
    end

    local ok, reason, count = Beats.EmitForNearbyGroups("environment.player_exposure", {
        condition = condition,
        weather = cur,
        env = env,
        exposure = exp,
        usePlayerProximity = true,
    }, now, 16, 1)
    if ok then
        nextExposureGlobalAt = now + EXPOSURE_GLOBAL_COOLDOWN_MS
        lastExposureByCondition[condition] = now
    end
    if auditEnabled() then
        Beats.AuditLog("exposure_eval", {
            "condition=" .. condition,
            "isOutside=" .. tostring(exp.isOutside == true),
            "wetLevel=" .. tostring(exp.wetLevel or 0),
            "wetness=" .. tostring(math.floor(tonumber(exp.wetness) or 0)),
            "hypo=" .. tostring(exp.hypoLevel or 0),
            "hyper=" .. tostring(exp.hyperLevel or 0),
            "decision=" .. (ok and "emit" or "skip"),
            "reason=" .. tostring(ok and evalReason or (reason or "no_groups")),
            "groups=" .. tostring(count or 0),
        })
    end
    return ok
end

function Beats.GetWeatherExposureAuditState(at)
    local now = nowMs(at)
    return {
        thunderHooked = Beats._ThunderEventHooked == true,
        lastCondition = lastEvaluatedCondition,
        exposureCooldownRemainingMs = math.max(0, math.floor(nextExposureGlobalAt - now)),
        thunderStrikeCooldownRemainingMs = math.max(0, math.floor(nextThunderStrikeAt - now)),
        thunderRumbleCooldownRemainingMs = math.max(0, math.floor(nextThunderRumbleAt - now)),
        outdoorRainDwellMs = outdoorRainSinceAt and math.max(0, math.floor(now - outdoorRainSinceAt)) or 0,
        supportedWeatherCount = 10,
        supportedExposureCount = #EXPOSURE_PRIORITY,
    }
end

function Beats.ResetWeatherExposureRuntime()
    nextThunderStrikeAt = 0
    nextThunderRumbleAt = 0
    nextExposureGlobalAt = 0
    lastWeatherByKey = {}
    lastExposureByCondition = {}
    outdoorRainSinceAt = nil
    lastEvaluatedCondition = "none"
end

if Events and Events.OnThunderEvent and not Beats._ThunderEventHooked then
    Events.OnThunderEvent.Add(function(x, y, doStrike, doLightning, doRumble)
        Beats.OnThunderEvent(x, y, doStrike, doLightning, doRumble)
    end)
    Beats._ThunderEventHooked = true
end

return Beats
