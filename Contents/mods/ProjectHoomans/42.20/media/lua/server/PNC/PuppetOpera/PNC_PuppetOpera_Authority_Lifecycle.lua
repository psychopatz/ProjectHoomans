-- Puppet Opera authority session lifecycle.
-- Owns delivery, phase transitions, session indexes, actor release, and close
-- behavior while preserving the Authority.Internal contract.

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

local Const = PNC.Const or {}
local NPCMovement = Opera.NPCMovement
    or require "PNC/PuppetOpera/PNC_PuppetOpera_NPCMovementAdapter"
local NPCAnimation = Opera.NPCAnimation
    or require "PNC/PuppetOpera/PNC_PuppetOpera_NPCAnimationAdapter"
local NPCOverride = Opera.Override
    or require "PNC/PuppetOpera/PNC_PuppetOpera_OverrideAdapter"
local now = Internal.now
local trace = Internal.trace

require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Lifecycle_Response"
local sendToClient = Internal.sendToClient
local sendState = Internal.sendState
local sendError = Internal.sendError

local function setPhase(session, phase, deadline, reason, notify)
    session.phase = phase
    session.phaseDeadline = deadline
    session.updatedAt = now()
    session.revision = (tonumber(session.revision) or 0) + 1
    if reason then session.lastReason = tostring(reason) end
    trace(session, "phase", {
        phase = phase,
        reason = reason,
        revision = session.revision,
    })
    if notify ~= false then sendState(session, false) end
end

local function rememberSnapshot(session, includeTrace)
    Authority.LastSnapshots[session.ownerId] = Opera.BuildSnapshot(
        session,
        includeTrace == true
    )
end

local function indexSession(session)
    Authority.Sessions[session.sessionId] = session
    Authority.ByOwner[session.ownerId] = session
    Authority.ByActor["player:" .. session.ownerId] = session
    for actorID, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" and actor.npcID then
            Authority.ByActor[tostring(actor.npcID)] = session
        elseif actor.kind == "local_player" then
            Authority.ByActor["player:" .. session.ownerId] = session
        end
    end
end

local function unindexSession(session)
    if Authority.Sessions[session.sessionId] == session then
        Authority.Sessions[session.sessionId] = nil
    end
    if Authority.ByOwner[session.ownerId] == session then
        Authority.ByOwner[session.ownerId] = nil
    end
    if Authority.ByActor["player:" .. session.ownerId] == session then
        Authority.ByActor["player:" .. session.ownerId] = nil
    end
    for _, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" and actor.npcID
            and Authority.ByActor[tostring(actor.npcID)] == session
        then
            Authority.ByActor[tostring(actor.npcID)] = nil
        end
    end
end

local function clearNPCLease(session, actor)
    actor = actor or session and session.actors and session.actors.npc
    local record = actor and actor.record or nil
    local runtime = record and record.runtime or nil
    local lease = runtime and runtime.puppetOperaLease or nil
    if lease and tostring(lease.sessionId or "")
        == tostring(session.sessionId or "")
    then
        runtime.puppetOperaLease = nil
    end
end

local function releaseActors(session)
    for _, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" then
            if actor.animationOwned
                or NPCAnimation.IsOwned(actor.body, session.sessionId)
            then
                NPCAnimation.Release(session, actor)
            end
            if actor.movementOwned
                or NPCMovement.IsOwned(actor.record, session.sessionId)
            then
                NPCMovement.Release(session, actor)
            end
            if actor.overrideOwned
                or NPCOverride.IsOwned(actor.record, session.sessionId)
            then
                NPCOverride.Release(session, actor)
            end
            clearNPCLease(session, actor)
        end
    end
end

local function closeSession(session, finalPhase, reason, errorText)
    if not session or session.closed then return false end
    session.closed = true
    session.stopReason = reason and tostring(reason) or nil
    session.lastError = errorText and tostring(errorText) or session.lastError
    setPhase(session, Opera.Phases.STOPPING, now() + 1000, reason, true)
    trace(session, "release_begin", { reason = reason, error = errorText })
    releaseActors(session)
    session.restored = true
    session.updatedAt = now()
    session.phase = finalPhase
    session.phaseDeadline = nil
    session.revision = (tonumber(session.revision) or 0) + 1
    trace(session, "session_closed", {
        phase = finalPhase,
        reason = reason,
        error = errorText,
    })
    rememberSnapshot(session, true)
    unindexSession(session)
    sendState(session, true)
    return true
end

local function abortSession(session, reason)
    trace(session, "abort", { reason = reason })
    return closeSession(session, Opera.Phases.ABORTED, reason, reason)
end


Internal.setPhase = setPhase
Internal.indexSession = indexSession
Internal.releaseActors = releaseActors
Internal.unindexSession = unindexSession
Internal.closeSession = closeSession
Internal.abortSession = abortSession

return true
