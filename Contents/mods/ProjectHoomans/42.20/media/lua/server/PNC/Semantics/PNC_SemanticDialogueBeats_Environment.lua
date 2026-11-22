-- Environment watcher and built-in weather dialogue beat hooks.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local ENV_CHECK_INTERVAL_MS = 10000

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now()) or 0
end

local function isCalmSquadmate(rec, teamKey, now)
    if type(rec) ~= "table" or rec.alive == false or rec.id == nil then return false end
    local live = tostring(PNC.Const and PNC.Const.PRESENCE_LIVE or "live")
    if rec.presenceState ~= nil and tostring(rec.presenceState) ~= live then return false end
    if type(rec.runtime) == "table" and (rec.runtime.target ~= nil or rec.runtime.attackAction ~= nil) then
        return false
    end
    local perc = PNC.Perception
    if teamKey and perc and type(perc.GetActiveSkirmish) == "function"
        and perc.GetActiveSkirmish(teamKey, now) ~= nil
    then
        return false
    end
    return true
end

local function findCalmSpeakerNearPoint(x, y, radius, now)
    local perc, sp = PNC.Perception, PNC.SpatialIndex
    if not sp or type(sp.QueryNPCs) ~= "function" then return nil, nil end
    local list = sp.QueryNPCs(x, y, radius or 12) or {}
    local hasAllyCheck = perc and type(perc.AreWarningAllies) == "function"
    local firstCalm = nil
    for i = 1, #list do
        local a = list[i]
        local tk = perc and perc.GetTeamKey and perc.GetTeamKey(a) or nil
        if isCalmSquadmate(a, tk, now) then
            if not firstCalm then firstCalm = a end
            for j = i + 1, #list do
                local b = list[j]
                if isCalmSquadmate(b, tk, now)
                    and (not hasAllyCheck or perc.AreWarningAllies(a, b) == true)
                then
                    return a, b
                end
            end
        end
    end
    return firstCalm, nil
end

local function findCalmPairNearPlayer(now)
    local core = PNC.Core
    if not core or type(core.ForEachPlayer) ~= "function" then return nil, nil end
    local anchor, partner = nil, nil
    core.ForEachPlayer(function(p)
        if anchor then return end
        local x = p and p.getX and tonumber(p:getX())
        local y = p and p.getY and tonumber(p:getY())
        if x and y then
            local a, b = findCalmSpeakerNearPoint(x, y, 12, now)
            if a and b then anchor, partner = a, b end
        end
    end)
    return anchor, partner
end

local function findCalmSpeakerNearPlayer(now)
    local core = PNC.Core
    if not core or type(core.ForEachPlayer) ~= "function" then return nil, nil end
    local fallbackAnchor = nil
    local anchor, partner = nil, nil
    core.ForEachPlayer(function(p)
        if anchor then return end
        local x = p and p.getX and tonumber(p:getX())
        local y = p and p.getY and tonumber(p:getY())
        if x and y then
            local a, b = findCalmSpeakerNearPoint(x, y, 12, now)
            if a and b then
                anchor, partner = a, b
            elseif a and not fallbackAnchor then
                fallbackAnchor = a
            end
        end
    end)
    if anchor then return anchor, partner end
    return fallbackAnchor, nil
end

local function findNearestPlayerName(x, y)
    local core = PNC.Core
    if not core or type(core.ForEachPlayer) ~= "function" then return "friend" end
    local bestDistSq = math.huge
    local bestName = nil
    local px0, py0 = tonumber(x), tonumber(y)
    core.ForEachPlayer(function(p)
        if not p then return end
        local px = p.getX and tonumber(p:getX())
        local py = p.getY and tonumber(p:getY())
        local distSq = 0
        if px0 and py0 and px and py then
            local dx, dy = px - px0, py - py0
            distSq = dx * dx + dy * dy
        end
        if distSq <= bestDistSq then
            local desc = p.getDescriptor and p:getDescriptor() or nil
            local name = (desc and desc.getForename and desc:getForename())
                or (p.getDisplayName and p:getDisplayName())
                or (p.getUsername and p:getUsername())
                or nil
            if name and tostring(name) ~= "" then
                bestDistSq = distSq
                bestName = tostring(name)
            end
        end
    end)
    return bestName or "friend"
end

Beats.IsCalmSquadmate = isCalmSquadmate
Beats.FindCalmPairNearPlayer = findCalmPairNearPlayer
Beats.FindCalmSpeakerNearPoint = findCalmSpeakerNearPoint
Beats.FindCalmSpeakerNearPlayer = findCalmSpeakerNearPlayer
Beats.FindNearestPlayerName = findNearestPlayerName

