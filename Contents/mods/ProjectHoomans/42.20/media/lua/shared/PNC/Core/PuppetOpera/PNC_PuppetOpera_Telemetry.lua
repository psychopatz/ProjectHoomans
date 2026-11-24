-- Structured, token-efficient console telemetry for Puppet Opera sessions.
--
-- Emits single-line `[PNC][OPERA]` records on session start/end, phase/beat
-- transitions, animation start, and a 1-shot 250ms post-start engine track
-- sample (actual ActionState, ActionContext, playing AnimTrack clips+weights,
-- PNC_Opera* AnimVars, and world coordinates). Designed for both live
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
        and body:getVariableBoolean("PNC_OperaActive") or false
    local style = body.getVariableString
        and tostring(body:getVariableString("PNC_OperaStyle") or "") or ""
    local role = body.getVariableString
        and tostring(body:getVariableString("PNC_OperaRole") or "") or ""
    local phase = body.getVariableString
        and tostring(body:getVariableString("PNC_OperaPhase") or "") or ""
    return {
        state = state ~= "" and state or "nil",
        ctx = ctx ~= "" and ctx or "nil",
        tracks = Telemetry.SampleAnimTracks(body),
        operaActive = tostring(active),
        operaStyle = style ~= "" and style or "-",
        operaRole = role ~= "" and role or "-",
        operaPhase = phase ~= "" and phase or "-",
        pos = string.format("%.2f,%.2f,%.2f", x, y, z),
    }
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
            operaActive = sample.operaActive,
            operaStyle = sample.operaStyle,
            operaRole = sample.operaRole,
            operaPhase = sample.operaPhase,
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
