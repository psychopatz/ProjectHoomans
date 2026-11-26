-- Structured, token-efficient console telemetry for Puppet Opera sessions.
--
-- Emits single-line `[PNC][OPERA]` records on session start/end, phase/beat
-- transitions, animation start, and a 1-shot 250ms post-start engine track
-- sample (actual ActionState, ActionContext, playing AnimTrack clips+weights,
-- PNC_Anim* AnimVars, and world coordinates). Designed for both live
-- debugging and future automated animation-authoring harnesses.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.Telemetry = PNC.PuppetOpera.Telemetry or {}

local Telemetry = PNC.PuppetOpera.Telemetry

Telemetry.Enabled = true

local function emit(tag, fields)
    if Telemetry.Enabled == false then return end
    local parts = { "[PNC][OPERA] " .. tostring(tag) }
    if type(fields) == "table" then
        local keys = {}
        for k in pairs(fields) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        for _, k in ipairs(keys) do
            local v = fields[k]
            if v ~= nil then
                parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
            end
        end
    end
    local line = table.concat(parts, " ")
    if PNC.Log and PNC.Log.Info then
        PNC.Log.Info("OPERA", line)
    elseif type(print) == "function" then
        print(line)
    end
end

function Telemetry.SampleAnimTracks(body)
    if not body or not body.dbgGetAnimTrackName then return "none" end
    local found = {}
    for i = 0, 7 do
        local name = body:dbgGetAnimTrackName(0, i)
        if not name or name == "" then break end
        local weight = body.dbgGetAnimTrackWeight
            and tonumber(body:dbgGetAnimTrackWeight(0, i)) or 0
        if weight > 0.01 then
            found[#found + 1] = string.format("%s@%.2f", tostring(name), weight)
        end
    end
    return #found > 0 and table.concat(found, ",") or "none"
end

function Telemetry.SampleBodyState(body)
    if not body then return {} end
    local state = body.getActionStateName
        and tostring(body:getActionStateName() or "") or ""
    local ctx = body.getCurrentActionContextStateName
        and tostring(body:getCurrentActionContextStateName() or "") or state
    local x = body.getX and tonumber(body:getX()) or 0
    local y = body.getY and tonumber(body:getY()) or 0
    local z = body.getZ and tonumber(body:getZ()) or 0
    local active = body.getVariableBoolean
        and body:getVariableBoolean("PNC_AnimActive") or false
    local style = body.getVariableString
        and tostring(body:getVariableString("PNC_AnimStyle") or "") or ""
    local role = body.getVariableString
        and tostring(body:getVariableString("PNC_AnimRole") or "") or ""
    local phase = body.getVariableString
        and tostring(body:getVariableString("PNC_AnimPhase") or "") or ""
    return {
        state = state ~= "" and state or "nil",
        ctx = ctx ~= "" and ctx or "nil",
        tracks = Telemetry.SampleAnimTracks(body),
        animActive = tostring(active),
        animStyle = style ~= "" and style or "-",
        animRole = role ~= "" and role or "-",
        animPhase = phase ~= "" and phase or "-",
        pos = string.format("%.2f,%.2f,%.2f", x, y, z),
    }
end

function Telemetry.LogActorSnapshot(session, tag, timestamp, force)
    if type(session) ~= "table" then return end
    local now = tonumber(timestamp)
        or (PNC.Core and PNC.Core.Now and PNC.Core.Now()) or 0
    local throttleKey = "_telemetryLast_" .. tostring(tag or "SNAP")
    if not force and session[throttleKey] and now - session[throttleKey] < 1000 then
        return
    end
    session[throttleKey] = now
    local Anchors = PNC.PuppetOpera and PNC.PuppetOpera.Anchors or nil
    for actorID, actor in pairs(session.actors or {}) do
        local body = actor.body
        local bx = body and body.getX and tonumber(body:getX()) or nil
        local by = body and body.getY and tonumber(body:getY()) or nil
        local bz = body and body.getZ and tonumber(body:getZ()) or 0
        local pt = Anchors and Anchors.WorldPoint and actor.target
            and Anchors.WorldPoint(actor.target) or nil
        local dist = -1
        if bx and by and pt then
            local dx = bx - pt.x
            local dy = by - pt.y
            dist = math.sqrt(dx * dx + dy * dy)
        end
        local actionState = body and body.getActionStateName
            and tostring(body:getActionStateName() or "-") or "-"
        local hasPath2 = body and body.getPath2 and (body:getPath2() ~= nil)
            or false
        emit(tag or "ACTOR_SNAP", {
            session = session.sessionId,
            phase = session.phase or "-",
            actor = actorID,
            kind = actor.kind or "-",
            arrived = tostring(actor.arrived == true),
            facing = tostring(actor.facing == true),
            state = actor.state or "-",
            actionState = actionState,
            hasPath2 = tostring(hasPath2),
            pos = bx and string.format("%.2f,%.2f,%.0f", bx, by, bz) or "nil",
            target = pt and string.format("%.2f,%.2f,%.0f", pt.x, pt.y, pt.z) or "nil",
            dist = dist >= 0 and string.format("%.2f", dist) or "-",
            reason = actor.lastReason or "-",
        })
    end
end

function Telemetry.LogPlan(session)
    if type(session) ~= "table" then return end
    local plan = session.plan or {}
    emit("PLAN", {
        session = session.sessionId,
        blueprint = session.blueprintId,
        allowOverlap = tostring(session.blueprint
            and session.blueprint.anchorFrame
            and session.blueprint.anchorFrame.allowOverlap == true),
        stopDist = tostring(plan.movementStopDistance or "-"),
        arrivalTol = tostring(plan.arrivalTolerance or plan.tolerance or "-"),
        origin = plan.origin and string.format("%s,%s,%s",
            tostring(plan.origin.x), tostring(plan.origin.y),
            tostring(plan.origin.z)) or "-",
    })
    Telemetry.LogActorSnapshot(session, "PLAN_ACTOR", nil, true)
end

function Telemetry.LogPhase(session, phase, reason)
    if type(session) ~= "table" then return end
    local beats = session.blueprint and session.blueprint.beats or {}
    local idx = tonumber(session.beatIndex) or 1
    local beat = beats[idx]
    emit("PHASE", {
        session = session.sessionId,
        blueprint = session.blueprintId,
        phase = phase,
        beat = tostring(idx) .. "/" .. tostring(#beats)
            .. (beat and ("(" .. tostring(beat.id) .. ":" .. tostring(beat.mode or "timed") .. ")") or ""),
        reason = reason or "-",
    })
    if phase == "moving" then
        Telemetry.LogPlan(session)
    elseif type(reason) == "string"
        and string.sub(reason, 1, 14) == "phase_timeout:"
    then
        Telemetry.LogActorSnapshot(session, "TIMEOUT_DUMP", nil, true)
    end
end

function Telemetry.LogAnimStart(session, actor, track)
    if type(session) ~= "table" or type(actor) ~= "table" then return end
    local sample = Telemetry.SampleBodyState(actor.body)
    emit("ANIM_START", {
        session = session.sessionId,
        actor = actor.id,
        binding = actor.bindingID or actor.npcID or "-",
        route = track and track.route or "-",
        clip = track and (track.bump or track.style or track.emote or track.action) or "-",
        role = track and track.role or "-",
        beatPhase = track and track.phase or "-",
        state = sample.state,
        ctx = sample.ctx,
        tracks = sample.tracks,
    })
end

function Telemetry.LogBeatSample(session, beat)
    if type(session) ~= "table" then return end
    for actorID, actor in pairs(session.actors or {}) do
        local sample = Telemetry.SampleBodyState(actor.body)
        emit("ANIM_SAMPLE", {
            session = session.sessionId,
            blueprint = session.blueprintId,
            beat = beat and beat.id or "-",
            actor = actorID,
            tethered = tostring(actor.tethered == true),
            state = sample.state,
            ctx = sample.ctx,
            tracks = sample.tracks,
            animActive = sample.animActive,
            animStyle = sample.animStyle,
            animRole = sample.animRole,
            animPhase = sample.animPhase,
            pos = sample.pos,
        })
    end
end

function Telemetry.LogSessionEnd(session, phase, reason)
    if type(session) ~= "table" then return end
    local nowMs = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    local elapsed = nowMs - (tonumber(session.createdAt) or nowMs)
    emit("SESSION_END", {
        session = session.sessionId,
        blueprint = session.blueprintId,
        phase = phase,
        reason = reason or "-",
        elapsedMs = math.max(0, math.floor(elapsed)),
    })
end

return Telemetry
