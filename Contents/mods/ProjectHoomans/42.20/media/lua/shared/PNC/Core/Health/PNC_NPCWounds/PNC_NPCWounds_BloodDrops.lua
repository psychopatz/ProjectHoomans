-- Lightweight, MP-friendly floor blood droplets for bleeding NPCs.
-- Uses PZ's native IsoChunk:addBloodSplat(x, y, z, type), which automatically
-- replicates via PacketType.AddBlood to nearby clients in MP and respects each
-- player's local Core:getOptionBloodDecals() setting (0 = None, 1..10 = 10%..100%).

PNC = PNC or {}
PNC.NPCWounds = PNC.NPCWounds or {}

local Wounds = PNC.NPCWounds
local Core = PNC.Core

local MIN_DROP_INTERVAL_MS = 2200
local MAX_DROP_INTERVAL_MS = 8000
local HEAVY_BLEED_RATE = 0.08
local MAX_BLOOD_DECALS_OPT = 10

local function randInt(bound)
    bound = math.floor(tonumber(bound) or 1)
    if bound <= 1 then return 0 end
    if type(ZombRand) == "function" then
        return ZombRand(bound)
    end
    return math.random(0, bound - 1)
end

local function isDedicatedServer()
    return type(isServer) == "function" and isServer() == true
end

local function resolveLocalBloodDecalsOption()
    if isDedicatedServer() then
        -- Dedicated MP servers relay native AddBlood packets to relative
        -- clients; each client's IsoChunkMap.renderBloodForChunks filters
        -- rendering using that client's own getOptionBloodDecals() setting.
        return MAX_BLOOD_DECALS_OPT
    end
    local gameCore = type(getCore) == "function" and getCore() or nil
    if gameCore and type(gameCore.getOptionBloodDecals) == "function" then
        local opt = tonumber(gameCore:getOptionBloodDecals())
        if opt ~= nil then
            return math.max(0, math.min(MAX_BLOOD_DECALS_OPT, math.floor(opt)))
        end
    end
    return MAX_BLOOD_DECALS_OPT
end

local function computeDropIntervalMs(bleedingRate, healthState, bloodOpt)
    local rate = math.max(0.005, tonumber(bleedingRate) or 0.01)
    -- Higher bleedingRate -> shorter interval (bounded to stay lightweight).
    local baseMs = math.floor(240 / rate)
    if baseMs < MIN_DROP_INTERVAL_MS then baseMs = MIN_DROP_INTERVAL_MS end
    if baseMs > MAX_DROP_INTERVAL_MS then baseMs = MAX_DROP_INTERVAL_MS end
    if healthState == "incapacitated" then
        baseMs = math.floor(baseMs * 1.5)
    end
    if bloodOpt > 0 and bloodOpt < MAX_BLOOD_DECALS_OPT then
        baseMs = math.floor(baseMs * (MAX_BLOOD_DECALS_OPT / bloodOpt))
    end
    return baseMs
end

function Wounds.TryDropBleedingBlood(record, body, woundBody, health, now)
    if type(record) ~= "table" or record.alive == false then return false end
    if type(woundBody) ~= "table" then return false end
    local rate = tonumber(woundBody.bleedingRate) or 0
    if rate <= 0 then return false end
    if not body or type(body.getCurrentSquare) ~= "function" then return false end

    local bloodOpt = resolveLocalBloodDecalsOption()
    if bloodOpt <= 0 then return false end

    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    record.runtime = record.runtime or {}
    local nextAt = tonumber(record.runtime.nextBloodDropAt) or 0
    if now < nextAt then return false end

    local sq = body:getCurrentSquare()
    if not sq then return false end
    if type(sq.isSolidFloor) == "function" and sq:isSolidFloor() ~= true then
        return false
    end
    local chunk = type(sq.getChunk) == "function" and sq:getChunk() or nil
    if not chunk or type(chunk.addBloodSplat) ~= "function" then
        return false
    end

    local x = type(body.getX) == "function" and tonumber(body:getX()) or tonumber(record.x)
    local y = type(body.getY) == "function" and tonumber(body:getY()) or tonumber(record.y)
    local z = type(body.getZ) == "function" and tonumber(body:getZ()) or tonumber(record.z) or 0
    if x == nil or y == nil then return false end

    -- Subtle jitter inside the current tile so stationary bleeding NPCs form a
    -- natural pool instead of stacking decals on one exact coordinate.
    local ox = (randInt(45) - 22) * 0.01
    local oy = (randInt(45) - 22) * 0.01
    local sx = tonumber(sq.getX and sq:getX()) or math.floor(x)
    local sy = tonumber(sq.getY and sq:getY()) or math.floor(y)
    local px = math.max(sx + 0.05, math.min(sx + 0.95, x + ox))
    local py = math.max(sy + 0.05, math.min(sy + 0.95, y + oy))

    -- Prefer types 0..7 so IsoChunk assigns b.index (1..10), allowing PZ's
    -- IsoChunkMap.renderBloodForChunks to scale droplets per-client via
    -- Core:getOptionBloodDecals(). Heavy bleeding occasionally drops a larger splat.
    local splatType = (rate >= HEAVY_BLEED_RATE and randInt(5) == 0)
        and (8 + randInt(12))
        or randInt(8)

    chunk:addBloodSplat(px, py, z, splatType)

    local healthState = type(health) == "table" and tostring(health.state or "normal") or "normal"
    local intervalMs = computeDropIntervalMs(rate, healthState, bloodOpt)
    local jitterMs = randInt(math.max(250, math.floor(intervalMs * 0.25)))
    record.runtime.nextBloodDropAt = now + intervalMs + jitterMs
    return true
end

return Wounds
