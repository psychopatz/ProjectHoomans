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
pcall(require, "PNC/ConvoEngine/Dialogue/ResponseCatalog")

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

local function isAuditEnabled()
    local diag = PNC.PerformanceScalingDiagnostics
    return type(diag) == "table" and diag.BehaviorScriptAuditEnabled == true
end

local function auditLog(event, record, fields)
    if not isAuditEnabled() then return end
    local npcId = type(record) == "table" and tostring(record.id or "unknown") or "unknown"
    local line = "bscript_audit event=" .. tostring(event) .. " npc=" .. npcId
    if type(fields) == "string" and fields ~= "" then
        line = line .. " " .. fields
    end
    if PNC.Core and type(PNC.Core.LogInfo) == "function" then
        PNC.Core.LogInfo(line)
    elseif print then
        print("[PNC][INFO] " .. line)
    end
end

local function resetMovement(record, body, reason)
    local ps = PNC.PathService
    if ps and ps.Commands and type(ps.Commands.Reset) == "function" then
        pcall(ps.Commands.Reset, record, body, reason)
        return true
    end
    if PNC.BehaviorCommon and type(PNC.BehaviorCommon.HaltMovement) == "function" then
        pcall(PNC.BehaviorCommon.HaltMovement, record, body, reason)
        return true
    end
    return false
end

local function requestMoveTo(record, body, tx, ty, tz, reason)
    local common = PNC.BehaviorCommon
    if body and common and type(common.MoveRecord) == "function" then
        local ok, moved, state = pcall(
            common.MoveRecord,
            record,
            body,
            tx,
            ty,
            tz,
            "walk",
            1.25,
            reason or "behavior_script_move",
            {
                navigationPolicy = "local",
                finalX = tx,
                finalY = ty,
                finalZ = tz,
            }
        )
        if ok and moved ~= false then return true, state or "move_intent" end
        return false, state or "move_rejected"
    end
    return false, "move_record_unavailable"
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

local function shortItemLabel(name)
    if type(name) ~= "string" or name == "" then return "" end
    local s = string.gsub(name, ":", " ")
    s = (s:gsub("^%s+", ""):gsub("%s+$", ""))
    if #s > 24 then s = string.sub(s, 1, 21) .. "..." end
    return s
end

local function fallbackLineForRole(role, addrName, summary, extraTokens)
    local who = (addrName and addrName ~= "") and (", " .. addrName) or ""
    if role == "ack_script_done_loot" then
        local loot = extraTokens and extraTokens["slot.loot.summary"] or "some supplies"
        return "Done looting" .. who .. " - I found " .. tostring(loot) .. "!"
    elseif role == "ack_script_done_empty" then
        return "Done checking" .. who .. " - didn't find anything useful."
    elseif role == "ack_script_done" then
        return "All done" .. who .. "."
    elseif role == "ack_script_cancelled" then
        return "Alright" .. who .. ", stopping now."
    elseif role == "ack_follow" then
        return "Right behind you" .. who .. "."
    elseif role == "ack_script_plan" then
        return "Got it" .. who .. " - I'll " .. tostring(summary or "handle that") .. "."
    end
    return "Got it" .. who .. "."
end

