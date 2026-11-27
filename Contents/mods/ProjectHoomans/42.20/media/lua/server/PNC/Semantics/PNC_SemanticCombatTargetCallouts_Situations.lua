if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_SituationQuery"

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

local SIT_BARK_OPTS = I.SituationBarkOpts

function I.EmitSituationCallout(speaker, addr, desc, role, now, ref, extraTokens)
    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
    local dirTopic = role == "blindside" and "combat_blindside"
        or (role == "swarm_help" or role == "swarm_overwhelmed" or role == "swarm_bystander_help") and "combat_swarm_help"
        or (role == "reloading_cover" or role == "reloading_panic") and "combat_reloading"
        or role == "swarm_rescue_thanks" and "combat_swarm_rescue"
        or role == "stamina_exhausted" and "combat_exhausted"
        or "combat_situation"
    local dirScope = "sit:" .. tostring(speaker and speaker.id or "nil") .. ":" .. tostring(role or "generic")
    if Dir and type(Dir.GateEmitter) == "function" then
        local dirOk = Dir.GateEmitter(dirTopic, speaker, {
            scopeKey = dirScope,
            now = now,
            markOnAdmit = false,
        })
        if not dirOk then return false end
    end
    local tone = S.ResolveAllyWarnTone(speaker, nil)
    local toks = S.BuildRichSpeechTokens
        and S.BuildRichSpeechTokens(speaker, addr, desc, now, tone, { skipLocation = true }) or {}
    if type(extraTokens) == "table" then
        for k, v in pairs(extraTokens) do toks[k] = v end
    end
    local tCls = desc and desc.semanticClass or "human_hostile"
    local text, res = S.ResolveSemanticLine(
        speaker, "combat_ally_warn_callout", "WARN", tCls, ref, nil, toks, { replyRole = role }
    )
    if not text then return false end
    local sec = PNC.SecondaryChannel
    if sec and type(sec.RequestBark) == "function" then sec.RequestBark(speaker, "bark.alert_hey", now) end
    local sent = S.DeliverBark(speaker, now, {
        eventType = "combat_ally_warn_callout",
        speechEventID = res and res.realizationID or ("semantic.combat." .. tostring(role)),
        act = "WARN", family = SIT_BARK_OPTS.family, cooldownMs = SIT_BARK_OPTS.cooldownMs,
        familyCooldownMs = SIT_BARK_OPTS.familyCooldownMs, priority = SIT_BARK_OPTS.priority,
        priorityHoldMs = SIT_BARK_OPTS.priorityHoldMs, ttlMs = SIT_BARK_OPTS.ttlMs,
        interrupt = role == "blindside"
            or role == "swarm_help"
            or role == "swarm_overwhelmed"
            or role == "swarm_bystander_help"
            or role == "reloading_panic",
        clientCooldowns = SIT_BARK_OPTS.clientCooldowns, threadID = ref,
        streamKey = "ally-warn-sit:" .. tostring(speaker.id),
        eventRef = ref, text = text, presentationClass = res and res.presentationClass or "BARK",
        context = { eventType = "combat_ally_warn_callout", eventRef = ref, threadID = ref, transient = true },
    })
    local okSent = (tonumber(sent) or 0) > 0
    if okSent and Dir and type(Dir.MarkSpoken) == "function" then
        Dir.MarkSpoken(dirScope, dirTopic, role == "blindside" and 3 or 1, now, speaker and speaker.id)
    end
    return okSent
end

local function turnToward(ally, tx, ty, now)
    local ax, ay = tonumber(ally.x) or tx, tonumber(ally.y) or ty
    local dx, dy = tx - ax, ty - ay
    local len = math.sqrt((dx * dx) + (dy * dy))
    ally.runtime = type(ally.runtime) == "table" and ally.runtime or {}
    if len > 0.05 then ally.runtime.facingDirX, ally.runtime.facingDirY = dx / len, dy / len end
    local sec = PNC.SecondaryChannel
    if sec and sec.SetAlertLevel then sec.SetAlertLevel(ally, "tense") end
    if sec and sec.RequestGaze then sec.RequestGaze(ally, tx, ty, 3500, now) end
