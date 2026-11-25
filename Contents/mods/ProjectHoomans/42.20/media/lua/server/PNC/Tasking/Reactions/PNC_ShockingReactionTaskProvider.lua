-- Server-authoritative Tasking provider reacting to spatial ShockingEventBus events using ReactionPolicy & ClueMemory.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ShockingReactionTaskProvider = PNC.ShockingReactionTaskProvider or {}

local Provider = PNC.ShockingReactionTaskProvider
local Evaluator = PNC.ReactionPolicyEvaluator
    or require "PNC/Tasking/Reactions/PNC_ReactionPolicyEvaluator"

Provider.DOMAIN = "reaction"
Provider.DEFAULT_OFFER_TTL_MS = 10000
Provider.DEFAULT_CLAIM_TTL_MS = 15000
Provider.MAX_LISTENERS_PER_EVENT = 16
Provider.MAX_WARN_ALLIES = 8
Provider.OffersByNPC = Provider.OffersByNPC or {}
Provider.ActiveByLease = Provider.ActiveByLease or {}

local INTENT_CAPABILITIES = {
    StopAndAssess = "reaction.assess",
    BackAway = "reaction.retreat",
    Investigate = "reaction.investigate",
    WarnGroup = "reaction.warn",
    SmartFlee = "reaction.flee",
}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and PNC.Core.Now() or 0
end

