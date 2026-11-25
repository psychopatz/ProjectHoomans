-- Restart-safe Behavior Script Orchestrator for controllable colonists.
-- Manages active multi-step scripts on record.runtime.behaviorScript (ephemeral,
-- pure primitives, zero Java objects), emits spoken plan verification on start,
-- supports instant stop/cancel ("okay that's enough", "stop", "follow me"),
-- yields to combat/threats, and auto-reconciles cleanly across save/restarts.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Compiler = PNC.ConvoEngine.BehaviorScriptCompiler
    or require "PNC/ConvoEngine/BehaviorScriptCompiler"
local GrammarJoin = PNC.ConvoEngine.GrammarJoin
    or require "PNC/ConvoEngine/GrammarJoin"

local Runner = PNC.ConvoEngine.BehaviorScriptRunner or {}
PNC.ConvoEngine.BehaviorScriptRunner = Runner

Runner.VERSION = 1
Runner.DEFAULT_TTL_MS = 90000

-- Unique per-boot session epoch so any stale state surviving a restart or
-- deserialization is detected and cleared on the very first reconcile tick.
local function randToken()
    if type(ZombRand) == "function" then
        return tostring(ZombRand(100000, 999999))
    end
    if math and type(math.random) == "function" then
        return tostring(math.random(100000, 999999))
    end
    return "0"
end

local RUNNER_EPOCH = "boot:" .. tostring(PNC.Core and type(PNC.Core.Now) == "function" and math.floor(PNC.Core.Now()) or 1)
    .. ":" .. randToken()
Runner.SESSION_EPOCH = RUNNER_EPOCH
local planSeq = 0

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now()) or 0
end

local function playerDisplayName(player)
    if not player then return "boss" end
    local desc = player.getDescriptor and player:getDescriptor() or nil
    local fore = desc and desc.getForename and tostring(desc:getForename() or "") or ""
    if fore ~= "" then return fore end
    local disp = player.getDisplayName and tostring(player:getDisplayName() or "") or ""
    if disp ~= "" then return disp end
    local uname = player.getUsername and tostring(player:getUsername() or "") or ""
    return uname ~= "" and uname or "boss"
end

local function speakScriptLine(record, player, role, summary, now)
    local Transport = PNC.Semantics and PNC.Semantics.SpeechTransport or nil
    if not Transport or type(Transport.ResolveLine) ~= "function" or type(Transport.Deliver) ~= "function" then
        return false, nil
    end
    local addrName = playerDisplayName(player)
    local cleanSummary = summary and GrammarJoin.CleanSurface(summary) or "handle that"
    local ref = "bscript:" .. tostring(record.id) .. ":" .. tostring(role) .. ":" .. tostring(math.floor(now))
    local tokens = {
        ["addressee.name"] = addrName,
        ["slot.plan.summary"] = cleanSummary,
    }
    local ctx = {
        beatRole = role,
        commandRole = role,
        topic = "command_ack",
        inCombat = false,
    }
    local text, res = Transport.ResolveLine(record, {
        eventType = "behavior_script",
        eventID = ref,
        act = role == "ack_script_cancelled" and "ACK" or "ACCEPT",
        topic = "command_ack",
        poolID = "semantic.command.ack",
        role = role,
        tokens = tokens,
        context = ctx,
        inCombat = false,
    })
    if not text then return false, nil end
    text = GrammarJoin.CleanSurface(text)
    local sent = Transport.Deliver(record, now, {
        eventType = "behavior_script",
        speechEventID = res and res.realizationID or ("semantic.command.ack." .. role),
        act = "ACK",
        domain = "social",
        topic = "command_ack",
        channel = "social",
        family = "behavior_script_" .. role,
        priority = 60,
        priorityHoldMs = 1200,
        cooldownMs = 1000,
        familyCooldownMs = 1000,
        ttlMs = 8000,
        clientCooldowns = { familyMs = 800, speakerMs = 1000, ambientMs = 300, mergeWindowMs = 0 },
        poolID = res and res.poolID or "semantic.command.ack",
        lightweightBark = true,
        observerOnly = true,
        eventRef = ref,
        threadID = ref,
        streamKey = "bscript:" .. tostring(record.id),
        text = text,
        presentationClass = res and res.presentationClass or "BARK",
        context = ctx,
    })
    return (tonumber(sent) or 0) > 0, text
end

function Runner.IsActive(record, at)
    local rt = type(record) == "table" and record.runtime or nil
    local bs = type(rt) == "table" and rt.behaviorScript or nil
    if type(bs) ~= "table" or bs.active ~= true then return false end
    if bs.sessionEpoch ~= RUNNER_EPOCH then return false end
    local now = nowMs(at)
    if now > (tonumber(bs.expiresAt) or 0) then return false end
    return true
end