function Beats.BuildWorldThread(a, b, spec)
    if type(a) ~= "table" or a.alive == false or a.id == nil then return nil end
    local art = type(a.runtime) == "table" and a.runtime or nil
    if art and art.target ~= nil then return nil end
    if type(b) == "table" then
        local brt = type(b.runtime) == "table" and b.runtime or nil
        if b.alive == false or (brt and brt.target ~= nil) then b = nil end
    end
    spec = type(spec) == "table" and spec or {}
    local ref = tostring(spec.refPrefix or "world") .. ":" .. tostring(a.id)
    local cds = { familyMs = 3000, speakerMs = 3000, ambientMs = 800, mergeWindowMs = 0 }
    local pri = tonumber(spec.priority) or 35
    local playerName = (not b) and findNearestPlayerName(a.x, a.y) or nil
    local openTokens = {}
    if type(spec.tokens) == "table" then
        for k, v in pairs(spec.tokens) do openTokens[k] = v end
    end
    if playerName then openTokens["addressee.name"] = playerName end
    local plan = {
        threadID = ref,
        family = spec.family,
        eventRef = ref,
        opening = {
            speaker = a,
            addressee = b,
            poolID = spec.poolID,
            eventType = spec.eventType,
            topic = spec.topic or "world_event",
            inCombat = false,
            act = spec.openAct or "REACT",
            role = spec.openRole,
            family = spec.family,
            priority = pri,
            priorityHoldMs = 500,
            holdMs = 700,
            clientCooldowns = cds,
            eventRef = ref,
            tokens = openTokens,
        },
        replies = {},
    }
    if type(b) == "table" and spec.replyRole then
        local replyTokens = nil
        if type(spec.tokens) == "table" then
            replyTokens = {}
            for k, v in pairs(spec.tokens) do replyTokens[k] = v end
        end
        plan.replies[1] = {
            speaker = b,
            addressee = a,
            poolID = spec.poolID,
            eventType = spec.eventType,
            topic = spec.topic or "world_event",
            inCombat = false,
            act = spec.replyAct or "REACT",
            role = spec.replyRole,
            family = spec.family,
            delayMs = tonumber(spec.delayMs) or 950,
            priority = pri,
            priorityHoldMs = 500,
            holdMs = 700,
            clientCooldowns = cds,
            eventRef = ref .. ":r1",
            tokens = replyTokens,
        }
    end
    return plan
end

function Beats.CheckEnvironment(now)
    now = nowMs(now)
    if now < (tonumber(Beats.NextEnvCheckAt) or 0) then return false end
    Beats.NextEnvCheckAt = now + ENV_CHECK_INTERVAL_MS

    if type(Beats.CheckUtilities) == "function" then
        Beats.CheckUtilities(now)
    end
    if type(Beats.CheckNearbyWorldObjects) == "function" then
        Beats.CheckNearbyWorldObjects(now)
    end

    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    if not BC or type(BC.GetWorldWeather) ~= "function" then return false end
    local env = BC.GetWorldWeather(now)
    local cur = env and env.weather or "clear"
    local prev = Beats.LastWeather
    Beats.LastWeather = cur
    if prev == nil then return false end
    local wasRain = prev == "rain" or prev == "storm"
    local isRain = cur == "rain" or cur == "storm"
    if not wasRain and isRain then
        local a, b = findCalmPairNearPlayer(now)
        if a and b then
            return Beats.Emit("environment.weather_changed", {
                weather = cur, previous = prev, anchor = a, partner = b, env = env,
            }, now)
        end
    end
    return false
end

Beats.RegisterHook("environment.weather_rain", {
    eventTypes = { "environment.weather_changed" },
    priority = 30,
    cooldownMs = 120000,
    evaluate = function(_, payload, ctx)
        local w = tostring(payload.weather or (ctx.env and ctx.env.weather) or "")
        if w ~= "rain" and w ~= "storm" then return nil end
        local a, b = payload.anchor or payload.speaker, payload.partner or payload.addressee
        if type(a) ~= "table" or type(b) ~= "table" or a.alive == false or b.alive == false then
            return nil
        end
        local art = type(a.runtime) == "table" and a.runtime or nil
        local brt = type(b.runtime) == "table" and b.runtime or nil
        if (art and art.target ~= nil) or (brt and brt.target ~= nil) then return nil end
        local ref = "weather:rain:" .. tostring(a.id)
        local cds = { familyMs = 3000, speakerMs = 3000, ambientMs = 800, mergeWindowMs = 0 }
        return {
            threadID = ref,
            family = "environment_weather_rain",
            eventRef = ref,
            opening = {
                speaker = a, addressee = b, eventType = "combat_ally_warn_callout", act = "WARN",
                role = "weather_rain_open", family = "environment_weather_rain",
                priority = 30, priorityHoldMs = 500, holdMs = 700, clientCooldowns = cds, eventRef = ref,
            },
            replies = { {
                speaker = b, addressee = a, eventType = "combat_ally_warn_reply_engaging", act = "ACK",
                role = "weather_rain_reply", family = "environment_weather_rain", delayMs = 900,
                priority = 30, priorityHoldMs = 500, holdMs = 700, clientCooldowns = cds, eventRef = ref .. ":r1",
            } },
        }
    end,
})

return Beats