local function queryNearbyNPCs(x, y, radius)
    if PNC.SpatialIndex and type(PNC.SpatialIndex.QueryNPCs) == "function" then
        local nearby = PNC.SpatialIndex.QueryNPCs(x, y, radius)
        return type(nearby) == "table" and nearby or {}
    end
    local out = {}
    if PNC.Registry and type(PNC.Registry.Data) == "table" then
        for _, rec in pairs(PNC.Registry.Data) do
            if type(rec) == "table" and rec.alive ~= false then
                out[#out + 1] = rec
            end
        end
    end
    return out
end

---Handles a spatial shocking event, updates ClueMemory, builds reaction offers, and emits SHOCKING_EVENT.
function Provider.HandleShockingEvent(event)
    if type(event) ~= "table" or event.x == nil or event.y == nil then return 0 end
    if event.eventType == "shock.ally_threat_warning" then return 0 end
    local at = tonumber(event.at or event.emittedAt) or nowMs()
    local radius = math.max(1, tonumber(event.radius) or 18)
    local ez = tonumber(event.z) or 0
    local radiusSq = radius * radius

    local nearby = queryNearbyNPCs(event.x, event.y, radius)
    local offered = 0
    for i = 1, math.min(Provider.MAX_LISTENERS_PER_EVENT, #nearby) do
        local rec = nearby[i]
        if type(rec) == "table" and rec.alive ~= false and rec.id
            and rec.x ~= nil and rec.y ~= nil
            and math.abs((tonumber(rec.z) or 0) - ez) <= 1.0
        then
            local dx = (tonumber(rec.x) or 0) - event.x
            local dy = (tonumber(rec.y) or 0) - event.y
            if dx * dx + dy * dy <= radiusSq then
                if PNC.PerceptionService and type(PNC.PerceptionService.RecordClue) == "function" then
                    PNC.PerceptionService.RecordClue(rec, {
                        key = "shock:" .. tostring(event.id or event.eventType),
                        kind = "shock",
                        x = event.x,
                        y = event.y,
                        z = ez,
                        sourceId = event.sourceId,
                        severity = event.severity,
                    }, at)
                end
                local eval = Evaluator.Evaluate(rec, event)
                if eval and eval.reaction then
                    local reaction = eval.reaction
                    local npcKey = tostring(rec.id)
                    local currentOffer = Provider.OffersByNPC[npcKey]
                    local newPri = tonumber(reaction.priority) or 50
                    if not currentOffer
                        or (tonumber(currentOffer.expiresAt) or 0) <= at
                        or newPri >= (tonumber(currentOffer.priority) or 0)
                    then
                        Provider.OffersByNPC[npcKey] = {
                            npcId = npcKey,
                            event = event,
                            reaction = reaction,
                            priority = newPri,
                            createdAt = at,
                            expiresAt = at + Provider.DEFAULT_OFFER_TTL_MS,
                        }
                        offered = offered + 1
                        if PNC.Tasking and PNC.Tasking.Events and type(PNC.Tasking.Events.Emit) == "function" then
                            PNC.Tasking.Events.Emit("SHOCKING_EVENT", {
                                npcId = npcKey,
                                source = "Tasking.ShockingReaction",
                                entityId = tostring(event.id or reaction.id),
                                cause = tostring(event.eventType),
                            })
                        end
                    end
                end
            end
        end
    end
    return offered
end

function Provider.GetCandidates(npcId, options)
    local npcKey = tostring(npcId or "")
    local offer = Provider.OffersByNPC[npcKey]
    if not offer then return {} end
    local current = nowMs(type(options) == "table" and options.at or nil)
    if (tonumber(offer.expiresAt) or 0) <= current then
        Provider.OffersByNPC[npcKey] = nil
        return {}
    end
    local rec = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcKey)
    if not rec or rec.alive == false then return {} end

    local reaction = offer.reaction
    local band = tostring(reaction.band or "HARD_EMERGENCY")
    if PNC.TaskPriority and PNC.TaskPriority.RANK and not PNC.TaskPriority.RANK[band] then
        band = "HARD_EMERGENCY"
    end
    local intentName = tostring(reaction.intent or "StopAndAssess")
    return {
        {
            taskId = "reaction:" .. tostring(reaction.id) .. ":" .. npcKey,
            npcId = npcKey,
            kind = intentName,
            operation = intentName,
            sourceDomain = Provider.DOMAIN,
            sourceRef = tostring(reaction.id),
            precedence = band,
            urgency = math.max(0.1, math.min(1.0, (tonumber(reaction.priority) or 50) / 100)),
            capability = INTENT_CAPABILITIES[intentName] or "reaction.assess",
            interruptPolicy = "NORMAL",
        },
    }
end

function Provider.Validate(intent)
    if type(intent) ~= "table" or not intent.npcId then return false end
    local npcKey = tostring(intent.npcId)
    local offer = Provider.OffersByNPC[npcKey]
    if offer and offer.reaction and tostring(offer.reaction.id) == tostring(intent.sourceRef) then
        return (tonumber(offer.expiresAt) or 0) > nowMs()
    end
    for _, active in pairs(Provider.ActiveByLease) do
        if active.npcId == npcKey and active.reactionId == tostring(intent.sourceRef) then
            return true
        end
    end
    return false
end

function Provider.Assign(intent)
    local npcKey = tostring(intent.npcId or "")
    local rec = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcKey)
    if not rec or rec.alive == false then return nil, "NPC_UNAVAILABLE" end
    local offer = Provider.OffersByNPC[npcKey]
    if not offer or not offer.reaction then return nil, "REACTION_OFFER_EXPIRED" end

    local at = nowMs()
    local claimKey = "reaction:" .. npcKey
    local claims = PNC.Tasking and PNC.Tasking.Claims or nil
    local claimKeys = nil
    if claims and type(claims.Acquire) == "function" then
        local ok, reason = claims.Acquire(claimKey, npcKey, {
            domain = Provider.DOMAIN,
            ttlMs = Provider.DEFAULT_CLAIM_TTL_MS,
            at = at,
            metadata = { reactionId = offer.reaction.id, intent = offer.reaction.intent },
        })
        if not ok then return nil, tostring(reason or "REACTION_CLAIM_CONFLICT") end
        claimKeys = { claimKey }
    end

    return {
        reaction = offer.reaction,
        event = offer.event,
        claimKey = claimKey,
        claimKeys = claimKeys,
        claimOwnerId = npcKey,
        executionMode = (PNC.Registry.GetLiveZombie and PNC.Registry.GetLiveZombie(npcKey))
            and "LIVE" or "ABSTRACT",
    }
