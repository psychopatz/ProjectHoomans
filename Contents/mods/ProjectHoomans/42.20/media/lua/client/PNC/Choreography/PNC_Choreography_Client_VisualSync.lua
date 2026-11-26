-- Lightweight client-side MP visual presentation receiver for Puppet Opera.
--
-- Applies replicated `PNC_Anim*` variables and zero-jitter visual tether
-- lockstep for nearby multiplayer scenes (both Player-to-NPC and emergent
-- NPC-to-NPC). Uses zero persistent ModData and O(1) idle cost when no
-- replicated scenes are active.

PNC = PNC or {}
PNC.Choreography = PNC.Choreography or {}

local Opera = PNC.Choreography
local AnimVars = Opera.AnimVarAdapter
    or require "PNC/Core/Choreography/PNC_Choreography_AnimVarAdapter"
local Tether = Opera.Tether
    or require "PNC/Core/Choreography/PNC_Choreography_Tether"
local Const = PNC.Const or {}

local VisualSync = Opera.ClientVisualSync or {}
Opera.ClientVisualSync = VisualSync

VisualSync.Active = VisualSync.Active or {}
VisualSync.ActiveCount = tonumber(VisualSync.ActiveCount) or 0

local function localPlayerBody()
    if type(getPlayer) == "function" then
        return getPlayer()
    end
    return nil
end

local function isClientOnlyRuntime()
    if PNC.Core and PNC.Core.IsClientOnly then
        return PNC.Core.IsClientOnly() == true
    end
    return type(isClient) == "function" and isClient() == true
end

local function findPlayerByOnlineID(oid)
    oid = tonumber(oid)
    if oid == nil then return nil end
    local localP = localPlayerBody()
    if localP and localP.getOnlineID
        and tonumber(localP:getOnlineID()) == oid
    then
        return localP
    end
    if type(getOnlinePlayers) ~= "function" then return nil end
    local online = getOnlinePlayers()
    if not online or not online.size or not online.get then return nil end
    local total = tonumber(online:size()) or 0
    for i = 0, total - 1 do
        local player = online:get(i)
        if player and player.getOnlineID
            and tonumber(player:getOnlineID()) == oid
        then
            return player
        end
    end
    return nil
end

local function findZombieByOnlineID(oid)
    oid = tonumber(oid)
    if oid == nil then return nil end
    if PNC.Network and PNC.Network.FindZombieByOnlineID then
        return PNC.Network.FindZombieByOnlineID(oid)
    end
    if type(getCell) ~= "function" then return nil end
    local cell = getCell()
    if not cell or not cell.getZombieList then return nil end
    local list = cell:getZombieList()
    if not list or not list.size or not list.get then return nil end
    for i = list:size() - 1, 0, -1 do
        local z = list:get(i)
        if z and z.getOnlineID and tonumber(z:getOnlineID()) == oid then
            return z
        end
    end
    return nil
end

local function resolveBody(actorEntry)
    local cached = actorEntry._body
    if cached and cached.getOnlineID
        and tonumber(cached:getOnlineID()) == actorEntry.oid
        and (not cached.isDead or not cached:isDead())
    then
        return cached
    end
    local body
    if actorEntry.k == "p" then
        body = findPlayerByOnlineID(actorEntry.oid)
    else
        body = findZombieByOnlineID(actorEntry.oid)
    end
    actorEntry._body = body
    return body
end

local function isLocallyOwnedPlayer(body, sessionId)
    local localP = localPlayerBody()
    if not body or body ~= localP then return false end
    local playerAnim = Opera.PlayerAnimation
    if playerAnim and playerAnim.Active
        and tostring(playerAnim.Active.sessionId or "")
            == tostring(sessionId or "")
    then
        return true
    end
    return false
end

local function detectBodyMoving(body, refEntry)
    if not body then return false end
    local isPlayer = (refEntry and refEntry.k == "p")
        or (type(instanceof) == "function" and instanceof(body, "IsoPlayer"))
        or (body.isLocalPlayer ~= nil)
    if isPlayer then
        if body.getActionStateName then
            local st = tostring(body:getActionStateName() or "")
            if st == "movement" or st == "run" or st == "sprint"
                or st == "turningMovement180"
            then
                return true
            end
            if st == "strafe" then
                return body:isPlayerMoving() == true
            end
            if st ~= "" then
                return false
            end
        end
        return body:isPlayerMoving() == true
    end
    local moving = false
    if body.getActionStateName then
        local st = tostring(body:getActionStateName() or "")
        if st == "walktoward" or st == "walktoward-network" or st == "pathfind"
            or st == "movement" or st == "run" or st == "sprint"
        then
            moving = true
        end
    end
    if not moving and body.isMoving and body:isMoving() == true then
        moving = true
    end
    local bx = body.getX and tonumber(body:getX()) or nil
    local by = body.getY and tonumber(body:getY()) or nil
    if refEntry and bx and by then
        if refEntry._lastX and refEntry._lastY then
            local dx = bx - refEntry._lastX
            local dy = by - refEntry._lastY
            if (dx * dx + dy * dy) > 0.0001 then
                moving = true
            end
        end
        refEntry._lastX = bx
        refEntry._lastY = by
    end
    return moving
end