-- Cleanly cancels an active behavior script (from stop words, "follow me",
-- combat interruption, timeout, or restart reconciliation).
function Runner.Cancel(record, body, reason, player, at)
    if type(record) ~= "table" then return false end
    local now = nowMs(at)
    local rt = type(record.runtime) == "table" and record.runtime or nil
    local bs = rt and rt.behaviorScript or nil
    local hadActive = type(bs) == "table" and bs.active == true
    local prevOrderKind = bs and bs.prevOrderKind or nil

    if rt then
        rt.behaviorScript = nil
        if reason == "follow_override" or prevOrderKind == "follow" then
            if reason == "follow_override" then
                rt.followOrderActive = true
            end
        end
    end
    if record.activeBehavior == "BehaviorScript" then
        record.activeBehavior = nil
    end
    if body and PNC.BehaviorCommon and type(PNC.BehaviorCommon.HaltMovement) == "function" then
        PNC.BehaviorCommon.HaltMovement(record, body, "behavior_script_" .. tostring(reason or "cancelled"))
    end
    if hadActive and (reason == "player_cancelled" or reason == "follow_override") then
        local role = reason == "follow_override" and "ack_follow" or "ack_script_cancelled"
        speakScriptLine(record, player, role, nil, now)
    end
    return hadActive
end

-- Starts a compiled behavior script (or cancels if plan.isCancel / FOLLOW override).
-- Emits spoken plan verification so the player knows exactly what the NPC will do.
function Runner.Start(record, body, plan, player, at)
    local allowed, authReason = Compiler.CanExecuteScript(record, player)
    if not allowed then return false, authReason end
    if type(plan) ~= "table" then return false, "invalid_plan" end
    local now = nowMs(at)

    -- Stop-word phrase ("okay that's enough", "stop", "never mind")
    if plan.isCancel == true then
        local cancelled = Runner.Cancel(record, body, "player_cancelled", player, now)
        return true, cancelled and "script_cancelled" or "no_active_script"
    end

    -- Pure "follow me" overrides and cancels any running script cleanly
    if plan.stepCount == 1 and plan.steps[1] and plan.steps[1].kind == "FOLLOW" then
        if Runner.IsActive(record, now) then
            Runner.Cancel(record, body, "follow_override", player, now)
        end
        record.runtime = record.runtime or {}
        record.runtime.followOrderActive = true
        return true, "follow_resumed"
    end

    if type(plan.steps) ~= "table" or #plan.steps == 0 then
        return false, "empty_plan"
    end

    record.runtime = record.runtime or {}
    local prevOrderKind = (record.orderSpec and record.orderSpec.kind)
        or (record.runtime.followOrderActive == true and "follow" or nil)

    planSeq = planSeq + 1
    local summary = plan.summary or Compiler.DescribePlan(plan)
    record.runtime.behaviorScript = {
        active = true,
        planId = "bscript:" .. tostring(record.id) .. ":" .. tostring(planSeq),
        sessionEpoch = RUNNER_EPOCH,
        steps = plan.steps,
        currentIndex = 1,
        summary = summary,
        startedAt = now,
        expiresAt = now + Runner.DEFAULT_TTL_MS,
        prevOrderKind = prevOrderKind,
    }
    -- Temporarily pause follow while executing the script so it doesn't tug back
    record.runtime.followOrderActive = false
    record.activeBehavior = "BehaviorScript"

    local _, spokenText = speakScriptLine(record, player, "ack_script_plan", summary, now)
    return true, "script_started", {
        planId = record.runtime.behaviorScript.planId,
        summary = summary,
        spokenText = spokenText,
    }
end

-- Called from TickOwnership: auto-clears stale/restarted/expired/combat-interrupted
-- scripts so an NPC is NEVER stuck after a save/reload or combat encounter.
function Runner.Reconcile(record, body, at)
    local rt = type(record) == "table" and record.runtime or nil
    local bs = type(rt) == "table" and rt.behaviorScript or nil
    if type(bs) ~= "table" then return false end
    local now = nowMs(at)
    if record.alive == false
        or bs.active ~= true
        or bs.sessionEpoch ~= RUNNER_EPOCH
        or now > (tonumber(bs.expiresAt) or 0)
        or rt.target ~= nil
        or rt.attackAction ~= nil
        or rt.combatTarget ~= nil
        or now < (tonumber(rt.inCombatUntil) or 0)
    then
        local why = bs.sessionEpoch ~= RUNNER_EPOCH and "restart_reconcile" or "interrupted"
        Runner.Cancel(record, body, why, nil, now)
        return false, why
    end
    return true
end

function Runner.Complete(record, body, player, at)
    local now = nowMs(at)
    local rt = type(record) == "table" and record.runtime or nil
    local bs = rt and rt.behaviorScript or nil
    if not bs then return false end
    local prevFollow = bs.prevOrderKind == "follow"
    rt.behaviorScript = nil
    if record.activeBehavior == "BehaviorScript" then
        record.activeBehavior = nil
    end
    if prevFollow then
        rt.followOrderActive = true
    end
    speakScriptLine(record, player, "ack_script_done", bs.summary, now)
    return true
end

return Runner
