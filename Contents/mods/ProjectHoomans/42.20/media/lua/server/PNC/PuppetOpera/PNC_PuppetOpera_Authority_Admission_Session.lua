-- Server-authoritative Puppet Opera session construction and acquisition.
--
-- This provider owns actor ordering, session state construction, NPC lease
-- acquisition, movement startup, and the authoritative start operation.  It
-- consumes the resolution and preflight contracts from the sibling provider.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Authority = Opera.Authority or {}
Opera.Authority = Authority
local Internal = Authority.Internal or {}
Authority.Internal = Internal
local Blueprints = Internal.Blueprints or Opera.Blueprints
local Anchors = Internal.Anchors or Opera.Anchors
local NPCMovement = Internal.NPCMovement or Opera.NPCMovement
local NPCOverride = Internal.NPCOverride or Opera.Override

local now = Internal.now
local trace = Internal.trace
local ownerID = Internal.ownerID
local inRange = Internal.inRange
local actorFailureReason = Internal.actorFailureReason
local invalidPlayer = Internal.invalidPlayer
local indexSession = Internal.indexSession
local releaseActors = Internal.releaseActors
local unindexSession = Internal.unindexSession
local setPhase = Internal.setPhase
local closeSession = Internal.closeSession
local resolveNPC = Internal.resolveNPC
local resolveBlueprint = Internal.resolveBlueprint
local validatePlan = Internal.validatePlan
local supportedActors = Internal.supportedActors
local actorAllowsKind = Internal.actorAllowsKind
local requestedBinding = Internal.requestedBinding

