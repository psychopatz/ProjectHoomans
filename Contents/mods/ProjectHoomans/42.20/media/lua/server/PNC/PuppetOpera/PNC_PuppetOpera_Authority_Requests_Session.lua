-- Puppet Opera session lifecycle request actions.
--
-- The transport root owns authorization and dispatch; this provider owns
-- start, preview, replay, and stop transitions.

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

local function handleSessionAction(player, session, args, action)
    local accepted
    local reason
    if action == "start" then
        accepted, reason = Internal.startSession(player, args, false)
        if not accepted then
            Internal.sendError(player, reason, session)
            return true, false, reason, true
        end
        return true, true, reason, true
    end
    if action == "preview_start" then
        if session and not session.previewOnly then
            Internal.sendError(player, "playback_session_active", session)
            return true, false, "playback_session_active", true
        end
        accepted, reason = Internal.startSession(player, args, true)
        if not accepted then
            Internal.sendError(player, reason, session)
            return true, false, reason, true
        end
        return true, true, reason, true
    end
    if action == "preview_stop" then
        if not session then return true, true, "preview_missing", true end
        if not session.previewOnly then
            Internal.sendError(player, "playback_session_active", session)
            return true, false, "playback_session_active", true
        end
        accepted, reason = Internal.ownsRequest(session, player, args)
        if not accepted then
            Internal.sendError(player, reason, session)
            return true, false, reason, true
        end
        Internal.closeSession(session, Opera.Phases.RESTORED, "preview_stop")
        return true, true, "preview_stopped", true
    end
    if action == "preview_refresh" then
        if not session then return true, false, "preview_missing", true end
        if not session.previewOnly then
            Internal.sendError(player, "playback_session_active", session)
            return true, false, "playback_session_active", true
        end
        accepted, reason = Internal.ownsRequest(session, player, args)
        if not accepted then
            Internal.sendError(player, reason, session)
            return true, false, reason, true
        end
        local refreshAt = Internal.now()
        local safe
        safe, reason = Internal.activeSafety(session, refreshAt)
        if not safe then
            Internal.abortSession(session, reason)
            return true, false, reason, true
        end
        safe, reason = Internal.maintainOverrides(session, refreshAt)
        if not safe then
            Internal.abortSession(session, reason)
            return true, false, reason, true
        end
        session.phaseDeadline = refreshAt + (
            tonumber(Opera.Config.placementPreviewLeaseMs) or 30000
        )
        Internal.sendState(session, false)
        return true, true, "preview_refreshed", true
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
            return true, false, reason, true
        end
        return true, true, reason, true
    end
    if action == "stop" then
        accepted, reason = Internal.ownsRequest(session, player, args)
        if not accepted then
            Internal.sendError(player, reason, session)
            return true, false, reason, true
        end
        Internal.closeSession(session, Opera.Phases.RESTORED, "user_stop")
        return true, true, "stopped", true
    end
    return false
end

Internal.handleSessionAction = handleSessionAction

return Authority

