-- Server-authoritative Puppet Opera animation timeline coordination.
--
-- This provider owns timeline lookup, node selection, and animation adapter
-- coordination.  It exposes only the runtime handoff functions consumed by
-- the phase pump.

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
local NPCAnimation = Internal.NPCAnimation or Opera.NPCAnimation

local function timelineFor(beat, actorID, actorKind)
    if Blueprints.GetTimeline then
        return Blueprints.GetTimeline(beat, actorID, actorKind) or {}
    end
    local track = Blueprints.GetTrack
        and Blueprints.GetTrack(beat, actorID, actorKind)
        or beat.tracks and beat.tracks[actorID]
        or beat.npc
    return {
        {
            id = "legacy_" .. tostring(actorID),
            type = "animation",
            startMs = 0,
            durationMs = tonumber(beat.durationMs) or 900,
            track = track,
        },
    }
end

local function timelineStartOffset(beat, actorID, actorKind)
    local earliest
    for _, node in ipairs(timelineFor(beat, actorID, actorKind)) do
        if node.type == "animation" then
            local startMs = tonumber(node.startMs or node.offsetMs) or 0
            if earliest == nil or startMs < earliest then
                earliest = startMs
            end
        end
    end
    return earliest or 0
end

local function releaseTimelineAnimation(session, actor)
    if not actor.animationOwned then return true end
    local released, reason = NPCAnimation.Release(session, actor)
    if released ~= true then
        return false, reason or "npc_animation_release_failed"
    end
    actor.animationOwned = false
    return true
end

local function pendingTimelineNode(nodes, elapsed, actor)
    for index, node in ipairs(nodes or {}) do
        local startMs = tonumber(node.startMs or node.offsetMs) or 0
        local durationMs = tonumber(node.durationMs) or 0
        local nodeID = tostring(node.id or ("node_" .. tostring(index)))
        local finished = actor.timelineNodeFinished == true
            and tostring(actor.timelineNodeID or "") == nodeID
        if not finished
            and elapsed >= startMs
            and elapsed < startMs + durationMs
        then
            return node, index
        end
    end
    return nil
end

local function hasPendingTimelineNode(nodes, elapsed, actor)
    for index, node in ipairs(nodes or {}) do
        local startMs = tonumber(node.startMs or node.offsetMs) or 0
        local durationMs = tonumber(node.durationMs) or 0
        local nodeID = tostring(node.id or ("node_" .. tostring(index)))
        local finished = actor.timelineNodeFinished == true
            and tostring(actor.timelineNodeID or "") == nodeID
        if not finished and startMs + durationMs > elapsed then
            return true
        end
    end
    return false
end

local function observeTimelineAnimation(
    session,
    actor,
    nodeBeat,
    track,
    nodes,
    elapsed,
    nodeID
)
    local ok, status = NPCAnimation.Observe(
        session,
        actor,
        nodeBeat,
        track
    )
    if not ok then return false, status end
    if status == "finished" then
        local released, releaseReason = releaseTimelineAnimation(
            session,
            actor
        )
        if not released then return false, releaseReason end
        actor.timelineNodeFinished = true
        actor.lastReason = "npc_animation_finished:" .. nodeID
        if not hasPendingTimelineNode(nodes, elapsed, actor) then
            actor.state = "animation_finished"
            session.beatFinishedBy[actor.id] = true
        else
            actor.state = "animation_delay"
        end
    elseif elapsed < tonumber(session.phaseDeadline or 0) then
        local maintained, maintainReason = NPCAnimation.Maintain(
            session,
            actor,
            nodeBeat,
            session.phaseDeadline,
            track
        )
        if maintained ~= true then
            return false, maintainReason
                or "npc_animation_maintain_failed"
        end
    end
    return true
end

local function pumpNPCAnimationTimeline(session, actor, beat, timestamp)
    local nodes = timelineFor(beat, actor.id, actor.kind)
    local elapsed = timestamp - (tonumber(actor.timelineStartedAt) or timestamp)
    local node, nodeIndex = pendingTimelineNode(nodes, elapsed, actor)
    local previousState = actor.state
    if node and node.type == "animation" then
        local nodeID = tostring(node.id or ("node_" .. tostring(nodeIndex)))
        local track = node.track or node
        local durationMs = tonumber(node.durationMs)
            or tonumber(beat.durationMs) or 900
        local nodeBeat = { durationMs = durationMs }
        if tostring(actor.timelineNodeID or "") ~= nodeID
            or actor.timelineNodeType ~= "animation"
        then
            local released, releaseReason = releaseTimelineAnimation(
                session,
                actor
            )
            if not released then return false, releaseReason end
            local accepted, startReason = NPCAnimation.Start(
                session,
                actor,
                nodeBeat,
                track
            )
            if not accepted then
                return false, startReason or "npc_animation_start_failed"
            end
            actor.timelineNodeID = nodeID
            actor.timelineNodeType = "animation"
            actor.timelineNodeFinished = false
            actor.animationOwned = true
            actor.animationStartedAt = timestamp
            actor.state = "animating"
            actor.lastReason = "npc_animation_started:" .. nodeID
            local observed, observeReason = observeTimelineAnimation(
                session,
                actor,
                nodeBeat,
                track,
                nodes,
                elapsed,
                nodeID
            )
            if not observed then return false, observeReason end
        elseif actor.animationOwned then
            local observed, observeReason = observeTimelineAnimation(
                session,
                actor,
                nodeBeat,
                track,
                nodes,
                elapsed,
                nodeID
            )
            if not observed then return false, observeReason end
        end
    elseif node then
        local released, releaseReason = releaseTimelineAnimation(
            session,
            actor
        )
        if not released then return false, releaseReason end
        actor.timelineNodeID = tostring(
            node.id or ("node_" .. tostring(nodeIndex))
        )
        actor.timelineNodeType = node.type or "delay"
        actor.timelineNodeFinished = false
        actor.state = node.type == "delay"
            and "animation_delay" or "animation_queued"
        actor.lastReason = "timeline_" .. tostring(node.type or "wait")
    elseif not hasPendingTimelineNode(nodes, elapsed, actor) then
        local released, releaseReason = releaseTimelineAnimation(
            session,
            actor
        )
        if not released then return false, releaseReason end
        actor.timelineNodeFinished = true
        actor.state = "animation_finished"
        actor.lastReason = "timeline_finished"
        session.beatFinishedBy[actor.id] = true
    else
        local released, releaseReason = releaseTimelineAnimation(
            session,
            actor
        )
        if not released then return false, releaseReason end
        actor.state = "animation_delay"
        actor.lastReason = "timeline_waiting"
    end
    actor.timelineElapsedMs = math.max(0, math.floor(elapsed))
    return true, nil, previousState ~= actor.state
end

Internal.timelineStartOffset = timelineStartOffset
Internal.pumpNPCAnimationTimeline = pumpNPCAnimationTimeline

return Authority
