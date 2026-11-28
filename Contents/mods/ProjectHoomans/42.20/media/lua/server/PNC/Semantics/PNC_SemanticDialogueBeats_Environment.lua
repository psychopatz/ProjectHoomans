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

local function calmRejectionReason(rec, teamKey, now)
    if type(rec) ~= "table" or rec.id == nil then return "invalid_record" end
    if rec.alive == false then return "not_alive" end
    local live = tostring(PNC.Const and PNC.Const.PRESENCE_LIVE or "live")
    if rec.presenceState ~= nil and tostring(rec.presenceState) ~= live then
        return "presence:" .. tostring(rec.presenceState)
    end
    if type(rec.runtime) == "table" then
        if rec.runtime.target ~= nil then return "has_target" end
        if rec.runtime.attackAction ~= nil then return "has_attack_action" end
    end
    local perc = PNC.Perception
    if teamKey and perc and type(perc.GetActiveSkirmish) == "function"
        and perc.GetActiveSkirmish(teamKey, now) ~= nil
    then
        return "active_skirmish"
    end
    return nil
end

local function isCalmSquadmate(rec, teamKey, now)
    return calmRejectionReason(rec, teamKey, now) == nil
end

local function findCalmSpeakerNearPoint(x, y, radius, now)
    local perc, sp = PNC.Perception, PNC.SpatialIndex
    local audit = type(Beats.IsAuditEnabled) == "function" and Beats.IsAuditEnabled() == true
    if not sp or type(sp.QueryNPCs) ~= "function" then
        if audit then
            Beats.AuditLog("speaker_search", {
                "x=" .. tostring(x),
                "y=" .. tostring(y),
                "radius=" .. tostring(radius or 12),
                "reason=spatial_index_unavailable",
            })
        end
        return nil, nil
    end
    local list = sp.QueryNPCs(x, y, radius or 12) or {}
    local hasAllyCheck = perc and type(perc.AreWarningAllies) == "function"
    local firstCalm = nil
    local rejected = audit and {} or nil
    local calmCount = 0
    for i = 1, #list do
        local a = list[i]
        local tk = perc and perc.GetTeamKey and perc.GetTeamKey(a) or nil
        local rejA = calmRejectionReason(a, tk, now)
        if rejA == nil then
            calmCount = calmCount + 1
            if not firstCalm then firstCalm = a end
            for j = i + 1, #list do
                local b = list[j]
                if isCalmSquadmate(b, tk, now)
                    and (not hasAllyCheck or perc.AreWarningAllies(a, b) == true)
                then
                    if audit then
                        Beats.AuditLog("speaker_search", {
                            "x=" .. tostring(math.floor(tonumber(x) or 0)),
                            "y=" .. tostring(math.floor(tonumber(y) or 0)),
                            "radius=" .. tostring(radius or 12),
                            "queried=" .. tostring(#list),
                            "anchor=" .. tostring(a.id or ""),
                            "partner=" .. tostring(b.id or ""),
                            "rejected=" .. (#rejected > 0 and table.concat(rejected, ",") or "none"),
                        })
                    end
                    return a, b
                end
            end
        elseif rejected and #rejected < 8 then
            rejected[#rejected + 1] = tostring(a and a.id or "?") .. ":" .. rejA
        end
    end
    if audit then
        Beats.AuditLog("speaker_search", {
            "x=" .. tostring(math.floor(tonumber(x) or 0)),
            "y=" .. tostring(math.floor(tonumber(y) or 0)),
            "radius=" .. tostring(radius or 12),
            "queried=" .. tostring(#list),
            "calm=" .. tostring(calmCount),
            "anchor=" .. tostring(firstCalm and firstCalm.id or "nil"),
            "partner=nil",
            "rejected=" .. (#rejected > 0 and table.concat(rejected, ",") or "none"),
        })
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

local function findCalmGroupsNearPoint(x, y, radius, now, maxGroups)
    local perc, sp = PNC.Perception, PNC.SpatialIndex
    local audit = type(Beats.IsAuditEnabled) == "function" and Beats.IsAuditEnabled() == true
    if not sp or type(sp.QueryNPCs) ~= "function" then
        if audit then
            Beats.AuditLog("speaker_search", {
                "mode=groups",
                "x=" .. tostring(x),
                "y=" .. tostring(y),
                "radius=" .. tostring(radius or 16),
                "reason=spatial_index_unavailable",
            })
        end
        return {}
    end
    local list = sp.QueryNPCs(x, y, radius or 16) or {}
    local limit = math.max(1, tonumber(maxGroups) or 3)
    local byKey = {}
    local order = {}
    local rejected = audit and {} or nil
    for i = 1, #list do
        local rec = list[i]
        local tk = perc and perc.GetTeamKey and perc.GetTeamKey(rec) or nil
        local rej = calmRejectionReason(rec, tk, now)
        if rej == nil then
            local gKey = tostring(tk or rec.factionID or ("solo:" .. tostring(rec.id)))
            local group = byKey[gKey]
            if not group then
                if #order < limit then
                    group = { teamKey = gKey, members = {} }
                    byKey[gKey] = group
                    order[#order + 1] = group
                end
            end
            if group and #group.members < 4 then
                group.members[#group.members + 1] = rec
            end
        elseif rejected and #rejected < 8 then
            rejected[#rejected + 1] = tostring(rec and rec.id or "?") .. ":" .. rej
        end
    end
    if audit then
        Beats.AuditLog("speaker_search", {
            "mode=groups",
            "x=" .. tostring(math.floor(tonumber(x) or 0)),
            "y=" .. tostring(math.floor(tonumber(y) or 0)),
            "radius=" .. tostring(radius or 16),
            "queried=" .. tostring(#list),
            "groups=" .. tostring(#order),
            "rejected=" .. (#rejected > 0 and table.concat(rejected, ",") or "none"),
        })
    end
    return order
end

local function findCalmGroupsNearPlayer(now, maxGroups, radius)
    local core = PNC.Core
    if not core or type(core.ForEachPlayer) ~= "function" then return {} end
    local groups = {}
    core.ForEachPlayer(function(p)
        if #groups > 0 or not p then return end
        local x = p.getX and tonumber(p:getX())
        local y = p.getY and tonumber(p:getY())
        if x and y then
            groups = findCalmGroupsNearPoint(x, y, radius or 16, now, maxGroups or 3)
        end
    end)
    return groups
end

Beats.IsCalmSquadmate = isCalmSquadmate
Beats.FindCalmPairNearPlayer = findCalmPairNearPlayer
Beats.FindCalmSpeakerNearPoint = findCalmSpeakerNearPoint
Beats.FindCalmSpeakerNearPlayer = findCalmSpeakerNearPlayer
Beats.FindCalmGroupsNearPoint = findCalmGroupsNearPoint
Beats.FindCalmGroupsNearPlayer = findCalmGroupsNearPlayer
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
    local holdMs = tonumber(spec.holdMs) or 1800
    local audSvc = PNC.Semantics and PNC.Semantics.AudienceContext or nil
    local listeners = {}
    if type(b) == "table" then listeners[#listeners + 1] = b end
    if type(spec.third) == "table" then listeners[#listeners + 1] = spec.third end
    if type(spec.fourth) == "table" then listeners[#listeners + 1] = spec.fourth end
    local aud = audSvc and type(audSvc.Resolve) == "function"
        and audSvc.Resolve(a, listeners, { includeNearbyPlayer = true, playerRadius = 14 }) or nil
    local playerName = (aud and aud.playerName) or ((not b) and findNearestPlayerName(a.x, a.y) or nil)
    local openTokens = {}
    if aud and type(aud.tokens) == "table" then
        for k, v in pairs(aud.tokens) do openTokens[k] = v end
    end
    if type(spec.tokens) == "table" then
        for k, v in pairs(spec.tokens) do openTokens[k] = v end
    end
    if not openTokens["addressee.name"] and playerName then
        openTokens["addressee.name"] = playerName
    end
    local function buildTurnContext(extra)
        local c = {}
        if aud and type(aud.context) == "table" then
            for k, v in pairs(aud.context) do c[k] = v end
        end
        if type(spec.context) == "table" then
            for k, v in pairs(spec.context) do c[k] = v end
        end
        if type(extra) == "table" then
            for k, v in pairs(extra) do c[k] = v end
        end
        return c
    end
    local plan = {
        threadID = ref,
        family = spec.family,
        eventRef = ref,
        opening = {
            speaker = a,
            addressee = b,
            poolID = spec.poolID,
            eventType = spec.eventType,
            domain = spec.domain or "world",
            channel = spec.channel or spec.domain or "world",
            topic = spec.topic or "world_event",
            inCombat = false,
            act = spec.openAct or "REACT",
            role = spec.openRole,
            family = spec.family,
            priority = pri,
            priorityHoldMs = 500,
            holdMs = holdMs,
            delayMs = tonumber(spec.openingDelayMs) or 0,
            clientCooldowns = cds,
            eventRef = ref,
            tokens = openTokens,
            context = buildTurnContext(nil),
        },
        replies = {},
    }
    local function copySpecTokens()
        local t = {}
        if playerName then t["player.name"] = playerName end
        if type(spec.tokens) == "table" then
            for k, v in pairs(spec.tokens) do t[k] = v end
        end
        return t
    end
    local replyDelay = tonumber(spec.delayMs) or 1150
    if type(b) == "table" and spec.replyRole then
        plan.replies[#plan.replies + 1] = {
            speaker = b,
            addressee = a,
            poolID = spec.poolID,
            eventType = spec.eventType,
            domain = spec.domain or "world",
            channel = spec.channel or spec.domain or "world",
            topic = spec.topic or "world_event",
            inCombat = false,
            act = spec.replyAct or "REACT",
            role = spec.replyRole,
            family = spec.family,
            delayMs = replyDelay,
            priority = pri,
            priorityHoldMs = 500,
            holdMs = holdMs,
            clientCooldowns = cds,
            eventRef = ref .. ":r1",
            tokens = copySpecTokens(),
            context = buildTurnContext(nil),
        }
    end
    local c = spec.third
    if type(c) == "table" and c.alive ~= false and c.id ~= nil
        and c.id ~= a.id and (not b or c.id ~= b.id) and spec.chimeRole
    then
        local crt = type(c.runtime) == "table" and c.runtime or nil
        if not (crt and crt.target ~= nil) then
            plan.replies[#plan.replies + 1] = {
                speaker = c,
                addressee = b or a,
                poolID = spec.poolID,
                eventType = spec.eventType,
                domain = spec.domain or "world",
                channel = spec.channel or spec.domain or "world",
                topic = spec.topic or "world_event",
                inCombat = false,
                act = spec.chimeAct or spec.replyAct or "REACT",
                role = spec.chimeRole,
                family = spec.family,
                delayMs = tonumber(spec.chimeDelayMs) or (replyDelay + 1450),
                priority = pri,
                priorityHoldMs = 500,
                holdMs = holdMs,
                clientCooldowns = cds,
                eventRef = ref .. ":r2",
                tokens = copySpecTokens(),
                context = buildTurnContext(nil),
            }
        end
    end
    local d = spec.fourth
    if type(d) == "table" and d.alive ~= false and d.id ~= nil
        and spec.wrapRole
    then
        local drt = type(d.runtime) == "table" and d.runtime or nil
        if not (drt and drt.target ~= nil) then
            plan.replies[#plan.replies + 1] = {
                speaker = d,
                addressee = c or b or a,
                poolID = spec.poolID,
                eventType = spec.eventType,
                domain = spec.domain or "world",
                channel = spec.channel or spec.domain or "world",
                topic = spec.topic or "world_event",
                inCombat = false,
                act = spec.wrapAct or spec.replyAct or "REACT",
                role = spec.wrapRole,
                family = spec.family,
                delayMs = tonumber(spec.wrapDelayMs) or (replyDelay + 2900),
                priority = pri,
                priorityHoldMs = 500,
                holdMs = holdMs,
                clientCooldowns = cds,
                eventRef = ref .. ":r3",
                tokens = copySpecTokens(),
                context = buildTurnContext(nil),
            }
        end
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
    if type(Beats.CheckHouseAlarmEnded) == "function" then
        Beats.CheckHouseAlarmEnded(now)
    end
    if PNC.WorldKnowledge and type(PNC.WorldKnowledge.ObserveHelicopterEpisode) == "function" then
        local worldHours = PNC.Core and type(PNC.Core.NowWorldAgeHours) == "function"
            and PNC.Core.NowWorldAgeHours() or nil
        local heliRes = PNC.WorldKnowledge.ObserveHelicopterEpisode(worldHours)
        if type(heliRes) == "table" then
            if heliRes.action == "started" then
                Beats.EmitForNearbyGroups("environment.helicopter_start", {
                    x = heliRes.x, y = heliRes.y, factID = heliRes.factID,
                }, now, 28, 3)
            elseif heliRes.action == "ended" then
                Beats.EmitForNearbyGroups("environment.helicopter_ended", {
                    x = heliRes.x, y = heliRes.y, factID = heliRes.factID,
                }, now, 28, 3)
            end
        end
    end
    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    local frame = {
        now = now,
        env = BC and type(BC.GetWorldWeather) == "function" and BC.GetWorldWeather(now) or nil,
        util = BC and type(BC.GetWorldUtilities) == "function" and BC.GetWorldUtilities(now) or nil,
        groups = nil,
    }
    frame.getGroups = function(maxGroups, radius)
        if frame.groups == nil and type(Beats.FindCalmGroupsNearPlayer) == "function" then
            frame.groups = Beats.FindCalmGroupsNearPlayer(now, maxGroups or 3, radius or 18)
        end
        return frame.groups or {}
    end

    -- Spread the heavier ambient checks across env ticks with a small time
    -- budget so server_finish.dialogue_beats never spikes 70-900ms in one frame.
    local envStartMs = nowMs()
    local envBudgetMs = 5
    local wxEmitted = false
    local watcherEmitted = false
    local tasks = {
        function()
            if type(Beats.CheckNearbyWorldObjects) == "function" then
                Beats.CheckNearbyWorldObjects(now)
            end
        end,
        function()
            if Beats.LastWeather ~= nil and type(Beats.CheckGroupBanter) == "function" then
                Beats.CheckGroupBanter(now, frame)
            end
        end,
        function()
            if type(Beats.CheckCompanionNeeds) == "function" then
                Beats.CheckCompanionNeeds(now)
            end
        end,
        function()
            if type(Beats.CheckGroupItemShare) == "function" then
                Beats.CheckGroupItemShare(now)
            end
        end,
        function()
            if type(Beats.CheckWeatherAndExposure) == "function" then
                wxEmitted = Beats.CheckWeatherAndExposure(now, frame) == true
            end
        end,
        function()
            if type(Beats.CheckStateWatchers) == "function" then
                watcherEmitted = Beats.CheckStateWatchers(now, frame) == true
            end
        end,
    }
    local cursor = tonumber(Beats.EnvCheckCursor) or 1
    if cursor < 1 or cursor > #tasks then cursor = 1 end
    local ran = 0
    while ran < #tasks do
        tasks[cursor]()
        ran = ran + 1
        cursor = (cursor % #tasks) + 1
        if ran < #tasks and (nowMs() - envStartMs) >= envBudgetMs then
            break
        end
    end
    Beats.EnvCheckCursor = cursor
    if type(Beats.MaybeLogPeriodicAuditSnapshot) == "function" then
        Beats.MaybeLogPeriodicAuditSnapshot("env_check", now)
    end
    if wxEmitted or watcherEmitted then
        return true
    end
    if type(Beats.CheckWeatherAndExposure) == "function" then
        return false
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
        return Beats.EmitForNearbyGroups("environment.weather_changed", {
            weather = cur, previous = prev, env = env, usePlayerProximity = true,
        }, now, 16, 2)
    end
    return false
end

Beats.RegisterHook("environment.weather_rain", {
    eventTypes = { "environment.weather_changed" },
    priority = 30,
    cooldownMs = 0,
    evaluate = function(_, payload, ctx)
        local w = tostring(payload.weather or (ctx.env and ctx.env.weather) or "")
        if w ~= "rain" and w ~= "storm" and w ~= "thunderstorm" and w ~= "tropical_storm" then return nil end
        local isStorm = w == "storm" or w == "thunderstorm" or w == "tropical_storm"
        local prefix = isStorm and "weather_storm" or "weather_rain"
        local a, b = payload.anchor or payload.speaker, payload.partner or payload.addressee
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "weather:" .. w .. ":" .. tostring(payload.groupIndex or 1),
            family = isStorm and "environment_weather_storm" or "environment_weather_rain",
            poolID = "semantic.world.weather.rain",
            eventType = "world_weather_beat",
            domain = "weather",
            channel = "weather",
            topic = "weather",
            openAct = "REACT",
            replyAct = "REACT",
            openRole = prefix .. "_open",
            replyRole = prefix .. "_reply",
            chimeRole = prefix .. "_chime",
            third = payload.third,
            openingDelayMs = payload.openingDelayMs,
            priority = isStorm and 33 or 30,
            delayMs = 900,
            chimeDelayMs = 2100,
        })
    end,
})

local function faceLiveNPC(record, x, y)
    if type(record) ~= "table" or not x or not y then return end
    local body = record.zombie or (PNC.Registry and PNC.Registry.GetZombie
        and PNC.Registry.GetZombie(record.id)) or nil
    if body and type(body.faceLocation) == "function" then
        body:faceLocation(x, y)
    end
end

function Beats.EmitForNearbyGroups(eventName, basePayload, now, radius, maxGroups)
    now = nowMs(now)
    basePayload = type(basePayload) == "table" and basePayload or {}
    local groups
    if basePayload.x ~= nil and basePayload.y ~= nil and basePayload.usePlayerProximity ~= true then
        groups = findCalmGroupsNearPoint(basePayload.x, basePayload.y, radius or 28, now, maxGroups or 3)
    else
        groups = findCalmGroupsNearPlayer(now, maxGroups or 3, radius or 18)
    end
    if #groups == 0 then return false, "no_calm_speaker", 0 end
    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
    local emitted = 0
    local firstTid = nil
    for gi = 1, #groups do
        local rawMembers = groups[gi].members
        local members = rawMembers
        if Dir and type(Dir.ResolveVoiceProfile) == "function" and #rawMembers > 1 then
            members = {}
            for mi = 1, #rawMembers do members[mi] = rawMembers[mi] end
            table.sort(members, function(m1, m2)
                local c1 = Dir.ResolveVoiceProfile(m1, now).chattiness or 1.0
                local c2 = Dir.ResolveVoiceProfile(m2, now).chattiness or 1.0
                if c1 ~= c2 then return c1 > c2 end
                return tostring(m1.id or "") < tostring(m2.id or "")
            end)
        end
        local a, b, c = members[1], members[2], members[3]
        if a then
            if basePayload.x and basePayload.y then
                faceLiveNPC(a, basePayload.x, basePayload.y)
                if b then faceLiveNPC(b, basePayload.x, basePayload.y) end
                if c then faceLiveNPC(c, basePayload.x, basePayload.y) end
            end
            local payload = {}
            for k, v in pairs(basePayload) do payload[k] = v end
            payload.anchor = a
            payload.speaker = a
            payload.partner = b
            payload.third = c
            payload.openingDelayMs = (gi - 1) * 1800
            payload.groupIndex = gi
            local ok, tid = Beats.Emit(eventName, payload, now)
            if ok then
                emitted = emitted + 1
                if not firstTid then firstTid = tid end
                if Dir and type(Dir.RecordStoryMoment) == "function" then
                    if eventName == "environment.house_alarm_ended" then
                        Dir.RecordStoryMoment(groups[gi].teamKey, {
                            kind = "house_alarm_ended",
                            topic = "post_alarm",
                            actorId = a.id,
                            salience = 76,
                            valence = -1,
                            ttlMs = 300000,
                        }, now)
                    elseif eventName == "environment.helicopter_ended" then
                        Dir.RecordStoryMoment(groups[gi].teamKey, {
                            kind = "chopper_ended",
                            topic = "post_chopper",
                            actorId = a.id,
                            salience = 84,
                            valence = -1,
                            ttlMs = 360000,
                        }, now)
                    end
                end
            end
        end
    end
    return emitted > 0, firstTid or "no_beat_selected", emitted
end

Beats.RegisterHook("environment.helicopter_start", {
    eventTypes = { "environment.helicopter_start" },
    priority = 46,
    cooldownMs = 0,
    evaluate = function(_, payload)
        local a = payload.anchor or payload.speaker
        if type(a) ~= "table" or a.alive == false then return nil end
        return Beats.BuildWorldThread(a, payload.partner, {
            refPrefix = "world:chopper_start:" .. tostring(payload.groupIndex or 1),
            family = "world_chopper_start",
            poolID = "semantic.world.chopper.react",
            eventType = "world_event_beat",
            domain = "world",
            channel = "world",
            topic = "helicopter_event",
            openAct = "WARN",
            replyAct = "REACT",
            openRole = "chopper_start_open",
            replyRole = "chopper_start_reply",
            chimeRole = "chopper_start_chime",
            third = payload.third,
            openingDelayMs = payload.openingDelayMs,
            priority = 46,
            delayMs = 950,
            chimeDelayMs = 2100,
        })
    end,
})

Beats.RegisterHook("environment.helicopter_ended", {
    eventTypes = { "environment.helicopter_ended" },
    priority = 44,
    cooldownMs = 0,
    evaluate = function(_, payload)
        local a = payload.anchor or payload.speaker
        if type(a) ~= "table" or a.alive == false then return nil end
        return Beats.BuildWorldThread(a, payload.partner, {
            refPrefix = "world:chopper_ended:" .. tostring(payload.groupIndex or 1),
            family = "world_chopper_ended",
            poolID = "semantic.world.chopper.react",
            eventType = "world_event_beat",
            domain = "world",
            channel = "world",
            topic = "helicopter_ended",
            openAct = "REACT",
            replyAct = "REACT",
            openRole = "chopper_ended_open",
            replyRole = "chopper_ended_reply",
            chimeRole = "chopper_ended_chime",
            third = payload.third,
            openingDelayMs = payload.openingDelayMs,
            priority = 44,
            delayMs = 1050,
            chimeDelayMs = 2250,
        })
    end,
})

Beats.RegisterHook("ambient.chopper_shelter.enter", {
    eventTypes = { "ambient.chopper_shelter.enter" },
    priority = 45,
    cooldownMs = 45000,
    evaluate = function(_, payload, ctx)
        local a = payload.speaker or payload.anchor
        if type(a) ~= "table" or a.alive == false then return nil end
        local _, b = findCalmSpeakerNearPoint(a.x, a.y, 10, ctx.now)
        if b == a then b = nil end
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "chopper_shelter_enter",
            family = "ambient_chopper_shelter_enter",
            poolID = "semantic.ambient.chopper_shelter.enter",
            eventType = "ambient_chopper_shelter_enter",
            domain = "world",
            topic = "chopper_shelter",
            openRole = "open",
            replyRole = "reply",
            priority = 45,
        })
    end,
})

Beats.RegisterHook("ambient.chopper_shelter.clear", {
    eventTypes = { "ambient.chopper_shelter.clear" },
    priority = 43,
    cooldownMs = 45000,
    evaluate = function(_, payload, ctx)
        local a = payload.speaker or payload.anchor
        if type(a) ~= "table" or a.alive == false then return nil end
        local _, b = findCalmSpeakerNearPoint(a.x, a.y, 10, ctx.now)
        if b == a then b = nil end
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "chopper_shelter_clear",
            family = "ambient_chopper_shelter_clear",
            poolID = "semantic.ambient.chopper_shelter.clear",
            eventType = "ambient_chopper_shelter_clear",
            domain = "world",
            topic = "chopper_shelter",
            openRole = "open",
            replyRole = "reply",
            priority = 43,
        })
    end,
})

Beats.RegisterHook("ambient.rain_shelter.enter", {
    eventTypes = { "ambient.rain_shelter.enter" },
    priority = 32,
    cooldownMs = 90000,
    evaluate = function(_, payload, ctx)
        local a = payload.speaker or payload.anchor
        if type(a) ~= "table" or a.alive == false then return nil end
        local _, b = findCalmSpeakerNearPoint(a.x, a.y, 10, ctx.now)
        if b == a then b = nil end
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "rain_shelter_enter",
            family = "ambient_rain_shelter_enter",
            poolID = "semantic.ambient.rain_shelter.enter",
            eventType = "ambient_rain_shelter_enter",
            domain = "weather",
            topic = "rain_shelter",
            openRole = "open",
            replyRole = "reply",
            priority = 32,
        })
    end,
})

Beats.RegisterHook("ambient.rain_shelter.clear", {
    eventTypes = { "ambient.rain_shelter.clear" },
    priority = 32,
    cooldownMs = 90000,
    evaluate = function(_, payload, ctx)
        local a = payload.speaker or payload.anchor
        if type(a) ~= "table" or a.alive == false then return nil end
        local _, b = findCalmSpeakerNearPoint(a.x, a.y, 10, ctx.now)
        if b == a then b = nil end
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "rain_shelter_clear",
            family = "ambient_rain_shelter_clear",
            poolID = "semantic.ambient.rain_shelter.clear",
            eventType = "ambient_rain_shelter_clear",
            domain = "weather",
            topic = "rain_shelter",
            openRole = "open",
            replyRole = "reply",
            priority = 32,
        })
    end,
})

Beats.RegisterHook("ambient.world_event.react", {
    eventTypes = { "ambient.world_event.react" },
    priority = 42,
    cooldownMs = 45000,
    evaluate = function(_, payload)
        local a = payload.speaker or payload.anchor
        local b = payload.partner
        if type(a) ~= "table" or a.alive == false then return nil end
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "world_event_react",
            family = "ambient_world_event_react",
            poolID = "semantic.ambient.world_event.react",
            eventType = "ambient_world_event_react",
            domain = "world",
            topic = tostring(payload.topic or "world_event"),
            openRole = "open",
            replyRole = "reply",
            priority = 42,
        })
    end,
})

Beats.RegisterHook("ambient.player_sight", {
    eventTypes = { "ambient.player_sight" },
    priority = 36,
    cooldownMs = 60000,
    evaluate = function(_, payload)
        local a = payload.speaker or payload.anchor
        if type(a) ~= "table" or a.alive == false then return nil end
        return Beats.BuildWorldThread(a, nil, {
            refPrefix = "player_sight",
            family = "ambient_player_sight",
            poolID = "semantic.ambient.player_sight",
            eventType = "ambient_player_sight",
            domain = "social",
            topic = tostring(payload.topic or "unarmed"),
            priority = 36,
            tokens = payload.playerName and { ["addressee.name"] = payload.playerName } or nil,
        })
    end,
})

local META_AMBIENT_TOPICS = {
    MetaAssaultRifle1 = "meta_gunshot",
    MetaPistol1 = "meta_gunshot",
    MetaPistol2 = "meta_gunshot",
    MetaPistol3 = "meta_gunshot",
    MetaShotgun1 = "meta_gunshot",
    MetaScream = "meta_scream",
    chopper = "helicopter_event",
}

local function isAnyPlayerWithin(x, y, maxDist)
    local core = PNC.Core
    if not core or type(core.ForEachPlayer) ~= "function" then return false end
    local rSq = (tonumber(maxDist) or 700) ^ 2
    local near = false
    core.ForEachPlayer(function(p)
        if near or not p then return end
        local px = p.getX and tonumber(p:getX())
        local py = p.getY and tonumber(p:getY())
        if px and py then
            local dx, dy = px - x, py - y
            if (dx * dx + dy * dy) <= rSq then near = true end
        end
    end)
    return near
end

-- Event-driven world-event reaction (zero polling): nearby calm NPCs turn
-- toward gunshots/screams/chopper/road stories, acquire the WorldKnowledge fact
-- so they remember it in dialogue, and emit one group-deduped ConvoDSL beat.
function Beats.OnWorldEventNearNPCs(eventSpec, now)
    local audit = type(Beats.IsAuditEnabled) == "function" and Beats.IsAuditEnabled() == true
    if type(eventSpec) ~= "table" then return false end
    now = nowMs(now)
    local x = tonumber(eventSpec.x)
    local y = tonumber(eventSpec.y)
    if not x or not y then return false end
    local a, b
    if eventSpec.usePlayerProximity == true then
        if not isAnyPlayerWithin(x, y, tonumber(eventSpec.hearingRadius) or 700) then
            if audit then
                Beats.AuditLog("world_event_near_npcs", {
                    "topic=" .. tostring(eventSpec.topic or "world_event"),
                    "x=" .. tostring(math.floor(x)),
                    "y=" .. tostring(math.floor(y)),
                    "ok=false",
                    "reason=out_of_hearing_radius",
                })
            end
            return false
        end
        a, b = findCalmSpeakerNearPlayer(now)
    else
        a, b = findCalmSpeakerNearPoint(x, y, tonumber(eventSpec.radius) or 28, now)
    end
    if not a then
        if audit then
            Beats.AuditLog("world_event_near_npcs", {
                "topic=" .. tostring(eventSpec.topic or "world_event"),
                "x=" .. tostring(math.floor(x)),
                "y=" .. tostring(math.floor(y)),
                "ok=false",
                "reason=no_calm_speaker",
            })
        end
        return false
    end
    faceLiveNPC(a, x, y)
    if b then faceLiveNPC(b, x, y) end
    local wkg = PsychopatzCore and PsychopatzCore.WorldKnowledge or nil
    if wkg and type(wkg.Acquire) == "function" and eventSpec.factID then
        wkg.Acquire(a.actorID or a.id, eventSpec.factID, { provenance = "environmental" })
        if b then
            wkg.Acquire(b.actorID or b.id, eventSpec.factID, { provenance = "environmental" })
        end
    end
    local ok, res = Beats.Emit("ambient.world_event.react", {
        speaker = a,
        partner = b,
        topic = eventSpec.topic or "world_event",
        x = x,
        y = y,
    }, now)
    if audit then
        Beats.AuditLog("world_event_near_npcs", {
            "topic=" .. tostring(eventSpec.topic or "world_event"),
            "x=" .. tostring(math.floor(x)),
            "y=" .. tostring(math.floor(y)),
            "anchor=" .. tostring(a.id or ""),
            "partner=" .. tostring(b and b.id or "nil"),
            "ok=" .. tostring(ok == true),
            "result=" .. tostring(res or "nil"),
        })
    end
    return ok, res
end

local function onMetaAmbientSound(name, x, y)
    local topic = META_AMBIENT_TOPICS[tostring(name or "")]
    if not topic then return end
    Beats.OnWorldEventNearNPCs({
        topic = topic,
        x = x,
        y = y,
        hearingRadius = 700,
        usePlayerProximity = true,
    }, nil)
end

if Events and Events.OnAmbientSound and not Beats._MetaAmbientSoundHooked then
    Events.OnAmbientSound.Add(onMetaAmbientSound)
    Beats._MetaAmbientSoundHooked = true
end

return Beats