local function speakScriptLine(record, player, role, summary, now, extraTokens, fallbackName, resolveOnly)
    local Transport = PNC.Semantics and PNC.Semantics.SpeechTransport or nil
    if not Transport or type(Transport.ResolveLine) ~= "function" then
        return false, nil
    end
    local addrName = player and playerDisplayName(player) or (fallbackName or "boss")
    local cleanSummary = summary and GrammarJoin.CleanSurface(summary) or "handle that"
    local ref = "bscript:" .. tostring(record.id) .. ":" .. tostring(role) .. ":" .. tostring(math.floor(now))
    local tokens = {
        ["addressee.name"] = addrName,
        ["slot.plan.summary"] = cleanSummary,
    }
    if type(extraTokens) == "table" then
        for k, v in pairs(extraTokens) do
            tokens[k] = v
        end
    end
    local ctx = {
        beatRole = role,
        commandRole = role,
        combatReactionRole = role,
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
    if not text or text == "" then
        text = fallbackLineForRole(role, addrName, cleanSummary, extraTokens)
    end
    text = GrammarJoin.CleanSurface(text)
    if resolveOnly == true or type(Transport.Deliver) ~= "function" then
        return true, text
    end
    local isDone = (role == "ack_script_done_loot" or role == "ack_script_done_empty" or role == "ack_script_done")
    local sent = Transport.Deliver(record, now, {
        eventType = "behavior_script",
        speechEventID = res and res.realizationID or ("semantic.command.ack." .. role),
        act = isDone and "INFORM" or "ACK",
        domain = "social",
        topic = "command_ack",
        channel = "social",
        family = "behavior_script_" .. role,
        priority = isDone and 68 or 60,
        priorityHoldMs = 1200,
        cooldownMs = 800,
        familyCooldownMs = isDone and 1200 or 1000,
        witnessRadius = 24,
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
    if isAuditEnabled() then
        auditLog("speak", record, "role=" .. tostring(role) .. " sent=" .. tostring(sent) .. " text=\"" .. tostring(text) .. "\"")
    end
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

local function copyPrimitiveOrderSpec(spec)
    if type(spec) ~= "table" then return nil end
    local copy = {}
    for k, v in pairs(spec) do
        local tv = type(v)
        if tv == "string" or tv == "number" or tv == "boolean" then
            copy[k] = v
        end
    end
    return copy
end

local function restoreOrderState(record, bs, reason)
    if type(record) ~= "table" then return end
    local rt = type(record.runtime) == "table" and record.runtime or nil
    local prevSpec = bs and bs.prevOrderSpec or nil
    if reason == "follow_override" then
        if prevSpec and prevSpec.kind == "follow" then
            record.orderSpec = copyPrimitiveOrderSpec(prevSpec)
        else
            record.orderSpec = { kind = "follow" }
        end
        if rt then rt.followOrderActive = true end
        return
    end
    if reason == "player_cancelled" then
        -- Explicit stop ("okay that's enough", "stop"): stay put instead of
        -- snapping straight back to follow until the player says "follow me".
        if prevSpec and prevSpec.kind ~= "follow" and prevSpec.kind ~= "behavior_script" then
            record.orderSpec = copyPrimitiveOrderSpec(prevSpec)
        else
            record.orderSpec = { kind = "guard", x = record.x, y = record.y, z = record.z or 0 }
        end
        if rt then rt.followOrderActive = false end
        return
    end
    -- Natural completion, restart reconcile, or combat interrupt:
    -- restore previous non-behavior_script order cleanly.
    if prevSpec and prevSpec.kind ~= "behavior_script" then
        record.orderSpec = copyPrimitiveOrderSpec(prevSpec)
        if rt and prevSpec.kind == "follow" then
            rt.followOrderActive = true
        end
    elseif type(record.orderSpec) == "table" and record.orderSpec.kind == "behavior_script" then
        record.orderSpec = nil
    end
end

local function releaseLootClaims(record)
    local providers = PNC.Semantics and PNC.Semantics.ActionPlanProviders or nil
    local pickup = providers and providers.Pickup or nil
    if pickup and type(pickup.ReleaseClaimsFor) == "function" and record and record.id ~= nil then
        pickup.ReleaseClaimsFor(record.id)
    end
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
    end
    releaseLootClaims(record)
    restoreOrderState(record, bs, reason)
    if record.activeBehavior == "BehaviorScript"
        or (type(record.activeBehavior) == "string" and string.sub(record.activeBehavior, 1, 14) == "BehaviorScript")
    then
        record.activeBehavior = nil
    end
    if record.activeJob == "BehaviorScript" then
        record.activeJob = nil
    end
    resetMovement(record, body, "behavior_script_" .. tostring(reason or "cancelled"))
    if hadActive and isAuditEnabled() then
        auditLog("cancel", record, "reason=" .. tostring(reason or "cancelled") .. " prevOrder=" .. tostring(prevOrderKind or "none"))
    end
    if hadActive and (reason == "player_cancelled" or reason == "follow_override") then
        local role = reason == "follow_override" and "ack_follow" or "ack_script_cancelled"
        speakScriptLine(record, player, role, nil, now)
    end
    return hadActive
end

-- Starts a compiled behavior script (or cancels if plan.isCancel / FOLLOW override).
-- Emits spoken plan verification so the player knows exactly what the NPC will do.
function Runner.Start(record, body, plan, player, at, options)
    options = type(options) == "table" and options or {}
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
    local existingOrder = type(record.orderSpec) == "table" and record.orderSpec or nil
    local existingBs = type(record.runtime.behaviorScript) == "table" and record.runtime.behaviorScript or nil
    local prevOrderSpec = (existingOrder and existingOrder.kind ~= "behavior_script")
        and copyPrimitiveOrderSpec(existingOrder)
        or (existingBs and existingBs.prevOrderSpec) or nil
    local prevOrderKind = (prevOrderSpec and prevOrderSpec.kind)
        or (record.runtime.followOrderActive == true and "follow" or nil)

    planSeq = planSeq + 1
    local summary = plan.summary or Compiler.DescribePlan(plan)
    local hadPickupStep = false
    for idx = 1, #plan.steps do
        if plan.steps[idx] and plan.steps[idx].kind == "PICKUP" then
            hadPickupStep = true
            break
        end
    end
    local planId = "bscript:" .. tostring(record.id) .. ":" .. tostring(planSeq)
    record.runtime.behaviorScript = {
        active = true,
        planId = planId,
        sessionEpoch = RUNNER_EPOCH,
        steps = plan.steps,
        currentIndex = 1,
        summary = summary,
        startedAt = now,
        expiresAt = now + Runner.DEFAULT_TTL_MS,
        prevOrderKind = prevOrderKind,
        prevOrderSpec = prevOrderSpec,
        playerName = playerDisplayName(player),
        hadPickupStep = hadPickupStep,
        collectedItems = {},
    }
    -- Switch into a dedicated `behavior_script` order state so FollowOwner
    -- never conflicts when the player walks around during execution.
    record.orderSpec = { kind = "behavior_script", planId = planId }
    record.runtime.followOrderActive = false
    record.activeJob = "BehaviorScript"
    record.activeBehavior = "BehaviorScript:" .. tostring(plan.steps[1] and plan.steps[1].kind or "start")
    record.nextThinkAt = now
    resetMovement(record, body, "behavior_script_started")

    -- Smart, non-invasive conversation hold yield: release the blocking
    -- `social.conversation` pose while keeping the chat lease active.
    if PNC.ConversationScene and type(PNC.ConversationScene.YieldForOrder) == "function" then
        PNC.ConversationScene.YieldForOrder(record, body, "behavior_script_started")
    end

    if isAuditEnabled() then
        local st1 = plan.steps[1] or {}
        local sc = type(st1.areaScope) == "table" and st1.areaScope or nil
        auditLog("start", record,
            "planId=" .. tostring(record.runtime.behaviorScript.planId)
            .. " steps=" .. tostring(#plan.steps)
            .. " first=" .. tostring(st1.kind or "nil")
            .. " filter=" .. tostring(st1.filter or "nil")
            .. " containers=" .. tostring(st1.includeContainers == true)
            .. " room=" .. tostring(sc and sc.room or "nil")
            .. " roomPos=" .. tostring(sc and sc.roomX or "nil") .. "," .. tostring(sc and sc.roomY or "nil")
            .. " prevOrder=" .. tostring(prevOrderKind or "none")
            .. " summary=\"" .. tostring(summary or "") .. "\"")
    end

    local _, spokenText = speakScriptLine(
        record, player, "ack_script_plan", summary, now, nil, nil, options.resolveOnly == true
    )
    if not spokenText and summary then
        spokenText = "Got it - I'll " .. tostring(summary) .. "."
    end
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
    if type(bs) ~= "table" then
        -- Restart safety: if a persisted `behavior_script` orderSpec survived
        -- reload without ephemeral runtime.behaviorScript, clear it cleanly.
        if type(record) == "table" and type(record.orderSpec) == "table"
            and record.orderSpec.kind == "behavior_script"
        then
            record.orderSpec = nil
            if record.activeJob == "BehaviorScript" then record.activeJob = nil end
            if type(record.activeBehavior) == "string"
                and string.sub(record.activeBehavior, 1, 14) == "BehaviorScript"
            then
                record.activeBehavior = nil
            end
        end
        return false
    end
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
    releaseLootClaims(record)
    restoreOrderState(record, bs, "completed")
    if record.activeBehavior == "BehaviorScript"
        or (type(record.activeBehavior) == "string" and string.sub(record.activeBehavior, 1, 14) == "BehaviorScript")
    then
        record.activeBehavior = nil
    end
    if record.activeJob == "BehaviorScript" then
        record.activeJob = nil
    end
    if isAuditEnabled() then
        auditLog("complete", record,
            "planId=" .. tostring(bs.planId)
            .. " prevFollow=" .. tostring(prevFollow)
            .. " collected=" .. tostring(type(bs.collectedItems) == "table" and #bs.collectedItems or 0))
    end
    if bs.hadPickupStep == true then
        local lootSummary = GrammarJoin.FormatLootSummary(bs.collectedItems)
        if lootSummary then
            speakScriptLine(record, player, "ack_script_done_loot", bs.summary, now, {
                ["slot.loot.summary"] = lootSummary,
            }, bs.playerName)
        else
            speakScriptLine(record, player, "ack_script_done_empty", bs.summary, now, nil, bs.playerName)
        end
    else
        speakScriptLine(record, player, "ack_script_done", bs.summary, now, nil, bs.playerName)
    end
    return true
end

local function resolveMoveCoords(record, body, step)
    local t = type(step) == "table" and step.target or nil
    if type(t) ~= "table" then return nil end
    if tonumber(t.x) and tonumber(t.y) then
        return tonumber(t.x), tonumber(t.y), tonumber(t.z) or (record and tonumber(record.z)) or 0
    end
    local resolver = PNC.Semantics and PNC.Semantics.WorldTargetResolver or nil
    if resolver and type(resolver.Resolve) == "function" and t.text then
        local resolved = resolver.Resolve({ kind = t.kind or "phrase", text = t.text }, {
            record = record,
            body = body,
        })
        if type(resolved) == "table" and tonumber(resolved.x) and tonumber(resolved.y) then
            t.x, t.y, t.z = tonumber(resolved.x), tonumber(resolved.y), tonumber(resolved.z) or 0
            return t.x, t.y, t.z
        end
    end
    return nil
end

local function emitLootGrabBeat(record, itemName, now)
    if not itemName or itemName == "" then return false end
    local Transport = PNC.Semantics and PNC.Semantics.SpeechTransport or nil
    if not Transport or type(Transport.ResolveLine) ~= "function" or type(Transport.Deliver) ~= "function" then
        return false
    end
    local cleanItem = GrammarJoin.CleanSurface(itemName)
    local ref = "bscript_loot:" .. tostring(record.id) .. ":" .. tostring(math.floor(now))
    local ctx = {
        beatRole = "loot_grab_item",
        commandRole = "loot_grab_item",
        topic = "command_ack",
        inCombat = false,
    }
    local text, res = Transport.ResolveLine(record, {
        eventType = "behavior_script_loot_grab",
        eventID = ref,
        act = "INFORM",
        topic = "command_ack",
        poolID = "semantic.command.ack",
        role = "loot_grab_item",
        tokens = { ["slot.item.name"] = cleanItem },
        context = ctx,
        inCombat = false,
    })
    if not text or text == "" then
        text = "Grabbing " .. tostring(cleanItem) .. "."
    end
    text = GrammarJoin.CleanSurface(text)
    local sent = Transport.Deliver(record, now, {
        eventType = "behavior_script_loot_grab",
        speechEventID = res and res.realizationID or "semantic.command.ack.loot_grab_item",
        act = "INFORM",
        domain = "social",
        topic = "command_ack",
        channel = "social",
        family = "behavior_script_loot_grab",
        priority = 42,
        priorityHoldMs = 900,
        cooldownMs = 4000,
        familyCooldownMs = 4500,
        witnessRadius = 20,
        ttlMs = 6000,
        clientCooldowns = { familyMs = 4500, speakerMs = 4000, ambientMs = 1200, mergeWindowMs = 2500 },
        poolID = res and res.poolID or "semantic.command.ack",
        lightweightBark = true,
        observerOnly = true,
        eventRef = ref,
        threadID = ref,
        streamKey = "bscript_loot:" .. tostring(record.id),
        text = text,
        presentationClass = res and res.presentationClass or "BARK",
        context = ctx,
    })
    return (tonumber(sent) or 0) > 0
end

local function getPickupProvider()
    local providers = PNC.Semantics and PNC.Semantics.ActionPlanProviders or nil
    if providers and providers.Pickup then return providers.Pickup end
    local ok, mod = pcall(require, "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanPickupProvider")
    return ok and mod or nil
end

local function getActionsProvider()
    local providers = PNC.Semantics and PNC.Semantics.ActionPlanProviders or nil
    if providers and providers.Actions then return providers.Actions end
    local ok, mod = pcall(require, "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanWorldInteractProvider")
    return ok and mod or nil
end

-- Bounded per-tick executor called from TickOwnership.
-- Runs Reconcile first, then advances the current primitive step cleanly.
function Runner.Tick(record, body, at)
    local ok, why = Runner.Reconcile(record, body, at)
    if not ok then return false, why end
    local now = nowMs(at)
    local rt = record.runtime
    local bs = rt.behaviorScript
    if now < (tonumber(bs.nextStepAt) or 0) then
        return true
    end
    local step = bs.steps and bs.steps[bs.currentIndex or 1] or nil
    if not step then
        Runner.Complete(record, body, nil, now)
        return false
    end

    local kind = tostring(step.kind or "")
    record.activeJob = "BehaviorScript"
    if kind == "WAIT" then
        record.activeBehavior = (step.autoSeat == true) and "BehaviorScript:WAIT_SEAT" or "BehaviorScript:WAIT"
        bs.nextStepAt = now + 500
        return true
    elseif kind == "FOLLOW" then
        Runner.Cancel(record, body, "follow_override", nil, now)
        return false
    elseif kind == "MOVE_TO" then
        record.activeBehavior = "BehaviorScript:MOVE_TO"
        local tx, ty, tz = resolveMoveCoords(record, body, step)
        if not tx then
            bs.currentIndex = (bs.currentIndex or 1) + 1
            bs.nextStepAt = now + 200
            return true
        end
        local bx = (body and body.getX and tonumber(body:getX())) or tonumber(record.x) or tx
        local by = (body and body.getY and tonumber(body:getY())) or tonumber(record.y) or ty
        local dx, dy = tx - bx, ty - by
        if (dx * dx + dy * dy) <= 2.56 or (bs.moveStartedAt and (now - bs.moveStartedAt) > 12000) then
            bs.moveStartedAt = nil
            bs.currentIndex = (bs.currentIndex or 1) + 1
            bs.nextStepAt = now + 250
            return true
        end
        bs.moveStartedAt = bs.moveStartedAt or now
        local moved, moveState = requestMoveTo(record, body, tx, ty, tz, "behavior_script_move")
        if isAuditEnabled() then
            auditLog("move_step", record,
                "tx=" .. tostring(tx) .. " ty=" .. tostring(ty) .. " moved=" .. tostring(moved) .. " state=" .. tostring(moveState))
        end
        bs.nextStepAt = now + 400
        return true
    elseif kind == "PICKUP" then
        local pickup = getPickupProvider()
        if not pickup then
            if isAuditEnabled() then auditLog("pickup_skip", record, "reason=pickup_provider_missing") end
            bs.currentIndex = (bs.currentIndex or 1) + 1
            bs.nextStepAt = now + 250
        else
            local cell = (bs.cell) or (type(getCell) == "function" and getCell() or nil)
            local maxTotal = (step.quantity == "one") and 1 or (pickup.MAX_ITEMS_PER_STEP or 12)
            local pickedSoFar = tonumber(bs.stepPickedCount) or 0
            local remaining = maxTotal - pickedSoFar
            if remaining <= 0 then
                bs.stepPickedCount = 0
                bs.lootMoveStartedAt = nil
                bs.currentIndex = (bs.currentIndex or 1) + 1
                bs.nextStepAt = now + 300
            else
                local spot = type(pickup.FindNextLootSpot) == "function"
                    and pickup.FindNextLootSpot(record, body, step, { cell = cell }) or nil
                if isAuditEnabled() then
                    auditLog("loot_spot", record,
                        "found=" .. tostring(spot ~= nil)
                        .. " pos=" .. tostring(spot and spot.x or "nil") .. "," .. tostring(spot and spot.y or "nil")
                        .. " distSq=" .. tostring(spot and math.floor((spot.distSq or 0) * 10) / 10 or "nil")
                        .. " src=" .. tostring(spot and spot.sourceKind or "nil")
                        .. " pickedSoFar=" .. tostring(pickedSoFar))
                end
                if not spot then
                    bs.stepPickedCount = 0
                    bs.lootMoveStartedAt = nil
                    bs.currentIndex = (bs.currentIndex or 1) + 1
                    bs.nextStepAt = now + 300
                elseif spot.distSq > 3.24
                    and body and PNC.BehaviorCommon and type(PNC.BehaviorCommon.MoveRecord) == "function"
                    and not (bs.lootMoveStartedAt and (now - bs.lootMoveStartedAt) > 7000)
                then
                    bs.lootMoveStartedAt = bs.lootMoveStartedAt or now
                    record.activeJob = "BehaviorScript"
                    local itemTag = shortItemLabel(spot.itemName)
                    record.activeBehavior = itemTag ~= ""
                        and ("BehaviorScript:PICKUP_MOVE:" .. itemTag)
                        or "BehaviorScript:PICKUP_MOVE"
                    local moved, moveState = requestMoveTo(
                        record, body, spot.x + 0.5, spot.y + 0.5, spot.z, "behavior_script_loot_approach"
                    )
                    if isAuditEnabled() then
                        auditLog("loot_move", record,
                            "tx=" .. tostring(spot.x + 0.5) .. " ty=" .. tostring(spot.y + 0.5)
                            .. " moved=" .. tostring(moved) .. " state=" .. tostring(moveState))
                    end
                    bs.nextStepAt = now + 400
                    return true
                else
                    bs.lootMoveStartedAt = nil
                    local itemTag = shortItemLabel(spot.itemName)
                    record.activeBehavior = itemTag ~= ""
                        and ("BehaviorScript:PICKUP_GRAB:" .. itemTag)
                        or "BehaviorScript:PICKUP_GRAB"
                    -- Play real scavenge animation (LootLow for ground/corpse, LootHigh for containers)
                    -- before transferring items so looting never looks magical/instant.
                    local scenes = PNC.AnimationScenes
                    if not bs.lootAnimPending
                        and body and scenes and type(scenes.Request) == "function"
                    then
                        resetMovement(record, body, "behavior_script_loot_anim")
                        if type(body.faceLocation) == "function" then
                            pcall(body.faceLocation, body, spot.x + 0.5, spot.y + 0.5)
                        end
                        local sceneId = (spot.sourceKind == "ground" or spot.sourceKind == "corpse")
                            and "scavenge.loot_low" or "scavenge.loot_high"
                        pcall(scenes.Request, record, body, sceneId, {
                            reason = "behavior_script_loot",
                            now = now,
                        })
                        if isAuditEnabled() then
                            auditLog("loot_anim", record, "scene=" .. tostring(sceneId) .. " src=" .. tostring(spot.sourceKind))
                        end
                        bs.lootAnimPending = true
                        bs.nextStepAt = now + 650
                        return true
                    end
                    bs.lootAnimPending = false
                    local okPick, reasonPick, countPick, pickedNames, pickedDetails = pickup.ExecutePickup(record, body, step, {
                        cell = cell,
                        originX = spot.x,
                        originY = spot.y,
                        originZ = spot.z,
                        radius = 1,
                        maxCount = math.min(3, remaining),
                    })
                    local n = tonumber(countPick) or 0
                    bs.stepPickedCount = pickedSoFar + n
                    if type(pickedDetails) == "table" and #pickedDetails > 0 then
                        bs.collectedItems = bs.collectedItems or {}
                        for dIdx = 1, #pickedDetails do
                            bs.collectedItems[#bs.collectedItems + 1] = pickedDetails[dIdx]
                        end
                    end
                    if isAuditEnabled() then
                        auditLog("loot_pickup", record,
                            "ok=" .. tostring(okPick)
                            .. " reason=" .. tostring(reasonPick)
                            .. " count=" .. tostring(n)
                            .. " first=" .. tostring(type(pickedNames) == "table" and pickedNames[1] or "nil")
                            .. " total=" .. tostring(bs.stepPickedCount))
                    end
                    if n > 0 and type(pickedNames) == "table" and pickedNames[1] then
                        emitLootGrabBeat(record, pickedNames[1], now)
                    end
                    if reasonPick == "pack_full" or bs.stepPickedCount >= maxTotal or n == 0 then
                        bs.stepPickedCount = 0
                        bs.currentIndex = (bs.currentIndex or 1) + 1
                        bs.nextStepAt = now + 400
                    else
                        -- Continue walking to the next loot spot on the next tick
                        bs.nextStepAt = now + 750
                        return true
                    end
                end
            end
        end
    elseif kind == "STORE" then
        record.activeBehavior = "BehaviorScript:STORE"
        local pickup = getPickupProvider()
        if pickup and type(pickup.ExecuteStore) == "function" then
            local cell = type(getCell) == "function" and getCell() or nil
            pcall(pickup.ExecuteStore, record, body, step, { cell = cell })
        end
        bs.currentIndex = (bs.currentIndex or 1) + 1
        bs.nextStepAt = now + 450
    else
        record.activeBehavior = "BehaviorScript:" .. kind
        local actions = getActionsProvider()
        if actions then
            local fnMap = {
                INTERACT = actions.ExecuteInteract,
                EQUIP = actions.ExecuteEquip,
                POSTURE = actions.ExecutePosture,
                ENGAGE = actions.ExecuteEngage,
                EMOTE = actions.ExecuteEmote,
                DROP = actions.ExecuteDrop,
                GIVE = actions.ExecuteGive,
            }
            local fn = fnMap[kind]
            if type(fn) == "function" then
                pcall(fn, record, body, step, {})
            end
        end
        bs.currentIndex = (bs.currentIndex or 1) + 1
        bs.nextStepAt = now + 450
    end

    if (bs.currentIndex or 1) > #(bs.steps or {}) then
        Runner.Complete(record, body, nil, now)
        return false
    end
    return true
end

return Runner
