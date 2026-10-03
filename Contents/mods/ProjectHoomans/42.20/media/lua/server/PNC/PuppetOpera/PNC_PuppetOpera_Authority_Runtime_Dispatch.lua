-- Server-authoritative Puppet Opera runtime dispatch.
--
-- This provider owns override maintenance, phase dispatch, timeout handling,
-- and the public runtime pump entry points.  The runtime entry module remains
-- a dependency-ordered composition root.

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
local NPCOverride = Internal.NPCOverride or Opera.Override
local activeSafety = Internal.activeSafety
local pumpMoving = Internal.pumpMoving
local pumpFacing = Internal.pumpFacing
local pumpReady = Internal.pumpReady
local pumpPlaying = Internal.pumpPlaying

local function maintainOverrides(session, timestamp)
    local actorFailureReason = Internal.actorFailureReason
    local actorID
    local actor
    local maintained
    local reason
    if not NPCOverride or not NPCOverride.Maintain then return true end
    for actorID, actor in pairs(session.actors or {}) do
        if actor.record then
            maintained, reason = NPCOverride.Maintain(
                session,
                actor,
                timestamp
            )
            if maintained ~= true then
                return false, actorFailureReason(reason, actorID, actor.body)
            end
        end
    end
    return true
end

function Authority.PumpSession(session, timestamp)
    if not session or session.closed then return false end
    local safe
    local reason
    safe, reason = activeSafety(session, timestamp)
    if not safe then
        Internal.abortSession(session, reason)
        return false
    end
    safe, reason = maintainOverrides(session, timestamp)
    if not safe then
        Internal.abortSession(session, reason)
        return false
    end
    if session.phase == Opera.Phases.MOVING then
        safe, reason = pumpMoving(session, timestamp)
    elseif session.phase == Opera.Phases.FACING then
        safe, reason = pumpFacing(session, timestamp)
    elseif session.phase == Opera.Phases.READY then
        if session.previewOnly then
            session.phaseDeadline = timestamp + (
                tonumber(Opera.Config.placementPreviewLeaseMs) or 30000
            )
            safe = true
        else
            safe, reason = pumpReady(session, timestamp)
        end
    elseif session.phase == Opera.Phases.PLAYING then
        safe, reason = pumpPlaying(session, timestamp)
    else
        safe = true
    end
    if not safe then
        Internal.abortSession(session, reason or "puppet_opera_phase_failed")
        return false
    end
    if session.phaseDeadline and timestamp > session.phaseDeadline
        and session.phase ~= Opera.Phases.PLAYING
    then
        Internal.abortSession(
            session,
            "phase_timeout:" .. tostring(session.phase)
        )
        return false
    end
    return true
end

function Authority.Pump()
    local timestamp = Internal.now()
    local sessions = {}
    local sessionID
    local session
    for sessionID, session in pairs(Authority.Sessions) do
        sessions[#sessions + 1] = session
    end
    for _, session in ipairs(sessions) do
        Authority.PumpSession(session, timestamp)
    end
end

Internal.maintainOverrides = maintainOverrides

return Authority
