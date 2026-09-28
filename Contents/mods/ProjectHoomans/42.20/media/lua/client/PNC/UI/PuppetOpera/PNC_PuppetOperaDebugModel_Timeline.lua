-- Timeline projection and editor mutations for Puppet Opera beats.
--
-- The runtime still accepts the legacy one-track-per-actor shape.  This
-- spoke presents that shape as a stable animation clip and materializes a
-- timeline only when the editor changes its position or duration.  Keeping
-- the conversion here gives the UI a timeline contract without coupling it
-- to blueprint serialization or server ownership.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local State = Internal.State or Model.State
local copy = Internal.copy
local markChanged = Internal.markChanged
local beatAt = Internal.beatAt
local trackForBeat = Internal.trackForBeat

local function trackLabel(track)
    if type(track) ~= "table" then return "Animation" end
    if track.mode == "emote" and track.emote then
        return tostring(track.emote)
    end
    return tostring(track.action or track.bump or track.anim or "Animation")
end

local function virtualNode(track, actorID, durationMs)
    local payload = copy(track or {})
    payload.timeline = nil
    return {
        id = "legacy_" .. tostring(actorID),
        type = "animation",
        startMs = 0,
        durationMs = tonumber(durationMs) or 900,
        label = trackLabel(payload),
        track = payload,
        virtual = true,
    }
end

local function nodesForTrack(track, actorID, durationMs)
    if type(track) == "table" and type(track.timeline) == "table"
        and #track.timeline > 0
    then
        return track.timeline
    end
    if type(track) ~= "table" then return {} end
    return { virtualNode(track, actorID, durationMs) }
end

local function selectedBeat()
    return beatAt(State and State.selectedBeatIndex or 1)
end

local function timelineTrack(actorID)
    local beat = selectedBeat()
    local kind = Model.GetActorKind(actorID)
    return beat and trackForBeat(beat, actorID, kind) or nil, beat
end

local function materialize(track, actorID, durationMs)
    if type(track) ~= "table" then return nil end
    if type(track.timeline) == "table" and #track.timeline > 0 then
        return track.timeline
    end
    local node = virtualNode(track, actorID, durationMs)
    track.timeline = { node }
    return track.timeline
end

local function findNode(nodes, nodeID)
    for index, node in ipairs(nodes or {}) do
        if tostring(node.id) == tostring(nodeID) then
            return node, index
        end
    end
    return nil
end