end

local SWARM_THRESHOLD = 3
local SWARM_OVERWHELMED_THRESHOLD = 5
local SWARM_HELP_COOLDOWN_MS = 10000
local BYSTANDER_HELP_COOLDOWN_MS = 15000
local BYSTANDER_IDLE_GRACE_MS = 3000
local SWARM_RESCUE_WINDOW_MS = 25000

local function applySwarmRescueRelationship(record, req, now)
    local relationships = PNC.Relationships
    if not relationships or type(relationships.ApplyConversationEffect) ~= "function" then
        return false
    end
    local gameTime = type(getGameTime) == "function" and getGameTime() or nil
    local worldAge = gameTime and type(gameTime.getWorldAgeHours) == "function"
        and gameTime:getWorldAgeHours() or 0
    local relKey = req.relKey or (req.isPlayer and "player" or ("npc:" .. tostring(req.helperId)))
    relationships.ApplyConversationEffect(tostring(record.id), relKey, {
        interactionType = "swarm_rescue",
        memoryType = "swarm_rescue",
        approval = 4,
        familiarity = 2,
        decayPerDay = 0.12,
        tags = { combat = true, rescue = true, aid = true },
    }, {
        eventID = "swarm-rescue:" .. tostring(req.ref or now),
        worldAgeHours = worldAge,
    })
    return true
end

function S.TryEmitSwarmHelpCall(record, desc, now, ref)
    if type(record) ~= "table" or record.alive == false then return false end
    now = I.SituationNow(now)
    record.runtime = record.runtime or {}
    local lastAt = tonumber(record.runtime.lastSwarmHelpAt) or 0
    if now >= lastAt and (now - lastAt) < SWARM_HELP_COOLDOWN_MS then
        return false
    end
    local threatCount = I.CountThreatsOnActor
        and I.CountThreatsOnActor(record, false, now) or 0
    if threatCount < SWARM_THRESHOLD then
        return false
    end
    local helper = I.FindLeastThreatenedHelper
        and I.FindLeastThreatenedHelper(record, 16, now) or nil
    if not helper then
        return false
    end
    local grappled = (tonumber(record.runtime.grappleHoldUntil) or 0) > now
    local lowHealth = record.health and tonumber(record.health.current)
        and tonumber(record.health.max)
        and (record.health.current / math.max(1, record.health.max)) < 0.45
    local role = (threatCount >= SWARM_OVERWHELMED_THRESHOLD or grappled or lowHealth)
        and "swarm_overwhelmed" or "swarm_help"
    local callDesc = type(desc) == "table" and desc or {
        semanticClass = "zombie",
        enemyCount = threatCount,
        x = record.x,
        y = record.y,
        z = record.z,
    }
    ref = tostring(ref or ("swarm:" .. tostring(record.id) .. ":" .. tostring(now)))
    local addrObj = helper.isPlayer
        and { id = "player", name = helper.name, isPlayer = true }
        or helper.record
    local spoke = I.EmitSituationCallout(record, addrObj, callDesc, role, now, ref, {
        ["swarm.count"] = tostring(threatCount),
    })
    if not spoke then return false end
    record.runtime.lastSwarmHelpAt = now
    record.runtime.swarmHelpRequest = {
        relKey = helper.relKey,
        helperId = helper.id,
        helperName = helper.name,
        isPlayer = helper.isPlayer == true,
        helperRecord = helper.record,
        at = now,
        initialCount = threatCount,
        ref = ref,
    }
    if not helper.isPlayer and helper.record and S.EnqueueCustomReply then
        S.EnqueueCustomReply({
            speaker = helper.record,
            addressee = record,
            desc = callDesc,
            role = "swarm_help_reply",
            eventType = "combat_ally_warn_reply_defensive",
            now = now,
            delayMs = 550,
            eventRef = ref .. ":s_reply",
            threadID = ref,
            barkOpts = SIT_BARK_OPTS,
        })
    end
    return true