local function cleanupScene(scene)
    if type(scene) ~= "table" then return end
    for _, entry in pairs(scene.actors or {}) do
        local body = entry._body or resolveBody(entry)
        if body and not isLocallyOwnedPlayer(body, scene.sessionId) then
            if AnimVars and AnimVars.Clear then
                AnimVars.Clear(body)
            end
            if entry._collisionDisabled and body.setCollidable then
                body:setCollidable(true)
                entry._collisionDisabled = false
            end
        end
        entry._body = nil
        entry._applied = false
    end
end

local function recountActive()
    local count = 0
    for _, _ in pairs(VisualSync.Active) do
        count = count + 1
    end
    VisualSync.ActiveCount = count
end

function VisualSync.Receive(payload)
    if not isClientOnlyRuntime() then return false end
    if type(payload) ~= "table" then return false end
    local sessionId = tostring(payload.s or "")
    if sessionId == "" then return false end

    if payload.op == "clear" then
        local existing = VisualSync.Active[sessionId]
        if existing then
            cleanupScene(existing)
            VisualSync.Active[sessionId] = nil
            recountActive()
        end
        return true
    end

    if payload.op ~= "set" or type(payload.a) ~= "table" then
        return false
    end

    local prev = VisualSync.Active[sessionId]
    local prevActors = prev and prev.actors or {}
    local actors = {}
    for i = 1, #payload.a do
        local raw = payload.a[i]
        if type(raw) == "table" and raw.id and raw.oid ~= nil then
            local id = tostring(raw.id)
            local old = prevActors[id]
            local entry = {
                id = id,
                k = tostring(raw.k or "z"),
                oid = tonumber(raw.oid),
                st = tostring(raw.st or "custom"),
                r = tostring(raw.r or "Actor"),
                ph = tostring(raw.ph or "play"),
                l = raw.l and tostring(raw.l) or nil,
                coupling = raw.l and {
                    attachTo = tostring(raw.l),
                    offsetRight = tonumber(raw.ox) or 0,
                    offsetForward = tonumber(raw.oy) or 0,
                    offsetZ = tonumber(raw.oz) or 0,
                    facingMode = tostring(raw.fm or "match"),
                } or nil,
                _body = old and old.oid == tonumber(raw.oid) and old._body or nil,
                _lastX = old and old._lastX or nil,
                _lastY = old and old._lastY or nil,
                _applied = false,
                _collisionDisabled = old and old._collisionDisabled == true or false,
            }
            actors[id] = entry
        end
    end

    -- Clear any actor removed between beats
    for id, old in pairs(prevActors) do
        if not actors[id] and old._body
            and not isLocallyOwnedPlayer(old._body, sessionId)
        then
            if AnimVars and AnimVars.Clear then AnimVars.Clear(old._body) end
            if old._collisionDisabled and old._body.setCollidable then
                old._body:setCollidable(true)
            end
        end
    end

    VisualSync.Active[sessionId] = {
        sessionId = sessionId,
        beatIndex = tonumber(payload.b) or 1,
        tetherActive = payload.t == true,
        disableCollision = payload.c == true,
        actors = actors,
    }
    recountActive()
    return true
end

function VisualSync.Pump()
    if VisualSync.ActiveCount <= 0 then return 0 end
    if not isClientOnlyRuntime() then return 0 end
    local updated = 0
    for sessionId, scene in pairs(VisualSync.Active) do
        local actors = scene.actors or {}
        -- Pass 1: resolve bodies and sample each untethered leader's movement
        -- once per tick so tethered followers read the same moving boolean.
        for _, entry in pairs(actors) do
            local body = resolveBody(entry)
            if body and not entry.l then
                entry._moving = detectBodyMoving(body, entry)
            end
        end
        -- Pass 2: apply AnimVars and client-side visual tether lockstep.
        for _, entry in pairs(actors) do
            local body = entry._body
            if body and not isLocallyOwnedPlayer(body, sessionId) then
                local leaderEntry = entry.l and actors[entry.l] or nil
                local refBody = leaderEntry and leaderEntry._body or body
                local moving
                if leaderEntry then
                    moving = leaderEntry._moving == true
                else
                    moving = entry._moving == true
                end
                if not entry._applied then
                    AnimVars.Apply(body, {
                        style = entry.st,
                        role = entry.r,
                        phase = entry.ph,
                    }, {
                        phase = entry.ph,
                        moving = moving,
                        progress = 0,
                    })
                    entry._applied = true
                else
                    AnimVars.UpdateProgress(body, nil, moving)
                end
                if scene.disableCollision and body.setCollidable
                    and not entry._collisionDisabled
                then
                    body:setCollidable(false)
                    entry._collisionDisabled = true
                end
                if scene.tetherActive and entry.coupling and refBody
                    and refBody ~= body
                then
                    Tether.ApplyBody(body, refBody, entry.coupling)
                end
                updated = updated + 1
            end
        end
    end
    return updated
end

function VisualSync.Reset()
    for _, scene in pairs(VisualSync.Active) do
        cleanupScene(scene)
    end
    VisualSync.Active = {}
    VisualSync.ActiveCount = 0
end

if PNC.Client and PNC.Client.RegisterServerCommand then
    PNC.Client.RegisterServerCommand(
        Const.CMD_CHOREOGRAPHY_VISUAL or "ChoreographyVisual",
        VisualSync.Receive
    )
end
if Events and Events.OnTick then
    Events.OnTick.Add(VisualSync.Pump)
end
if Events and Events.OnResetLua then
    Events.OnResetLua.Add(VisualSync.Reset)
end

return VisualSync