function Model.GetTimelineRows(snapshot)
    local beat = selectedBeat()
    if not beat then return {} end
    local rows = {}
    local actorRows = Model.GetActorRows(snapshot)
    for _, actor in ipairs(actorRows or {}) do
        local track = trackForBeat(
            beat,
            actor.id,
            Model.GetActorKind(actor.id)
        )
        local runtime = snapshot and snapshot.actors
            and snapshot.actors[actor.id] or nil
        local nodes = nodesForTrack(track, actor.id, beat.durationMs)
        local projected = {}
        for _, node in ipairs(nodes) do
            local item = {
                id = node.id,
                type = node.type or "animation",
                startMs = tonumber(node.startMs or node.offsetMs) or 0,
                durationMs = tonumber(node.durationMs)
                    or tonumber(beat.durationMs) or 900,
                label = node.label,
                virtual = node.virtual == true,
                active = false,
            }
            local nodeTrack = node.track or node
            if not item.label then
                item.label = item.type == "delay"
                    and "Delay" or trackLabel(nodeTrack)
            end
            if runtime then
                item.active = runtime.timelineNodeID ~= nil
                    and tostring(runtime.timelineNodeID)
                        == tostring(item.id)
                    or runtime.timelineNodeID == nil
                    and runtime.state == "animating"
                    and item.type == "animation"
            end
            projected[#projected + 1] = item
        end
        rows[#rows + 1] = {
            id = actor.id,
            label = actor.label,
            flow = actor.flow or "Idle / bound",
            state = actor.state,
            controlled = actor.controlled == true,
            owned = actor.owned == true,
            nodes = projected,
        }
    end
    return rows
end

function Model.GetTimelineDuration()
    local beat = selectedBeat()
    return beat and tonumber(beat.durationMs) or 900
end

function Model.SetTimelineNodeOffset(actorID, nodeID, startMs)
    local track, beat = timelineTrack(actorID)
    if not track or not beat then return false, "timeline_track_missing" end
    local nodes = materialize(track, actorID, beat.durationMs)
    local node = findNode(nodes, nodeID)
    if not node then return false, "timeline_node_not_found" end
    local duration = math.max(0, tonumber(node.durationMs) or 0)
    local maximum = math.max(0, tonumber(beat.durationMs) - duration)
    startMs = tonumber(startMs)
    if not startMs or startMs ~= math.floor(startMs) then
        return false, "timeline_offset_invalid"
    end
    node.startMs = math.max(0, math.min(maximum, math.floor(startMs)))
    markChanged()
    return true
end

function Model.SetTimelineNodeDuration(actorID, nodeID, durationMs)
    local track, beat = timelineTrack(actorID)
    if not track or not beat then return false, "timeline_track_missing" end
    local nodes = materialize(track, actorID, beat.durationMs)
    local node = findNode(nodes, nodeID)
    if not node then return false, "timeline_node_not_found" end
    durationMs = tonumber(durationMs)
    if not durationMs or durationMs ~= math.floor(durationMs)
        or durationMs < 0
    then
        return false, "timeline_duration_invalid"
    end
    node.durationMs = math.min(durationMs, tonumber(beat.durationMs) or 900)
    node.startMs = math.min(
        tonumber(node.startMs) or 0,
        math.max(0, beat.durationMs - node.durationMs)
    )
    markChanged()
    return true
end

function Model.ReorderTimelineNode(actorID, nodeID, targetIndex)
    local track, beat = timelineTrack(actorID)
    if not track or not beat then return false, "timeline_track_missing" end
    local nodes = materialize(track, actorID, beat.durationMs)
    local node, sourceIndex = findNode(nodes, nodeID)
    targetIndex = tonumber(targetIndex)
    if not node or not targetIndex or targetIndex ~= math.floor(targetIndex)
        or targetIndex < 1 or targetIndex > #nodes
    then
        return false, "timeline_reorder_invalid"
    end
    if sourceIndex == targetIndex then return true end
    table.remove(nodes, sourceIndex)
    table.insert(nodes, targetIndex, node)
    markChanged()
    return true
end

function Model.AddTimelineDelay(actorID, durationMs)
    local track, beat = timelineTrack(actorID)
    if not track or not beat then return false, "timeline_track_missing" end
    local nodes = materialize(track, actorID, beat.durationMs)
    durationMs = tonumber(durationMs)
    if not durationMs or durationMs ~= math.floor(durationMs)
        or durationMs < 0
    then
        return false, "timeline_duration_invalid"
    end
    local endMs = 0
    for index, node in ipairs(nodes) do
        local nodeEnd = (tonumber(node.startMs) or 0)
            + (tonumber(node.durationMs) or 0)
        if nodeEnd > endMs then endMs = nodeEnd end
        if not node.id or node.id == "" then
            node.id = "node_" .. tostring(index)
        end
    end
    local id = "delay_" .. tostring(#nodes + 1)
    local used = true
    while used do
        used = false
        for _, node in ipairs(nodes) do
            if tostring(node.id) == id then
                used = true
                id = id .. "_2"
                break
            end
        end
    end
    if endMs + durationMs > beat.durationMs then
        return false, "timeline_exceeds_beat_duration"
    end
    nodes[#nodes + 1] = {
        id = id,
        type = "delay",
        startMs = endMs,
        durationMs = durationMs,
        label = "Delay",
    }
    markChanged()
    return true, id
end

Internal.nodesForTrack = nodesForTrack
Internal.trackLabel = trackLabel

return Model