end

function S.TryEmitBystanderHelpCall(record, desc, now, ref)
    if type(record) ~= "table" or record.alive == false then return false end
    now = I.SituationNow(now)
    record.runtime = record.runtime or {}
    local lastAt = tonumber(record.runtime.lastBystanderHelpAt) or 0
    if now >= lastAt and (now - lastAt) < BYSTANDER_HELP_COOLDOWN_MS then
        return false
    end
    if not I.FindIdleBystanderHelper then return false end
    local bystander, activeFighters = I.FindIdleBystanderHelper(record, 16, now)
    if not bystander or (tonumber(activeFighters) or 0) < 2 then
        record.runtime.bystanderIdleKey = nil
        record.runtime.bystanderIdleSince = nil
        return false
    end
    local key = tostring(bystander.relKey or bystander.id or "")
    if record.runtime.bystanderIdleKey ~= key then
        record.runtime.bystanderIdleKey = key
        record.runtime.bystanderIdleSince = now
        return false
    end
    if (now - (tonumber(record.runtime.bystanderIdleSince) or now)) < BYSTANDER_IDLE_GRACE_MS then
        return false
    end
    local threatCount = I.CountThreatsOnActor and I.CountThreatsOnActor(record, false, now) or 1
    local callDesc = type(desc) == "table" and desc or {
        semanticClass = "zombie",
        enemyCount = math.max(1, threatCount),
        x = record.x,
        y = record.y,
        z = record.z,
    }
    ref = tostring(ref or ("bystander:" .. tostring(record.id) .. ":" .. tostring(now)))
    local addrObj = bystander.isPlayer
        and { id = "player", name = bystander.name, isPlayer = true }
        or bystander.record
    local spoke = I.EmitSituationCallout(record, addrObj, callDesc, "swarm_bystander_help", now, ref, {
        ["swarm.fighters"] = tostring(activeFighters),
    })
    if not spoke then return false end
    record.runtime.lastBystanderHelpAt = now
    record.runtime.bystanderIdleKey = nil
    record.runtime.bystanderIdleSince = nil
    if not record.runtime.swarmHelpRequest then
        record.runtime.swarmHelpRequest = {
            relKey = bystander.relKey,
            helperId = bystander.id,
            helperName = bystander.name,
            isPlayer = bystander.isPlayer == true,
            helperRecord = bystander.record,
            at = now,
            initialCount = math.max(2, threatCount),
            ref = ref,
        }
    end
    if not bystander.isPlayer and bystander.record and S.EnqueueCustomReply then
        S.EnqueueCustomReply({
            speaker = bystander.record,
            addressee = record,
            desc = callDesc,
            role = "swarm_bystander_help_reply",
            eventType = "combat_ally_warn_reply_defensive",
            now = now,
            delayMs = 550,
            eventRef = ref .. ":by_reply",
            threadID = ref,
            barkOpts = SIT_BARK_OPTS,
        })
    end
    return true
end

function S.CheckSwarmHelpResolution(record, now)
    local req = type(record) == "table" and record.runtime
        and record.runtime.swarmHelpRequest or nil
    if type(req) ~= "table" then return false end
    now = I.SituationNow(now)
    if (now - (tonumber(req.at) or 0)) > SWARM_RESCUE_WINDOW_MS then
        record.runtime.swarmHelpRequest = nil
        return false
    end
    if (now - (tonumber(req.at) or 0)) < 1500 then
        return false
    end
    local currentCount = I.CountThreatsOnActor
        and I.CountThreatsOnActor(record, false, now) or 0
    if currentCount > math.max(1, (tonumber(req.initialCount) or SWARM_THRESHOLD) - 2) then
        return false
    end
    record.runtime.swarmHelpRequest = nil
    applySwarmRescueRelationship(record, req, now)
    local addrObj = req.isPlayer
        and { id = "player", name = req.helperName, isPlayer = true }
        or req.helperRecord
    if addrObj then
        I.EmitSituationCallout(
            record,
            addrObj,
            { semanticClass = "zombie", enemyCount = currentCount, x = record.x, y = record.y, z = record.z },
            "swarm_rescue_thanks",
            now,
            tostring(req.ref or "swarm") .. ":thanks"
        )
    end
    return true
