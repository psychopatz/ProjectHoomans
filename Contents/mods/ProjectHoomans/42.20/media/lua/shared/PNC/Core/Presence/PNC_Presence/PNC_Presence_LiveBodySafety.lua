-- Hard lifecycle fence for live managed IsoZombie carriers.
--
-- Project Zomboid can virtualize any IsoZombie that reaches an unloading
-- chunk or leaves loaded world space while using native path states. PNC must
-- therefore retire managed human shells while they are still attached instead
-- of relying on a husk reaper after native population serialization.

local Presence = PNC.Presence
local Internal = Presence.Internal
local Core = PNC.Core
local Const = PNC.Const

Internal.LastLiveBodySafetySweepAt =
    tonumber(Internal.LastLiveBodySafetySweepAt) or 0

local function outsideLocalChunkMap(record, nearest)
    local cell
    local player
    local playerNum
    local chunkMap
    local margin = tonumber(Const.LIVE_BODY_CHUNK_MARGIN) or 8
    local x = tonumber(record and record.x)
    local y = tonumber(record and record.y)

    -- Dedicated/listen servers own loaded cells through ServerMap rather than
    -- the local IsoChunkMap. MP uses the conservative distance fence.
    if isServer and isServer() then return false end

    player = nearest and nearest.player or nil
    if not player or x == nil or y == nil or not getCell then return false end

    cell = getCell()
    if not cell or not cell.getChunkMap then return false end
    playerNum = player.getPlayerNum and tonumber(player:getPlayerNum()) or 0

    local ok, value = pcall(cell.getChunkMap, cell, playerNum)
    if not ok then return false end
    chunkMap = value
    if not chunkMap
        or not chunkMap.getWorldXMinTiles
        or not chunkMap.getWorldXMaxTiles
        or not chunkMap.getWorldYMinTiles
        or not chunkMap.getWorldYMaxTiles
    then
        return false
    end

    local minX = tonumber(chunkMap:getWorldXMinTiles())
    local maxX = tonumber(chunkMap:getWorldXMaxTiles())
    local minY = tonumber(chunkMap:getWorldYMinTiles())
    local maxY = tonumber(chunkMap:getWorldYMaxTiles())
    if not minX or not maxX or not minY or not maxY then return false end

    return x < minX + margin
        or x >= maxX - margin
        or y < minY + margin
        or y >= maxY - margin
end

function Presence.IsOutsideLiveBodyEnvelope(record, nearest)
    local distance = tonumber(Const.LIVE_BODY_RETIRE_DISTANCE)
        or tonumber(Const.ABSTRACT_DISTANCE)
        or 40

    nearest = nearest or (
        Internal.FindNearestPlayer and Internal.FindNearestPlayer(record)
    )
    if not nearest or nearest.distSq == nil then return true end
    if nearest.distSq >= (distance * distance) then return true end

    -- SP/splitscreen can use smaller local chunk maps than the MP server's
    -- clamped loaded range. Stay one chunk inside the actual local boundary.
    return outsideLocalChunkMap(record, nearest)
end

-- Per-record fast path used before behavior/pathing. Returns the current body
-- handle after enforcement so callers cannot accidentally continue operating
-- on a shell that was just abstracted.
function Presence.EnforceLiveBodyEnvelope(record, zombie)
    local registry = PNC.Registry
    if not zombie
        or not record
        or record.presenceState ~= Const.PRESENCE_LIVE
        or not Presence.IsOutsideLiveBodyEnvelope(record)
    then
        return zombie
    end
    -- Fail closed for this tick even if engine removal is temporarily
    -- unverified and Presence.Abstract leaves the registry handle live for a
    -- bounded retry. Returning nil prevents behavior/pathing from issuing a
    -- fresh native movement request toward an unloading boundary.
    Presence.Abstract(record, "live_body_safety_envelope")
    return nil
end

-- Runs independently from per-NPC AI cadence. It walks only Registry.LiveByID,
-- which is already bounded by live-body admission, and never scans world
-- zombies. Collect first because Presence.Abstract mutates LiveByID.
function Presence.RetireUnsafeLiveBodies(now, force)
    local registry = PNC.Registry
    local pending = {}
    local count = 0
    local cadence = tonumber(Const.LIVE_BODY_SAFETY_SWEEP_MS) or 100

    now = tonumber(now) or Core.Now()
    if force ~= true
        and now - Internal.LastLiveBodySafetySweepAt < cadence
    then
        return 0
    end
    Internal.LastLiveBodySafetySweepAt = now
    if not registry or not registry.ForEachLive then return 0 end

    registry.ForEachLive(function(record, zombie)
        local nearest
        if not record or record.alive == false
            or record.presenceState ~= Const.PRESENCE_LIVE
        then
            return
        end

        if registry.RefreshLivePosition then
            registry.RefreshLivePosition(record, zombie, false)
        end
        nearest = Internal.FindNearestPlayer
            and Internal.FindNearestPlayer(record) or nil

        record.runtime = record.runtime or {}
        record.runtime.nearestPlayerDistSq =
            nearest and nearest.distSq or nil

        if Presence.IsOutsideLiveBodyEnvelope(record, nearest) then
            pending[#pending + 1] = record
        end
    end)

    for i = 1, #pending do
        local record = pending[i]
        if record.presenceState == Const.PRESENCE_LIVE
            and Presence.Abstract(record, "live_body_safety_envelope")
        then
            count = count + 1
        end
    end
    return count
end

return Presence
