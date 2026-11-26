-- Lightweight multiplayer visual-presentation broadcaster for Puppet Opera.
--
-- Replicates `anim_vars` tracks and active tether couplings to nearby clients
-- without writing persistent ModData and without per-tick network traffic.
-- Clients compute `PNC_AnimMoving` and visual tether lockstep locally from
-- replicated body positions, so packets are sent only on:
--   1. Beat activation / change
--   2. A remote player entering observation range (checked every 1500 ms)
--   3. Observer leaving range or session close (`clear`)

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Choreography = PNC.Choreography or {}

local Opera = PNC.Choreography
local Authority = Opera.Authority or {}
Opera.Authority = Authority
local Internal = Authority.Internal or {}
Authority.Internal = Internal
local Const = PNC.Const or {}
local Core = PNC.Core

local VisualSync = Opera.AuthorityVisualSync or {}
Opera.AuthorityVisualSync = VisualSync

local ENTER_RADIUS_SQ = 45 * 45
local EXIT_RADIUS_SQ = 55 * 55
local OBSERVER_SCAN_INTERVAL_MS = 1500

local function nowMs()
    return Core and Core.Now and Core.Now() or 0
end

local function isDedicatedServer()
    return type(isServer) == "function" and isServer() == true
end

local function onlineIDOf(body)
    if not body or not body.getOnlineID then return nil end
    local oid = tonumber(body:getOnlineID())
    if oid == nil or oid < 0 then return nil end
    return oid
end

local function playerKeyOf(player)
    if not player then return nil end
    if player.getUsername then
        local name = tostring(player:getUsername() or "")
        if name ~= "" then return name end
    end
    local oid = onlineIDOf(player)
    if oid ~= nil then return "oid:" .. tostring(oid) end
    return nil
end

local function sessionPosition(session)
    for _, actor in pairs(session and session.actors or {}) do
        local body = actor and actor.body or nil
        if body and body.getX and body.getY then
            return tonumber(body:getX()) or 0, tonumber(body:getY()) or 0
        end
    end
    local origin = session and session.origin or nil
    if origin and origin.x and origin.y then
        return tonumber(origin.x) or 0, tonumber(origin.y) or 0
    end
    return nil, nil
end

local function resolveActorTrack(beat, actor)
    if type(beat) ~= "table" or type(actor) ~= "table" then return nil end
    local actorTracks = beat.actorTracks
    local track = actorTracks and actorTracks[actor.id] or nil
    if not track then
        if actor.kind == "local_player" then
            track = beat.player
        else
            track = beat.npc
        end
    end
    if type(track) ~= "table" or track.route ~= "anim_vars" then
        return nil
    end
    return track
end

local function buildPayload(session, beat)
    if type(session) ~= "table" or type(beat) ~= "table" then return nil end
    local bpActors = session.blueprint and session.blueprint.actors or {}
    local actors = {}
    local count = 0
    local tetherActive = beat.tetherActive == true or beat.mode == "locomotive"
    for actorID, actor in pairs(session.actors or {}) do
        local track = resolveActorTrack(beat, actor)
        local oid = onlineIDOf(actor.body)
        if track and oid ~= nil then
            local def = bpActors[actorID]
            local coupling = tetherActive and def and def.coupling or nil
            local entry = {
                id = tostring(actorID),
                k = actor.kind == "local_player" and "p" or "z",
                oid = oid,
                st = tostring(track.style or track.anim or "custom"),
                r = tostring(track.role or "Actor"),
                ph = tostring(track.phase or beat.id or "play"),
            }
            if coupling and coupling.attachTo then
                entry.l = tostring(coupling.attachTo)
                if tonumber(coupling.offsetRight) and coupling.offsetRight ~= 0 then
                    entry.ox = coupling.offsetRight
                end
                if tonumber(coupling.offsetForward) and coupling.offsetForward ~= 0 then
                    entry.oy = coupling.offsetForward
                end
                if tonumber(coupling.offsetZ) and coupling.offsetZ ~= 0 then
                    entry.oz = coupling.offsetZ
                end
                if coupling.facingMode and coupling.facingMode ~= "match" then
                    entry.fm = tostring(coupling.facingMode)
                end
            end
            count = count + 1
            actors[count] = entry
        end
    end
    if count == 0 then return nil end
    return {
        op = "set",
        s = tostring(session.sessionId or ""),
        b = tonumber(session.beatIndex) or 1,
        t = tetherActive or nil,
        c = beat.disableCollision == true or nil,
        a = actors,
    }
