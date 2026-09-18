-- Server-authoritative Puppet Opera player acknowledgement boundary.
--
-- This spoke owns the callbacks that acknowledge movement, facing, and
-- player-side beat work.  It only mutates state after the request contract,
-- current phase, revision, and world position have been verified.

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
local Anchors = Internal.Anchors or Opera.Anchors

local PLAYER_ACTIONS = {
    player_moving = true,
    player_arrived = true,
    player_facing = true,
    player_beat_started = true,
    player_beat_finished = true,
    player_cancelled = true,
}

local function isPlayerAcknowledgement(action)
    return PLAYER_ACTIONS[tostring(action or "")] == true
end

local function handlePlayerAcknowledgement(player, session, args, action)
    local accepted, reason = Internal.ownsRequest(session, player, args)
    if not accepted then
        Internal.sendError(player, reason)
        return false, reason
    end
    if action == "player_moving" then
        if session.phase ~= Opera.Phases.MOVING
            or tonumber(args.revision) ~= session.revision
        then
            return false, "player_movement_out_of_phase"
        end
        Internal.trace(session, "player_moving", { revision = args.revision })
        return true, "player_moving_acknowledged"
    end
    if action == "player_arrived" then
        if session.phase ~= Opera.Phases.MOVING
            or tonumber(args.revision) ~= session.revision
        then
            return false, "player_arrival_out_of_phase"
        end
        local actorID, actor = Internal.localActor(session)
        if not actor then return false, "player_actor_missing" end
        if not Anchors.IsAt(
            session.playerBody,
            actor.target,
            session.plan.tolerance
        ) then
            return false, "player_arrival_not_verified"
        end
        actor.arrived = true
        actor.state = "arrived"
        actor.lastReason = "player_arrived_verified"
        Internal.trace(session, "player_arrived", { actor = actorID })
        return true, "player_arrival_verified"
    end
    if action == "player_facing" then
        if session.phase ~= Opera.Phases.FACING
            or tonumber(args.revision) ~= session.revision
        then
            return false, "player_facing_out_of_phase"
        end
        local actorID, actor = Internal.localActor(session)
        if not actor then return false, "player_actor_missing" end
        local targetActor = actor.target and session.actors
            and session.actors[actor.target.faceTarget] or nil
        local target = targetActor and targetActor.target or nil
        if not target then return false, "player_facing_target_missing" end
        if not Anchors.IsFacing(
            session.playerBody,
            target,
            0.70
        ) then
            return false, "player_facing_not_verified"
        end
        actor.facing = true
        actor.lastReason = "player_facing_verified"
        Internal.trace(session, "player_facing", { actor = actorID })
        return true, "player_facing_verified"
    end
    if action == "player_beat_started" then
        if session.phase ~= Opera.Phases.PLAYING
            or tonumber(args.beatIndex) ~= session.beatIndex
            or tonumber(args.revision) ~= session.beatRevision
        then
            return false, "player_beat_start_out_of_phase"
        end
        local actorID, actor = Internal.localActor(session)
        if not actor then return false, "player_actor_missing" end
        session.beatStartedBy[actorID] = true
        actor.animationOwned = true
        Internal.trace(session, "player_beat_started", {
            actor = actorID,
            beat = session.beatIndex,
        })
        return true, "player_beat_start_verified"
    end
    if action == "player_beat_finished" then
        if session.phase ~= Opera.Phases.PLAYING
            or tonumber(args.beatIndex) ~= session.beatIndex
            or tonumber(args.revision) ~= session.beatRevision
        then
            return false, "player_beat_finish_out_of_phase"
        end
        local actorID, actor = Internal.localActor(session)
        if not actor then return false, "player_actor_missing" end
        session.beatFinishedBy[actorID] = true
        actor.animationOwned = false
        Internal.trace(session, "player_beat_finished", {
            actor = actorID,
            beat = session.beatIndex,
        })
        return true, "player_beat_finish_verified"
    end
    if action == "player_cancelled" then
        Internal.abortSession(
            session,
            tostring(args.reason or "player_cancelled")
        )
        return true, "session_aborted"
    end
    return false, "puppet_opera_action_unknown"
end

Internal.isPlayerAcknowledgement = isPlayerAcknowledgement
Internal.handlePlayerAcknowledgement = handlePlayerAcknowledgement

return Authority
