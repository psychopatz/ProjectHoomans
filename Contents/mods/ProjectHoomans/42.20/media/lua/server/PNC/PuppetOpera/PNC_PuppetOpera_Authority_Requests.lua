-- Server-authoritative Puppet Opera request boundary.
--
-- This spoke owns transport-facing action routing and server-side acknowledgements.
-- It deliberately delegates admission, lifecycle, and runtime work through the
-- authority's bounded Internal handoff table.

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
local Const = Internal.Const or PNC.Const or {}

Authority.RequestActions = Authority.RequestActions or {
    START = "start",
    REPLAY = "replay",
    STOP = "stop",
    SNAPSHOT = "snapshot",
    DUMP_TRACE = "dump_trace",
    PREFLIGHT = "preflight",
    PREVIEW_START = "preview_start",
    PREVIEW_STOP = "preview_stop",
    PREVIEW_REFRESH = "preview_refresh",
    PLAYER_MOVING = "player_moving",
    PLAYER_ARRIVED = "player_arrived",
    PLAYER_FACING = "player_facing",
    PLAYER_BEAT_STARTED = "player_beat_started",
    PLAYER_BEAT_FINISHED = "player_beat_finished",
    PLAYER_CANCELLED = "player_cancelled",
}

local function ownsRequest(session, player, args)
    if not session or session.ownerPlayer ~= player then
        return false, "session_owner_mismatch"
    end
    if args.sessionId and tostring(args.sessionId) ~= session.sessionId then
        return false, "session_id_mismatch"
    end
    return true
end

Internal.ownsRequest = ownsRequest

function Authority.HandleRequest(player, args)
    args = type(args) == "table" and args or {}
    local id = Internal.ownerID(player)
    local session = Authority.ByOwner[id]
    if not Internal.debugAllowed(player) then
        Internal.sendError(player, "debug_not_authorized", session)
        return false, "debug_not_authorized"
    end
    local action = tostring(args.action or "")
    local accepted
    local reason
    if action == "start" then
        accepted, reason = Internal.startSession(player, args, false)
        if not accepted then
            Internal.sendError(player, reason, session)
            return false, reason
        end
        return true, reason
    end
    if action == "preview_start" then
        if session and not session.previewOnly then
            Internal.sendError(player, "playback_session_active", session)
            return false, "playback_session_active"
        end
        accepted, reason = Internal.startSession(player, args, true)
        if not accepted then
            Internal.sendError(player, reason, session)
            return false, reason
        end
        return true, reason
    end
    if action == "preview_stop" then
        if not session then return true, "preview_missing" end
        if not session.previewOnly then
            Internal.sendError(player, "playback_session_active", session)
            return false, "playback_session_active"
        end
        accepted, reason = ownsRequest(session, player, args)
        if not accepted then
            Internal.sendError(player, reason, session)
            return false, reason
        end
        Internal.closeSession(session, Opera.Phases.RESTORED, "preview_stop")
        return true, "preview_stopped"
    end
    if action == "preview_refresh" then
        if not session then return false, "preview_missing" end
        if not session.previewOnly then
            Internal.sendError(player, "playback_session_active", session)
            return false, "playback_session_active"
        end
        accepted, reason = ownsRequest(session, player, args)
        if not accepted then
            Internal.sendError(player, reason, session)
            return false, reason
        end
        local refreshAt = Internal.now()
        local safe
        safe, reason = Internal.activeSafety(session, refreshAt)
        if not safe then
            Internal.abortSession(session, reason)
            return false, reason
        end
        safe, reason = Internal.maintainOverrides(session, refreshAt)
        if not safe then
            Internal.abortSession(session, reason)
            return false, reason
        end
        session.phaseDeadline = refreshAt + (
            tonumber(Opera.Config.placementPreviewLeaseMs) or 30000
        )
        Internal.sendState(session, false)
        return true, "preview_refreshed"
    end
    if action == "preflight" then
        local preflight
        preflight, reason = Internal.buildPreflight(player, args)
        if not preflight then
            Internal.sendError(player, reason, session)
            return false, reason
        end
        Internal.sendToClient(player, Const.CMD_PUPPET_OPERA_STATE, {
            phase = session and session.phase
                or (preflight.ready and "ready" or "blocked"),
            blueprintId = preflight.blueprintId,
            preflight = preflight,
        })
        return true, { preflight = preflight }
    end
    if action == "replay" then
        if session then
            local actorBindings = {}
            for actorID, actor in pairs(session.actors or {}) do
                if actor.bindingID then
                    actorBindings[actorID] = actor.bindingID
                end
            end
            local loop = session.loopEnabled
            Internal.closeSession(session, Opera.Phases.RESTORED, "replay")
            args.actors = args.actors or actorBindings
            args.npcID = args.npcID or session.npcID
            args.loop = args.loop == true or loop
        end
        accepted, reason = Internal.startSession(player, args, false)
        if not accepted then
            Internal.sendError(player, reason, session)
            return false, reason
        end
        return true, reason
    end
    if action == "stop" then
        accepted, reason = ownsRequest(session, player, args)
        if not accepted then
            Internal.sendError(player, reason, session)
            return false, reason
        end
        Internal.closeSession(session, Opera.Phases.RESTORED, "user_stop")
        return true, "stopped"
    end
    if action == "snapshot" then
        if session then
            Internal.sendState(session, false)
        else
            Internal.sendToClient(player, Const.CMD_PUPPET_OPERA_STATE, {
                phase = "idle",
                blueprints = Opera.ListBlueprints(),
                lastSnapshot = Authority.LastSnapshots[id],
            })
        end
        return true, "snapshot_sent"
    end
    if action == "dump_trace" then
        if not session then
            local last = Authority.LastSnapshots[id]
            if last then
                Internal.sendToClient(player, Const.CMD_PUPPET_OPERA_TRACE, last)
            else
                Internal.sendToClient(
                    player,
                    Const.CMD_PUPPET_OPERA_TRACE,
                    { trace = {} }
                )
            end
            return true, "trace_sent"
        end
        accepted, reason = ownsRequest(session, player, args)
        if not accepted then return false, reason end
        Internal.sendToClient(
            player,
            Const.CMD_PUPPET_OPERA_TRACE,
            Opera.BuildSnapshot(session, true)
        )
        return true, "trace_sent"
    end

    if not session then
        Internal.sendError(player, "session_missing")
        return false, "session_missing"
    end
    if Internal.isPlayerAcknowledgement(action) then
        return Internal.handlePlayerAcknowledgement(
            player,
            session,
            args,
            action
        )
    end
    accepted, reason = ownsRequest(session, player, args)
    if not accepted then
        Internal.sendError(player, reason)
        return false, reason
    end
    return false, "puppet_opera_action_unknown"
end

function Authority.GetSessionForOwner(player)
    return Authority.ByOwner[Internal.ownerID(player)]
end

return Authority