end

local function sendVisual(player, payload)
    if not player or not payload or type(sendServerCommand) ~= "function" then
        return false
    end
    local cmd = Const.CMD_CHOREOGRAPHY_VISUAL or "ChoreographyVisual"
    sendServerCommand(player, Const.MODULE, cmd, payload)
    return true
end

local function iterOnlinePlayers()
    local list = {}
    if type(getOnlinePlayers) ~= "function" then return list end
    local online = getOnlinePlayers()
    if not online or not online.size or not online.get then return list end
    local total = tonumber(online:size()) or 0
    for i = 0, total - 1 do
        local player = online:get(i)
        if player then
            list[#list + 1] = player
        end
    end
    return list
end

function VisualSync.SyncBeat(session, beat, force)
    if not isDedicatedServer() then return 0 end
    if type(session) ~= "table" or type(beat) ~= "table" then return 0 end
    local payload = buildPayload(session, beat)
    if not payload then return 0 end

    local sx, sy = sessionPosition(session)
    if not sx or not sy then return 0 end

    local now = nowMs()
    local state = session._visualSync
    if not state then
        state = {
            beatKey = "",
            recipients = {},
            lastScanAt = 0,
        }
        session._visualSync = state
    end

    local beatKey = tostring(session.beatIndex or 0) .. ":"
        .. tostring(beat.id or "") .. ":"
        .. tostring(session.revision or 0)
    local beatChanged = state.beatKey ~= beatKey
    if not force and not beatChanged
        and now - (tonumber(state.lastScanAt) or 0) < OBSERVER_SCAN_INTERVAL_MS
    then
        return 0
    end
    state.beatKey = beatKey
    state.lastScanAt = now

    local players = iterOnlinePlayers()
    local seen = {}
    local sent = 0
    local clearPayload = nil

    for i = 1, #players do
        local player = players[i]
        local key = playerKeyOf(player)
        if key and player.getX and player.getY then
            seen[key] = true
            local dx = (tonumber(player:getX()) or 0) - sx
            local dy = (tonumber(player:getY()) or 0) - sy
            local distSq = dx * dx + dy * dy
            local prevKey = state.recipients[key]
            if distSq <= ENTER_RADIUS_SQ then
                if force or prevKey ~= beatKey then
                    if sendVisual(player, payload) then
                        state.recipients[key] = beatKey
                        sent = sent + 1
                    end
                end
            elseif prevKey ~= nil and distSq >= EXIT_RADIUS_SQ then
                clearPayload = clearPayload or {
                    op = "clear",
                    s = tostring(session.sessionId or ""),
                }
                sendVisual(player, clearPayload)
                state.recipients[key] = nil
                sent = sent + 1
            end
        end
    end

    for key, _ in pairs(state.recipients) do
        if not seen[key] then
            state.recipients[key] = nil
        end
    end
    return sent
end

function VisualSync.ClearSession(session)
    if not isDedicatedServer() then return 0 end
    local state = type(session) == "table" and session._visualSync or nil
    if not state or type(state.recipients) ~= "table" then return 0 end

    local clearPayload = {
        op = "clear",
        s = tostring(session.sessionId or ""),
    }
    local players = iterOnlinePlayers()
    local sent = 0
    for i = 1, #players do
        local player = players[i]
        local key = playerKeyOf(player)
        if key and state.recipients[key] ~= nil then
            if sendVisual(player, clearPayload) then
                sent = sent + 1
            end
        end
    end
    session._visualSync = nil
    return sent
end

Internal.VisualSync = VisualSync

return VisualSync
