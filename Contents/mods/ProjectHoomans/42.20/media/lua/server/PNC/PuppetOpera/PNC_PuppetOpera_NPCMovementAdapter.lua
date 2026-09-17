-- Puppet-owned NPC movement adapter.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.NPCMovement = PNC.PuppetOpera.NPCMovement or {}

local Adapter = PNC.PuppetOpera.NPCMovement
local Anchors = PNC.PuppetOpera.Anchors
local MoveIntent = PNC.BehaviorMoveIntent
local PathService = PNC.PathService
local NavigationRouter = PNC.NavigationRouter

local function runtimeOf(record)
    if not record then return nil end
    record.runtime = record.runtime or {}
    return record.runtime
end

local function targetPoint(target)
    return Anchors.WorldPoint(target)
end

local function intentBelongs(intent, sessionID)
    return intent
        and tostring(intent.puppetOperaSessionId or "")
            == tostring(sessionID or "")
end

local function sameNumber(left, right)
    if left == nil or right == nil then return left == right end
    return tonumber(left) == tonumber(right)
end

local function intentMatchesClaim(intent, claim, sessionID)
    return intentBelongs(intent, sessionID)
        and claim ~= nil
        and tostring(intent.reason or "")
            == tostring(claim.reason or "")
        and sameNumber(intent.x, claim.requestedX)
        and sameNumber(intent.y, claim.requestedY)
        and sameNumber(intent.z, claim.requestedZ)
end

function Adapter.IsOwned(record, sessionID)
    local runtime = record and record.runtime or nil
    local claim = runtime and runtime.puppetOperaMovement or nil
    return claim ~= nil
        and tostring(claim.sessionId or "") == tostring(sessionID or "")
end

function Adapter.Start(session, actor)
    if type(session) ~= "table" or type(actor) ~= "table" then
        return false, "npc_movement_arguments_invalid"
    end
    local record = actor.record
    local body = actor.body
    local target = targetPoint(actor.target)
    if not record or not body or not target then
        return false, "npc_movement_actor_unavailable"
    end
    local runtime = runtimeOf(record)
    local claim = runtime.puppetOperaMovement
    if claim and tostring(claim.sessionId or "")
        ~= tostring(session.sessionId or "")
    then
        return false, "npc_movement_owned_by_other"
    end

    local tx = target.x
    local ty = target.y
    local tz = target.z
    local policyName
    local providerName
    local policy
    local steeringTarget
    local navigation
    local ownershipReason = "puppet_opera:" .. tostring(session.sessionId)
    if NavigationRouter and NavigationRouter.Resolve then
        policyName, providerName, policy = NavigationRouter.Resolve(
            record,
            "puppet_opera:" .. tostring(session.sessionId),
            { navigationPolicy = "local" },
            body
        )
        if providerName ~= NavigationRouter.DIRECT_PROVIDER
            and NavigationRouter.GetSteeringTarget
        then
            steeringTarget = NavigationRouter.GetSteeringTarget(
                record,
                body,
                {
                    x = tx,
                    y = ty,
                    z = tz,
                    mode = "walk",
                    stopDistance = 0.65,
                },
                policyName,
                providerName,
                policy
            )
        end
        if steeringTarget then
            tx = steeringTarget.x or tx
            ty = steeringTarget.y or ty
            tz = steeringTarget.z or tz
        end
        if providerName ~= NavigationRouter.DIRECT_PROVIDER then
            navigation = {
                navigationPolicy = policyName,
                navigationProvider = providerName,
                finalX = target.x,
                finalY = target.y,
                finalZ = target.z,
                waypointIndex = steeringTarget
                    and steeringTarget.waypointIndex or nil,
                steeringIndex = steeringTarget
                    and steeringTarget.steeringIndex or nil,
                steeringKind = steeringTarget
                    and steeringTarget.steeringKind or nil,
            }
        end
    end

    local accepted
    local movementState
    if MoveIntent and MoveIntent.RequestMove then
        accepted, movementState = MoveIntent.RequestMove(
            record,
            tx,
            ty,
            tz,
            "walk",
            0.65,
            ownershipReason,
            navigation
        )
    elseif PathService and PathService.MoveToward then
        accepted, movementState = PathService.MoveToward(
            record,
            body,
            tx,
            ty,
            tz,
            "walk",
            0.65,
            ownershipReason,
            navigation
        )
    else
        return false, "npc_movement_service_unavailable"
    end
    if accepted ~= true then
        return false, movementState or "npc_movement_request_rejected"
    end

    local intent = runtime.moveIntent
    if intent then
        intent.puppetOperaSessionId = tostring(session.sessionId)
        intent.puppetOperaRevision = tonumber(session.revision) or 0
    end
    runtime.puppetOperaMovement = {
        sessionId = tostring(session.sessionId),
        targetX = target.x,
        targetY = target.y,
        targetZ = target.z,
        requestedX = tx,
        requestedY = ty,
        requestedZ = tz,
        reason = ownershipReason,
        startedAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
    }
    actor.movementOwned = true
    actor.lastReason = movementState or "npc_movement_requested"
    return true, movementState or "npc_movement_requested"
end

function Adapter.Observe(session, actor)
    if type(session) ~= "table" or type(actor) ~= "table" then
        return false, "npc_movement_arguments_invalid"
    end
    local record = actor.record
    local body = actor.body
    local runtime = record and record.runtime or nil
    local claim = runtime and runtime.puppetOperaMovement or nil
    if not claim
        or tostring(claim.sessionId or "")
            ~= tostring(session.sessionId or "")
    then
        return false, "npc_movement_ownership_lost"
    end
    local intent = runtime and runtime.moveIntent or nil
    if not intent then
        return false, "npc_movement_intent_lost"
    end
    if not intentMatchesClaim(intent, claim, session.sessionId) then
        return false, "npc_movement_intent_replaced"
    end
    if Anchors.IsAt(body, actor.target, session.plan.tolerance) then
        actor.arrived = true
        actor.state = "arrived"
        actor.lastReason = "npc_arrived"
        return true, "arrived"
    end
    actor.lastReason = "npc_moving"
    return true, "moving"
end

function Adapter.Release(session, actor)
    if type(session) ~= "table" or type(actor) ~= "table" then
        return false, "npc_movement_arguments_invalid"
    end
    local record = actor.record
    local runtime = record and record.runtime or nil
    local claim = runtime and runtime.puppetOperaMovement or nil
    if not claim
        or tostring(claim.sessionId or "")
            ~= tostring(session.sessionId or "")
    then
        return false, "npc_movement_not_owned"
    end
    local intent = runtime.moveIntent
    if intentMatchesClaim(intent, claim, session.sessionId)
        and MoveIntent and MoveIntent.Hold
    then
        MoveIntent.Hold(record, "puppet_opera_release")
    end
    runtime.puppetOperaMovement = nil
    actor.movementOwned = false
    actor.lastReason = "npc_movement_released"
    return true, "released"
end

return Adapter
