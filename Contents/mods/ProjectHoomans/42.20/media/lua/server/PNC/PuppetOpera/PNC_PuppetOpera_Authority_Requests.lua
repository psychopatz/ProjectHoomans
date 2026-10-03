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

require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Requests_Session"
require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Requests_Readonly"

function Authority.HandleRequest(player, args)
    args = type(args) == "table" and args or {}
    local id = Internal.ownerID(player)
    local session = Authority.ByOwner[id]
    if not Internal.debugAllowed(player) then
        Internal.sendError(player, "debug_not_authorized", session)
        return false, "debug_not_authorized"
    end
    local action = tostring(args.action or "")
    local handled, accepted, result, reported
    handled, accepted, result, reported = Internal.handleSessionAction(
        player, session, args, action
    )
    if handled then
        if not accepted and not reported then
            Internal.sendError(player, result, session)
        end
        return accepted, result
    end
    handled, accepted, result, reported = Internal.handleReadonlyAction(
        player, session, args, action, id
    )
    if handled then
        if not accepted and not reported then
            Internal.sendError(player, result, session)
        end
        return accepted, result
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
    accepted, result = Internal.ownsRequest(session, player, args)
    if not accepted then
        Internal.sendError(player, result)
        return false, result
    end
    return false, "puppet_opera_action_unknown"
end

function Authority.GetSessionForOwner(player)
    return Authority.ByOwner[Internal.ownerID(player)]
end

return Authority