end

function Provider.Start(lease, assignment)
    if type(lease) ~= "table" or type(assignment) ~= "table" then
        return false, "INVALID_REACTION_START"
    end
    local npcKey = tostring(lease.npcId)
    local rec = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcKey)
    if not rec then return false, "NPC_UNAVAILABLE" end

    local at = nowMs()
    local reaction = assignment.reaction
    local event = assignment.event or {}
    local durationMs = reaction.intent == "StopAndAssess" and 3500
        or reaction.intent == "WarnGroup" and 3000
        or 6000

    rec.runtime = type(rec.runtime) == "table" and rec.runtime or {}
    rec.runtime.alertUntil = at + durationMs
    rec.runtime.reactionState = {
        leaseId = lease.leaseId,
        reactionId = reaction.id,
        intent = reaction.intent,
        startedAt = at,
        expiresAt = at + durationMs,
        targetX = tonumber(event.x),
        targetY = tonumber(event.y),
        targetZ = tonumber(event.z) or 0,
        warned = false,
    }
    Provider.ActiveByLease[lease.leaseId] = {
        npcId = npcKey,
        reactionId = reaction.id,
        claimKey = assignment.claimKey,
        reaction = reaction,
        event = event,
    }

    local secondary = PNC.SecondaryChannel
    if secondary then
        if event.x ~= nil and event.y ~= nil and type(secondary.RequestGaze) == "function" then
            secondary.RequestGaze(rec, event.x, event.y, durationMs, at)
        end
        if reaction.barkKey and type(secondary.RequestBark) == "function" then
            secondary.RequestBark(rec, reaction.barkKey, at)
        end
        if reaction.secondaryAnimVar == "PNCAlertLevel" and type(secondary.SetAlertLevel) == "function" then
            secondary.SetAlertLevel(rec, "tense")
        end
    end

    if reaction.socialEventId and PNC.SocialEventHooks
        and type(PNC.SocialEventHooks.RecordWitnessedEvent) == "function"
    then
        PNC.SocialEventHooks.RecordWitnessedEvent(rec, reaction.socialEventId, event.sourceId, at)
    end
    return true
end

local function moveAwayFrom(rec, zombie, ox, oy, oz, distMeters, reason)
    local rx = tonumber(rec.x) or 0
    local ry = tonumber(rec.y) or 0
    local dx = rx - (tonumber(ox) or rx)
    local dy = ry - (tonumber(oy) or ry)
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 0.05 then dx, dy, len = 1, 0, 1 end
    local tx = rx + (dx / len) * distMeters
    local ty = ry + (dy / len) * distMeters
    if PNC.BehaviorCommon and type(PNC.BehaviorCommon.MoveRecord) == "function" then
        PNC.BehaviorCommon.MoveRecord(rec, zombie, tx, ty, oz or 0, "run", 0.75, reason)
    else
        rec.runtime.reactionMoveTarget = { x = tx, y = ty, z = oz or 0, reason = reason }
    end
end

local function moveTowardClue(rec, zombie, tx, ty, tz, reason)
    if PNC.BehaviorCommon and type(PNC.BehaviorCommon.MoveRecord) == "function" then
        PNC.BehaviorCommon.MoveRecord(rec, zombie, tx, ty, tz or 0, "walk", 1.0, reason)
    else
        rec.runtime.reactionMoveTarget = { x = tx, y = ty, z = tz or 0, reason = reason }
    end
end

function Provider.CanContinue(lease)
    local rec = lease and PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(lease.npcId)
    local st = rec and rec.runtime and rec.runtime.reactionState or nil
    return rec ~= nil and rec.alive ~= false and st ~= nil and st.leaseId == lease.leaseId
end

