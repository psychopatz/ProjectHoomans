-- Server-authoritative Puppet Opera safety and lease checks.
--
-- This provider owns per-tick actor admission checks while a session is
-- active.  It keeps movement, action-state, ownership, and lease failures
-- behind the runtime's bounded Internal handoff.

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
local NPCMovement = Internal.NPCMovement or Opera.NPCMovement
local NPCAnimation = Internal.NPCAnimation or Opera.NPCAnimation
local NPCOverride = Internal.NPCOverride or Opera.Override
local Registry = Internal.Registry or PNC.Registry

local function refreshLease(session, timestamp)
    for _, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" then
            local record = actor.record
            local runtime = record and record.runtime or nil
            local lease = runtime and runtime.puppetOperaLease or nil
            if not lease or tostring(lease.sessionId or "")
                ~= tostring(session.sessionId or "")
            then
                return false
            end
            lease.expiresAt = timestamp + Opera.Config.leaseDurationMs
        end
    end
    return true
end

local function activeSafety(session, timestamp)
    local invalidPlayer = Internal.invalidPlayer
    local invalidNPC = Internal.invalidNPC
    local puppetMovementIsSafe = Internal.puppetMovementIsSafe
    local actorFailureReason = Internal.actorFailureReason
    local unsafeNPCActionState = Internal.unsafeNPCActionState
    local managedBumpCanBeReleased = Internal.managedBumpCanBeReleased
        or Internal.nonCombatBumpCanBeReleased
    local hasValue = Internal.hasValue
    local inRange = Internal.inRange
    local npcAnimation = NPCAnimation
    local npcOverride = NPCOverride

    local playerReason = invalidPlayer(session.playerBody)
    if playerReason then return false, playerReason end
    for actorID, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" then
            local live = Registry and Registry.GetLiveZombie
                and Registry.GetLiveZombie(actor.npcID) or nil
            if live ~= actor.body then
                return false, "npc_body_changed:" .. tostring(actorID)
            end
            local reason = invalidNPC(actor.record, actor.body, session)
            if reason then
                return false, actorFailureReason(reason, actorID, actor.body)
            end
            if PNC.LiveBodyControl
                and PNC.LiveBodyControl.IsSeated
                and PNC.LiveBodyControl.IsSeated(actor.record)
            then
                return false, "npc_became_seated:" .. tostring(actorID)
            end
            local movementSafe
            movementSafe, reason = puppetMovementIsSafe(session, actor)
            if not movementSafe then return false, reason end
            local traversalActive = PNC.PathService
                and PNC.PathService.IsTraversalActive
                and PNC.PathService.IsTraversalActive(
                    actor.record,
                    actor.body
                )
                or false
            local traversalOwned = traversalActive
                and NPCMovement
                and NPCMovement.IsOwned
                and NPCMovement.IsOwned(actor.record, session.sessionId)
                or false
            if unsafeNPCActionState(actor.body)
                and not npcAnimation.IsOwned(actor.body, session.sessionId)
                and not managedBumpCanBeReleased(actor.body)
                and not traversalOwned
            then
                return false, actorFailureReason(
                    "npc_action_state_interrupted",
                    actorID,
                    actor.body
                )
            end
            if traversalActive and not traversalOwned then
                return false, "npc_traversal_started:" .. tostring(actorID)
            end
            local runtime = actor.record and actor.record.runtime or nil
            local overrideOwned = npcOverride.IsOwned(
                actor.record,
                session.sessionId
            )
            if runtime and (
                hasValue(runtime.animationScene)
                    or hasValue(runtime.conversationLease)
                    or hasValue(runtime.taskLeaseId)
                    or hasValue(runtime.orderLeaseId)
                    or hasValue(runtime.facilityActivity)
                    or hasValue(runtime.workOrderId)
                    or hasValue(runtime.medicalCare)
                    or hasValue(runtime.treatment)
                    or hasValue(runtime.roamAmbient)
            ) then
                if not overrideOwned then
                    return false, "npc_behavior_ownership_lost:"
                        .. tostring(actorID)
                end
            end
            if runtime and runtime.followState
                and runtime.followState.ownerMoving == true
            then
                if not overrideOwned then
                    return false, "npc_movement_ownership_lost:"
                        .. tostring(actorID)
                end
            end
            if not inRange(session.playerBody, actor.body, 20) then
                return false, "actors_out_of_range:" .. tostring(actorID)
            end
        end
    end
    if not refreshLease(session, timestamp) then
        return false, "npc_session_lease_lost"
    end
    return true
end

Internal.activeSafety = activeSafety

return Authority
