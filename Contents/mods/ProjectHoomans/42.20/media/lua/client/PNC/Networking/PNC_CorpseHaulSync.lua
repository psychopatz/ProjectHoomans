-- Client-side mirror for the server-authoritative corpse grapple.
--
-- NPCs are IsoZombies, not IsoPlayers. Do not put them through vanilla
-- timed-action classes; those classes call player-only APIs. The server owns
-- the grapple state and this module only mirrors it on the local replica.

PNC = PNC or {}
PNC.CorpseHaulSync = PNC.CorpseHaulSync or {}

local Sync = PNC.CorpseHaulSync
local states = setmetatable({}, { __mode = "k" })
local pending = setmetatable({}, { __mode = "k" })

local function resolveBody(npcId)
    local presence = PNC.ClientPresenceSync
    local body = presence and presence.BodyByID
        and presence.BodyByID[tostring(npcId)] or nil
    if body then return body end
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(npcId) or nil
end

local function isLocalController(body)
    local presence = PNC.ClientPresenceSync
    local internal = presence and presence.Internal
    if not internal or not internal.IsLocalZombieController then return true end
    return internal.IsLocalZombieController(body) == true
end

local function stateFor(body, args, kind)
    local state = states[body]
    local taskId = tostring(args and args.taskId or "")
    if not state or state.taskId ~= taskId then
        state = { taskId = taskId, npcId = tostring(args.npcId), kind = kind,
            status = "pending" }
        states[body] = state
    end
    return state
end

local function applyGrab(body, args)
    local target
    local state = stateFor(body, args, "grab")
    if body.isDraggingCorpse and body:isDraggingCorpse() then
        state.status = "dragging"
        pending[body] = nil
        return true
    end
    if not PNC.Network or not PNC.Network.FindZombieByOnlineID then
        pending[body] = args
        return false
    end
    target = PNC.Network.FindZombieByOnlineID(args.grappleTargetOnlineID)
    if not target or not target.Grappled then
        pending[body] = args
        return false
    end
    local ok = pcall(function()
        target:Grappled(body, nil, 1.0, "BwdDrag")
    end)
    if not ok or not body.isDraggingCorpse
        or not body:isDraggingCorpse()
    then
        pending[body] = args
        return false
    end
    state.status = "dragging"
    pending[body] = nil
    return true
end

local function applyDrop(body, args)
    local state = stateFor(body, args, "drop")
    if body.isDraggingCorpse and body:isDraggingCorpse()
        and body.setDoGrappleLetGo
    then
        local ok = pcall(function() body:setDoGrappleLetGo() end)
        if not ok then
            pending[body] = args
            return false
        end
    end
    if body.isDraggingCorpse and body:isDraggingCorpse() then
        pending[body] = args
        return false
    end
    state.status = "released"
    pending[body] = nil
    return true
end

function Sync.ReceiveCommand(args)
    args = type(args) == "table" and args or {}
    local action = tostring(args.action or "")
    local body = resolveBody(args.npcId)
    if not body or tostring(args.taskId or "") == "" then return false end
    if not isLocalController(body) then return false end
    if action == "sync_grab" then return applyGrab(body, args) end
    if action == "sync_drop" then return applyDrop(body, args) end
    return false
end

function Sync.GetState(body)
    return states[body]
end

local function pump()
    for body, args in pairs(pending) do
        Sync.ReceiveCommand(args)
    end
end

if PNC.Client and PNC.Client.Internal
    and PNC.Client.Internal.RegisterServerCommand
then
    PNC.Client.Internal.RegisterServerCommand(
        PNC.Const.CMD_CORPSE_HAUL_ACTION,
        function(args) return Sync.ReceiveCommand(args) end)
end

if Events and Events.OnTick and not Sync.TickHookRegistered then
    Events.OnTick.Add(pump)
    Sync.TickHookRegistered = true
end

return Sync