function Provider.Tick(lease)
    local rec = lease and PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(lease.npcId)
    local st = rec and rec.runtime and rec.runtime.reactionState or nil
    if not rec or rec.alive == false or not st then
        return PNC.Tasking.Commands.Complete(lease.leaseId, "REACTION_STATE_MISSING")
    end
    local at = nowMs()
    if at >= (tonumber(st.expiresAt) or 0) then
        return PNC.Tasking.Commands.Complete(lease.leaseId, "REACTION_COMPLETE")
    end

    local zombie = PNC.Registry.GetLiveZombie and PNC.Registry.GetLiveZombie(lease.npcId) or nil
    local intent = st.intent
    if intent == "StopAndAssess" then
        if PNC.BehaviorCommon and PNC.BehaviorCommon.HaltMovement then
            PNC.BehaviorCommon.HaltMovement(rec, zombie, "reaction_assess")
        end
        if PNC.SecondaryChannel and PNC.SecondaryChannel.ApplyGaze then
            PNC.SecondaryChannel.ApplyGaze(rec, zombie, at)
        end
    elseif intent == "BackAway" then
        moveAwayFrom(rec, zombie, st.targetX, st.targetY, st.targetZ, 5.0, "reaction_back_away")
    elseif intent == "SmartFlee" then
        moveAwayFrom(rec, zombie, st.targetX, st.targetY, st.targetZ, 18.0, "reaction_smart_flee")
    elseif intent == "Investigate" then
        local clue = PNC.PerceptionService and PNC.PerceptionService.GetMostRecentClue
            and PNC.PerceptionService.GetMostRecentClue(rec, nil, at) or nil
        if not clue then
            return PNC.Tasking.Commands.Complete(lease.leaseId, "CLUE_EXPIRED")
        end
        local dx = (tonumber(rec.x) or 0) - clue.x
        local dy = (tonumber(rec.y) or 0) - clue.y
        if dx * dx + dy * dy <= 2.25 then
            return PNC.Tasking.Commands.Complete(lease.leaseId, "CLUE_INVESTIGATED")
        end
        moveTowardClue(rec, zombie, clue.x, clue.y, clue.z, "reaction_investigate")
    elseif intent == "WarnGroup" then
        if not st.warned then
            st.warned = true
            local active = Provider.ActiveByLease[lease.leaseId]
            local sourceId = active and active.event and active.event.sourceId or nil
            local sourceKind = active and active.event and active.event.sourceKind or nil
            local target = nil
            if sourceKind == "player" or (sourceId ~= nil and PNC.Core
                and type(PNC.Core.ResolvePlayerByUsername) == "function"
                and PNC.Core.ResolvePlayerByUsername(sourceId))
            then
                target = { kind = "player", username = sourceId, x = st.targetX, y = st.targetY, z = st.targetZ }
            elseif sourceKind == "zombie" or (sourceId ~= nil and PNC.Perception
                and type(PNC.Perception.FindZombieByID) == "function"
                and PNC.Perception.FindZombieByID(sourceId))
            then
                target = { kind = "zombie", zombieId = sourceId, x = st.targetX, y = st.targetY, z = st.targetZ }
            elseif sourceId ~= nil and PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(sourceId) then
                target = { kind = "npc", id = sourceId, x = st.targetX, y = st.targetY, z = st.targetZ }
            elseif sourceKind == "foreign_npc" then
                target = {
                    kind = "foreign_npc",
                    provider = active and active.event and active.event.sourceProvider,
                    actorId = sourceId,
                    x = st.targetX, y = st.targetY, z = st.targetZ,
                }
            end
            if target and PNC.Perception
                and type(PNC.Perception.PublishAllyThreatWarning) == "function"
            then
                PNC.Perception.PublishAllyThreatWarning(rec, target, {
                    at = at,
                    radius = 14,
                    source = "shock_reaction_warn_group",
                })
            else
                local allies = queryNearbyNPCs(rec.x or 0, rec.y or 0, 14)
                local count = 0
                for i = 1, #allies do
                    if count >= Provider.MAX_WARN_ALLIES then break end
                    local ally = allies[i]
                    local eligible = PNC.Perception
                        and type(PNC.Perception.AreWarningAllies) == "function"
                        and PNC.Perception.AreWarningAllies(rec, ally)
                        or (type(ally) == "table" and ally.id ~= rec.id and ally.alive ~= false
                            and (not rec.factionID or ally.factionID == rec.factionID))
                    if eligible then
                        count = count + 1
                        if PNC.SecondaryChannel and PNC.SecondaryChannel.SetAlertLevel then
                            PNC.SecondaryChannel.SetAlertLevel(ally, "wary")
                        end
                        if PNC.PerceptionService and PNC.PerceptionService.RecordClue
                            and st.targetX and st.targetY
                        then
                            PNC.PerceptionService.RecordClue(ally, {
                                key = "warn:" .. tostring(rec.id),
                                kind = "hearsay_warning",
                                x = st.targetX,
                                y = st.targetY,
                                z = st.targetZ or 0,
                                severity = 70,
                            }, at)
                        end
                    end
                end
            end
        end
    end

    lease.lastProgressAt = at
    return true
