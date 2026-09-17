-- Puppet Opera public shared surface.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Blueprints = Opera.Blueprints
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints"
local Trace = Opera.Trace
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Trace"

Opera.Phases = Opera.Phases or {
    REQUESTED = "requested",
    VALIDATING = "validating",
    PLANNING = "planning",
    ACQUIRING = "acquiring",
    MOVING = "moving",
    FACING = "facing",
    READY = "ready",
    PLAYING = "playing",
    STOPPING = "stopping",
    RESTORED = "restored",
    COMPLETED = "completed",
    ABORTED = "aborted",
}

Opera.Config = Opera.Config or {
    movementTimeoutMs = 10000,
    facingTimeoutMs = 1500,
    beatGraceMs = 1500,
    acknowledgementTimeoutMs = 1500,
    leaseDurationMs = 15000,
    traceEvents = 128,
    maxRequestText = 96,
}

local function serializable(value)
    local kind = type(value)
    return kind ~= "function" and kind ~= "userdata" and kind ~= "thread"
end

local function copyTable(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth > 3 then return nil end
    local result = {}
    local key
    local child
    for key, child in pairs(value) do
        if serializable(child) then
            if type(child) == "table" then
                result[key] = copyTable(child, depth + 1)
            else
                result[key] = child
            end
        end
    end
    return result
end

function Opera.GetBlueprint(id)
    return Blueprints.Get(id)
end

function Opera.ListBlueprints()
    return Blueprints.List()
end

function Opera.NewSession(sessionID, ownerID, blueprint, now, loopEnabled)
    return {
        sessionId = tostring(sessionID),
        ownerId = tostring(ownerID or ""),
        blueprintId = blueprint.id,
        blueprintVersion = blueprint.version,
        blueprint = blueprint,
        createdAt = tonumber(now) or 0,
        updatedAt = tonumber(now) or 0,
        phase = Opera.Phases.REQUESTED,
        phaseDeadline = nil,
        revision = 0,
        loopEnabled = loopEnabled == true,
        beatIndex = 1,
        iteration = 0,
        beatStartedAt = nil,
        beatStartAt = nil,
        actors = {},
        plan = nil,
        trace = Trace.New(Opera.Config.traceEvents),
        lastError = nil,
        stopReason = nil,
        restored = false,
    }
end

function Opera.BuildSnapshot(session, includeTrace)
    if type(session) ~= "table" then return nil end
    local snapshot = {
        sessionId = session.sessionId,
        ownerId = session.ownerId,
        blueprintId = session.blueprintId,
        blueprintVersion = session.blueprintVersion,
        phase = session.phase,
        phaseDeadline = session.phaseDeadline,
        revision = session.revision,
        loopEnabled = session.loopEnabled == true,
        beatIndex = session.beatIndex,
        iteration = session.iteration,
        beatStartedAt = session.beatStartedAt,
        beatStartAt = session.beatStartAt,
        createdAt = session.createdAt,
        updatedAt = session.updatedAt,
        lastError = session.lastError,
        stopReason = session.stopReason,
        restored = session.restored == true,
        plan = copyTable(session.plan),
        actors = {},
    }
    local actorID
    local actor
    for actorID, actor in pairs(session.actors or {}) do
        snapshot.actors[actorID] = {
            id = actor.id,
            kind = actor.kind,
            label = actor.label,
            anchor = actor.anchor,
            state = actor.state,
            target = copyTable(actor.target),
            arrived = actor.arrived == true,
            facing = actor.facing == true,
            movementOwned = actor.movementOwned == true,
            animationOwned = actor.animationOwned == true,
            lastReason = actor.lastReason,
            lastUpdateAt = actor.lastUpdateAt,
        }
    end
    if includeTrace == true then
        snapshot.trace = Trace.Snapshot(session.trace)
    end
    return snapshot
end

return Opera