end

local RELOAD_CALLOUT_COOLDOWN_MS = 6500

function S.TryEmitReloadCallout(record, target, now, ref)
    if type(record) ~= "table" or record.alive == false then return false end
    now = I.SituationNow(now)
    record.runtime = record.runtime or {}
    local lastAt = tonumber(record.runtime.lastReloadCalloutAt) or 0
    if now >= lastAt and (now - lastAt) < RELOAD_CALLOUT_COOLDOWN_MS then
        return false
    end
    local threatCount = I.CountThreatsOnActor
        and I.CountThreatsOnActor(record, false, now) or 0
    local distSq = type(target) == "table" and tonumber(target.distSq) or nil
    if distSq == nil and type(target) == "table" and target.x ~= nil and target.y ~= nil then
        distSq = I.DistSq(record.x, record.y, target.x, target.y)
    end
    local closeThreat = distSq ~= nil and distSq <= 16 -- <= 4 tiles
    local lowHealth = record.health and tonumber(record.health.current)
        and tonumber(record.health.max)
        and (record.health.current / math.max(1, record.health.max)) < 0.45
    local highStakes = threatCount >= 2 or closeThreat or lowHealth
    local role = highStakes and "reloading_panic" or "reloading_cover"

    local helper = I.FindLeastThreatenedHelper
        and I.FindLeastThreatenedHelper(record, 16, now) or nil
    local addrObj = helper and (
        helper.isPlayer
            and { id = "player", name = helper.name, isPlayer = true }
            or helper.record
    ) or nil
    local tCls = (type(target) == "table" and tostring(target.kind or "") ~= "zombie"
        and tostring(target.threatClass or "") ~= "zombie") and "human_hostile" or "zombie"
    local callDesc = {
        semanticClass = tCls,
        enemyCount = math.max(1, threatCount),
        x = (type(target) == "table" and target.x) or record.x,
        y = (type(target) == "table" and target.y) or record.y,
        z = (type(target) == "table" and target.z) or record.z,
    }
    ref = tostring(ref or ("reload:" .. tostring(record.id) .. ":" .. tostring(now)))
    local spoke = I.EmitSituationCallout(record, addrObj, callDesc, role, now, ref)
    if not spoke then return false end
    record.runtime.lastReloadCalloutAt = now
    if helper and not helper.isPlayer and helper.record and S.EnqueueCustomReply then
        S.EnqueueCustomReply({
            speaker = helper.record,
            addressee = record,
            desc = callDesc,
            role = "reloading_cover_reply",
            eventType = "combat_ally_warn_reply_defensive",
            now = now,
            delayMs = 550,
            eventRef = ref .. ":rl_reply",
            threadID = ref,
            barkOpts = SIT_BARK_OPTS,
        })
    end
    return true
end