local function orderedActorIDs(blueprint)
    local ids = {}
    for actorID in pairs(blueprint and blueprint.actors or {}) do
        ids[#ids + 1] = tostring(actorID)
    end
    table.sort(ids, function(left, right)
        if left == "player" then return right ~= "player" end
        if right == "player" then return false end
        return left < right
    end)
    return ids
end

local function localActor(session)
    for actorID, actor in pairs(session and session.actors or {}) do
        if actor.kind == "local_player" then
            return tostring(actorID), actor
        end
    end
    return nil, nil
end

local function makeSession(player, blueprint, resolvedActors, plan, loopEnabled)
    Authority.Serial = Authority.Serial + 1
    local timestamp = now()
    local sessionID = "puppet:" .. tostring(timestamp) .. ":"
        .. tostring(Authority.Serial)
    local id = ownerID(player)
    local session = Opera.NewSession(
        sessionID,
        id,
        blueprint,
        timestamp,
        loopEnabled == true and blueprint.playback.allowLoop == true
    )
    session.ownerPlayer = player
    session.playerBody = player
    session.plan = plan
    for _, actorID in ipairs(orderedActorIDs(blueprint)) do
        local definition = blueprint.actors[actorID]
        local resolved = resolvedActors[actorID]
        local actor = {
            id = actorID,
            kind = resolved.kind,
            bindingID = resolved.bindingID,
            label = definition.label,
            anchor = definition.anchor,
            target = plan.actors[actorID],
            body = resolved.body,
            record = resolved.record,
            npcID = resolved.kind == "nearby_live_npc"
                and resolved.bindingID or nil,
            state = "pending",
            arrived = false,
            facing = false,
            movementOwned = false,
            animationOwned = false,
            overrideOwned = false,
        }
        session.actors[actorID] = actor
        if actor.kind == "nearby_live_npc" then
            session.npcID = session.npcID or tostring(actor.npcID)
        end
    end
    trace(session, "session_created", {
        blueprint = blueprint.id,
        npc = session.npcID,
        loop = session.loopEnabled,
    }, timestamp)
    return session
end

local function claimNPCLease(session, actor)
    local record = actor and actor.record or nil
    local runtime = record and record.runtime or nil
    if not runtime then return false end
    local existing = runtime.puppetOperaLease
    if existing
        and tostring(existing.sessionId or "")
            ~= tostring(session.sessionId or "")
    then
        return false
    end
    runtime.puppetOperaLease = {
        sessionId = tostring(session.sessionId),
        ownerId = tostring(session.ownerId or ""),
        expiresAt = now() + Opera.Config.leaseDurationMs,
    }
    return true
end

local function startSession(player, args, previewOnly)
    args = type(args) == "table" and args or {}
    previewOnly = previewOnly == true
    local blueprintID = tostring(args.blueprintId or "social.kiss_player_npc")
    local blueprint, blueprintReason = resolveBlueprint(args)
    local current = Authority.ByOwner[ownerID(player)]
    local reason
    local plan
    local planOK
    local actorOK
    local resolvedActors = {}
    local seenNPCs = {}
    local npcCount = 0
    if current then
        if current.previewOnly then
            closeSession(current, Opera.Phases.RESTORED, "preview_replaced")
            current = nil
        else
            return false, "owner_session_already_active"
        end
    end
    if not blueprint then return false, blueprintReason end
    local runtimeOK
    runtimeOK, reason = Blueprints.ValidateRuntime(blueprint)
    if not runtimeOK then return false, reason end
    actorOK, reason = supportedActors(blueprint)
    if not actorOK then return false, reason end
    reason = invalidPlayer(player)
    if reason then return false, reason end

    -- Every neutral slot is resolved from a server-validated live binding.
    -- The legacy npcID field remains accepted for the original fixed `npc`
    -- slot only. World bodies and positions are never accepted from the
    -- client; only registry ids cross the transport boundary.
    for actorID, definition in pairs(blueprint.actors or {}) do
        local binding = requestedBinding(args, actorID, definition)
        if not binding then
            if definition.required ~= false then
                return false, "actor_binding_missing:" .. tostring(actorID)
            end
        elseif binding == "__local_player__" then
            if not actorAllowsKind(definition, "local_player") then
                return false, "actor_kind_not_allowed:local_player:"
                    .. tostring(actorID)
            end
            resolvedActors[tostring(actorID)] = {
                kind = "local_player",
                bindingID = "__local_player__",
                body = player,
                record = nil,
            }
        else
            if not actorAllowsKind(definition, "nearby_live_npc") then
                return false, "actor_kind_not_allowed:nearby_live_npc:"
                    .. tostring(actorID)
            end
            local npcID = binding
            local record, body
            local overrideReady
            local overrideReason
            record, body, reason = resolveNPC(npcID)
            if not body then return false, reason end
            overrideReady, overrideReason = NPCOverride.CanAcquire(
                record,
                body
            )
            if overrideReady ~= true then
                return false, actorFailureReason(
                    overrideReason,
                    actorID,
                    body
                )
            end
            if not inRange(
                player,
                body,
                tonumber(Opera.Config.runtimeActorRange) or 12
            ) then
                return false, "npc_out_of_range:" .. tostring(actorID)
            end
            local resolvedID = tostring(record.id)
            if seenNPCs[resolvedID] then
                return false, "npc_bound_to_multiple_actor_slots"
            end
            if Authority.ByActor[resolvedID] then
                return false, "npc_session_already_active:" .. tostring(actorID)
            end
            seenNPCs[resolvedID] = true
            resolvedActors[tostring(actorID)] = {
                kind = "nearby_live_npc",
                bindingID = resolvedID,
                record = record,
                body = body,
            }
            npcCount = npcCount + 1
        end
    end
    if npcCount == 0 then
        return false, "runtime_actor_missing"
    end
    plan, reason = Anchors.BuildPlan(blueprint, player)
    if not plan then return false, reason end
    planOK, reason = validatePlan(plan)
    if not planOK then return false, reason end

    local session = makeSession(
        player,
        blueprint,
        resolvedActors,
        plan,
        args.loop == true
    )
    session.previewOnly = previewOnly
    indexSession(session)
    setPhase(session, Opera.Phases.ACQUIRING, now() + 1500, "acquiring", false)
    local accepted
    for _, actorID in ipairs(orderedActorIDs(blueprint)) do
        local actor = session.actors[actorID]
        if actor.kind == "nearby_live_npc" then
            accepted, reason = NPCOverride.Acquire(session, actor)
            if not accepted then
                releaseActors(session)
                unindexSession(session)
                return false, reason or "npc_override_acquire_failed"
            end
            accepted = claimNPCLease(session, actor)
            if not accepted then
                releaseActors(session)
                unindexSession(session)
                return false, "npc_lease_claim_failed"
            end
            trace(session, "npc_override_acquired", {
                actor = actorID,
                ownerKind = actor.overrideOwnerKind,
                reason = actor.lastReason,
            })
            accepted, reason = NPCMovement.Start(session, actor)
            if not accepted then
                releaseActors(session)
                unindexSession(session)
                return false, reason or "npc_movement_start_failed"
            end
            actor.state = "moving"
            actor.movementOwned = true
        elseif actor.kind == "local_player" then
            actor.state = "moving"
        end
    end
    setPhase(
        session,
        Opera.Phases.MOVING,
        now() + Opera.Config.movementTimeoutMs,
        "movement_started",
        true
    )
    return true, session
end

Internal.orderedActorIDs = orderedActorIDs
Internal.localActor = localActor
Internal.makeSession = makeSession
Internal.claimNPCLease = claimNPCLease
Internal.startSession = startSession

return Authority