end

local function cleanupReaction(lease, reason)
    if type(lease) ~= "table" then return true end
    Provider.ActiveByLease[lease.leaseId] = nil
    Provider.OffersByNPC[tostring(lease.npcId or "")] = nil
    if PNC.Tasking and PNC.Tasking.Claims and type(PNC.Tasking.Claims.ReleaseByLease) == "function" then
        PNC.Tasking.Claims.ReleaseByLease(lease.leaseId, reason or "reaction_ended")
    end
    local rec = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(lease.npcId) or nil
    if rec and rec.runtime then
        if rec.runtime.reactionState and rec.runtime.reactionState.leaseId == lease.leaseId then
            rec.runtime.reactionState = nil
        end
        rec.runtime.reactionMoveTarget = nil
    end
    return true
end

function Provider.Cancel(lease, reason) return cleanupReaction(lease, reason) end
function Provider.Complete(lease, reason) return cleanupReaction(lease, reason) end
function Provider.RollbackAssignment(intent)
    if intent and intent.npcId then
        Provider.OffersByNPC[tostring(intent.npcId)] = nil
    end
    return true
end

function Provider.GetRecoveryState(lease)
    if not Provider.CanContinue(lease) then return { terminal = true } end
    local phase = tostring(lease.phase or "WORKING")
    local snapshot = {
        lastProgressAt = tonumber(lease.lastProgressAt) or nowMs(),
        phase = phase,
        watchable = true,
        timeoutMs = 15000,
        recoveryReason = "reaction_timeout",
    }
    local recovery = PNC.Tasking and PNC.Tasking.Commands
    if phase == "TRAVEL" and recovery and recovery.ApplyMovementRecovery then
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(lease.npcId) or nil
        snapshot = recovery.ApplyMovementRecovery(snapshot, lease, record)
    end
    return snapshot
end

function Provider.GetDiagnostics(npcId)
    local npcKey = tostring(npcId or "")
    local offer = Provider.OffersByNPC[npcKey]
    local rec = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcKey) or nil
    return {
        pendingReaction = offer and offer.reaction and offer.reaction.id or nil,
        activeReaction = rec and rec.runtime and rec.runtime.reactionState
            and rec.runtime.reactionState.reactionId or nil,
    }
end

function Provider.EnsureSubscribed()
    if PsychopatzCore and PsychopatzCore.ShockingEventBus
        and type(PsychopatzCore.ShockingEventBus.Subscribe) == "function"
    then
        PsychopatzCore.ShockingEventBus.Subscribe("*", function(ev)
            Provider.HandleShockingEvent(ev)
        end, "PNC.ShockingReactionTaskProvider")
    end
end

function Provider.Reset()
    Provider.OffersByNPC = {}
    Provider.ActiveByLease = {}
    Provider.EnsureSubscribed()
end

Provider.EnsureSubscribed()

if PNC.Tasking and PNC.Tasking.Commands
    and type(PNC.Tasking.Commands.RegisterProvider) == "function"
then
    PNC.Tasking.Commands.RegisterProvider(Provider.DOMAIN, Provider)
end

return Provider