function S.TryEmitBlindsideWarning(caller, ally, desc, now, ref)
    if type(caller) ~= "table" or type(ally) ~= "table" or type(desc) ~= "table" then return false end
    now = I.SituationNow(now)
    -- If the speaker is currently reloading, suppress generic ally warnings.
    local act = caller.runtime and caller.runtime.attackAction or nil
    if act and tostring(act.attackType or "") == "reload"
        and now < (tonumber(act.finishAt) or 0)
    then
        return false
    end
    -- If the speaker themselves is being swarmed (>= 3 zombies), call for help
    -- to the least-threatened ally/player instead of warning someone else!
    if I.CountThreatsOnActor and I.CountThreatsOnActor(caller, false, now) >= SWARM_THRESHOLD then
        return S.TryEmitSwarmHelpCall(caller, desc, now, ref)
    end
    local perc = PNC.Perception
    local teamKey = perc and perc.GetTeamKey and perc.GetTeamKey(caller) or nil
    local sk = perc and perc.GetActiveSkirmish and perc.GetActiveSkirmish(teamKey, now) or nil
    if sk and (now - (tonumber(sk.lastBeatAt) or 0)) < 6000 then return false end
    if perc and perc.MarkSkirmishBeat then perc.MarkSkirmishBeat(teamKey, "blindside", now) end
    turnToward(ally, tonumber(desc.x) or 0, tonumber(desc.y) or 0, now)
    ref = tostring(ref or ("blindside:" .. tostring(caller.id)))
    local spoke = I.EmitSituationCallout(caller, ally, desc, "blindside", now, ref)
    if spoke and S.EnqueueCustomReply then
        S.EnqueueCustomReply({
            speaker = ally, addressee = caller, desc = desc, role = "blindside_reply",
            now = now, delayMs = 600, eventRef = ref .. ":b_reply", threadID = ref, barkOpts = SIT_BARK_OPTS,
        })
    end
    return spoke
end

function S.TryEmitLastStragglerBeat(caller, ally, desc, now, ref)
    if type(caller) ~= "table" or type(desc) ~= "table" then return false end
    now = I.SituationNow(now)
    local perc = PNC.Perception
    local teamKey = perc and perc.GetTeamKey and perc.GetTeamKey(caller) or nil
    local sk = perc and perc.GetActiveSkirmish and perc.GetActiveSkirmish(teamKey, now) or nil
    if not sk or sk.lastOneSpoken or (tonumber(sk.initialCount) or 1) < 3 or (tonumber(desc.enemyCount) or 1) ~= 1 then
        return false
    end
    local addr = ally or I.FindSquadmates(caller, 16)[1]
    if not addr then return false end
    if perc and perc.MarkSkirmishBeat then perc.MarkSkirmishBeat(teamKey, "last_one", now) end
    ref = tostring(ref or ("lastone:" .. tostring(caller.id)))
    local spoke = I.EmitSituationCallout(caller, addr, desc, "last_one", now, ref)
    if spoke and S.EnqueueCustomReply then
        S.EnqueueCustomReply({
            speaker = addr, addressee = caller, desc = desc, role = "last_one_reply",
            now = now, delayMs = 650, eventRef = ref .. ":l_reply", threadID = ref, barkOpts = SIT_BARK_OPTS,
        })
    end
    return spoke
end

function S.HandleSkirmishActive(record, warningResult, now, ref)
    if S.CheckSwarmHelpResolution then
        S.CheckSwarmHelpResolution(record, now)
    end
    if I.CountThreatsOnActor and I.CountThreatsOnActor(record, false, now) >= SWARM_THRESHOLD then
        local okSwarm = S.TryEmitSwarmHelpCall(record, warningResult and warningResult.descriptor or nil, now, ref)
        if okSwarm then return true, "swarm_help" end
    elseif S.TryEmitBystanderHelpCall then
        local okBy = S.TryEmitBystanderHelpCall(record, warningResult and warningResult.descriptor or nil, now, ref)
        if okBy then return true, "swarm_bystander_help" end
    end
    if warningResult.blindsideAlly then
        local ok = S.TryEmitBlindsideWarning(record, warningResult.blindsideAlly, warningResult.descriptor, now, ref)
        return ok, ok and "blindside_warning" or "skirmish_already_active"
    end
    if warningResult.lastOneReady then
        local ok = S.TryEmitLastStragglerBeat(record, warningResult.notifiedAlly, warningResult.descriptor, now, ref)
        return ok, ok and "last_straggler" or "skirmish_already_active"
    end
    if type(S.OnFightingWhileInjured) == "function" then
        local okInj, reasonInj = S.OnFightingWhileInjured(record, warningResult.descriptor, now, { threadID = ref })
        if okInj then return true, reasonInj end
    end
    return false, "skirmish_already_active"
end

return S
