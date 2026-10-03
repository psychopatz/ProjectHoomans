--[[
    Social facing for the downed (incapacitated) state.

    This module owns the *distress* speech a downed NPC emits toward the
    survivors who can actually hear it.  It is the counterpart to the existing
    witness-driven modules: the *trigger* is the NPC's own health transition
    (it just went down, or its wound picture changed while down), but delivery
    is per nearby player because a flavor line has to reach a client.

    Every line is attributed, per listener, through PNC.FlavorText, so the
    downed NPC addresses whoever is there in the correct register:

        own follower / faction member -> "I need patching"    (ally)
        warm friend or self            -> a request, not an order
        a different, peaceful faction  -> "I'm fainting, help me" (stranger)
        a personal or faction enemy    -> mercy from a survivor,
                                          or a faint in front of the dead
        a zombie                       -> dying noise, never a plea to a human

    Performance: this runs once per incapacitation *edge* per NPC, not per
    tick.  The per-listener loop is bounded by the online/active player list
    and short-circuits on range, line of sight, and a per-listener cooldown
    that is reserved before the network send so a hostile crowd cannot make a
    single downed NPC spam the queue.
]]

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local Core = PNC.Core
local Const = PNC.Const
local Network = PNC.Network
-- The flavor vocabulary is owned by the shared composition, which may not
-- have run when this module is required.  Resolve it at call time so load
-- order can never break the server tree.
local function flavorText()
    return PNC.FlavorText
end

-- Never return nil: callers read fields straight off the result, and a nil
-- table would turn a graceful degradation into an index error.
local EMPTY_CONSTANTS = {}
local function flavorConst()
    return PNC.FlavorTextConst or EMPTY_CONSTANTS
end

-- Flavor ids carry their own literals so the module is usable (and testable)
-- even if the constants table is absent.
local function callFlavorID()
    return flavorConst().FLAVOR_CALL or "social.incapacitated_call"
end

local function updateFlavorID()
    return flavorConst().FLAVOR_UPDATE or "social.incapacitated_update"
end

local function repeatFlavorID()
    return flavorConst().FLAVOR_REPEAT or "social.incapacitated_repeat"
end

local HEAR_RADIUS = tonumber(Const and Const.ZOMBIE_TARGET_RADIUS) or 12
local CALL_COOLDOWN_MS = 20000
local UPDATE_COOLDOWN_MS = 25000
-- While an NPC stays down it keeps asking for help, but on a slow cadence so
-- the plea reads as persistence rather than spam.  The refresh is driven by
-- the existing incapacitated behavior tick, so there is no new timer.
local REPEAT_INTERVAL_MS = 45000
local MAX_TRACKED_NPCS = 256

-- Per-NPC debounce so a flapping health state cannot re-trigger the line.
local lastCallByNPC = {}
local lastCallOrder = {}

local function now()
    return (Core and Core.Now and Core.Now()) or 0
end

local function clean(value, fallback)
    if value == nil then return fallback end
    return tostring(value) ~= "" and tostring(value) or fallback
end

local function clampHistory()
    while #lastCallOrder > MAX_TRACKED_NPCS do
        local oldest = table.remove(lastCallOrder, 1)
        if oldest then lastCallByNPC[oldest] = nil end
    end
end

local function markCalled(npcID, at)
    if not lastCallByNPC[npcID] then
        lastCallOrder[#lastCallOrder + 1] = npcID
    end
    lastCallByNPC[npcID] = at
    clampHistory()
end

local function distanceSq(x1, y1, x2, y2)
    if Core and Core.DistanceSq then
        return Core.DistanceSq(x1, y1, x2, y2)
    end
    local dx = x2 - x1
    local dy = y2 - y1
    return (dx * dx) + (dy * dy)
end

local function coordinate(object, method, fallback)
    if not object or type(object[method]) ~= "function" then
        return fallback
    end
    local ok, value = pcall(object[method], object)
    if ok and value ~= nil then return tonumber(value) end
    return fallback
end

local function playerCanHear(player, record, radiusSq)
    local px = coordinate(player, "getX")
    local py = coordinate(player, "getY")
    local pz = coordinate(player, "getZ")
    local nx = tonumber(record and record.x)
    local ny = tonumber(record and record.y)
    local nz = tonumber(record and record.z)
    if not px or not py or not pz or not nx or not ny or not nz then
        return false
    end
    if math.abs(pz - nz) >= 1
        or distanceSq(px, py, nx, ny) > radiusSq
    then
        return false
    end
    local perception = PNC.Perception
    if perception and type(perception.CanSeeWorldObject) == "function" then
        return perception.CanSeeWorldObject(record, player) == true
    end
    -- Without a perception service, proximity is the honest answer.
    return true
end

H.FlavorText = flavorText
H.FlavorConst = flavorConst
H.CallFlavorID = callFlavorID
H.UpdateFlavorID = updateFlavorID
H.RepeatFlavorID = repeatFlavorID
H.Now = now
H.Clean = clean
H.MarkCalled = markCalled
H.DistanceSq = distanceSq
H.Coordinate = coordinate
H.PlayerCanHear = playerCanHear
H.LastCallByNPC = lastCallByNPC
H.LastCallOrder = lastCallOrder
H.HEAR_RADIUS = HEAR_RADIUS
H.CALL_COOLDOWN_MS = CALL_COOLDOWN_MS
H.UPDATE_COOLDOWN_MS = UPDATE_COOLDOWN_MS
H.REPEAT_INTERVAL_MS = REPEAT_INTERVAL_MS
H.ResetIncapacitatedFlavorState = function()
    for key in pairs(lastCallByNPC) do lastCallByNPC[key] = nil end
    while #lastCallOrder > 0 do table.remove(lastCallOrder) end
    return true
end

return Hooks
