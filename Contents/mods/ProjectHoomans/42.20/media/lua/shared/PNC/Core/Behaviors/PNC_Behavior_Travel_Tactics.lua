-- Proactive, throttled live-travel threat evaluation (Fight / Flank / Flee).
-- Strictly ephemeral runtime state: never persisted to ModData so reloads
-- always re-evaluate live surroundings cleanly with zero stuck detours.

PNC = PNC or {}
PNC.BehaviorTravelTactics = PNC.BehaviorTravelTactics or {}

local Tactics = PNC.BehaviorTravelTactics
local Hazards = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldHazards"

Tactics.SCAN_INTERVAL_MS = 750
Tactics.SCAN_RADIUS = 14
Tactics.PROACTIVE_ENGAGE_DIST = 5.5
Tactics.FLANK_DISTANCE = 14
Tactics.FLEE_DISTANCE = 18
Tactics.OVERWHELMING_COUNT = 10
Tactics.MEDIUM_COUNT = 4

local function bodyPosition(record, zombie)
    local x = zombie and zombie.getX and tonumber(zombie:getX()) or tonumber(record and record.x) or 0
    local y = zombie and zombie.getY and tonumber(zombie:getY()) or tonumber(record and record.y) or 0
    local z = zombie and zombie.getZ and tonumber(zombie:getZ()) or tonumber(record and record.z) or 0
    return x, y, z
end

local function healthRatio(record)
    local h = type(record and record.health) == "table" and record.health or nil
    local maxHp = math.max(1, tonumber(h and h.max) or 100)
    local curHp = tonumber(h and h.current)
    if curHp == nil then curHp = maxHp end
    return math.max(0, math.min(1, curHp / maxHp))
end

local function actorPowerScore(record)
    local profile = PNC.AbstractCombatProfile
    if profile and type(profile.ScoreActor) == "function" then
        local s = profile.ScoreActor(record, { applyPersonalAmmo = true })
        if type(s) == "table" then
            return (tonumber(s.melee) or 0) * 3.0
                + (tonumber(s.ranged) or 0) * 4.5
                + (tonumber(s.defense) or 0) * 2.0
        end
    end
    return 2.0
end

local function isActualZombie(obj, selfBody)
    if not obj or obj == selfBody then return false end
    if type(obj.isDead) == "function" and obj:isDead() == true then return false end
    -- Skip Hoomans-owned NPC bodies.
    if PNC.Registry and type(PNC.Registry.FindRecordByZombie) == "function" then
        if PNC.Registry.FindRecordByZombie(obj) ~= nil then return false end
    end
    return true
end

local function scanNearbyThreats(record, zombie, target, radius)
    local bx, by, bz = bodyPosition(record, zombie)
    local tx = tonumber(target and target.x) or bx
    local ty = tonumber(target and target.y) or by
    local hdx, hdy = tx - bx, ty - by
    local hLen = math.sqrt(hdx * hdx + hdy * hdy)
    if hLen > 0.001 then
        hdx, hdy = hdx / hLen, hdy / hLen
    else
        hdx, hdy = 1, 0
    end

    local candidates = nil
    if PNC.SpatialIndex and type(PNC.SpatialIndex.QueryZombies) == "function" then
        candidates = PNC.SpatialIndex.QueryZombies(bx, by, radius)
    end

    local count = 0
    local sumX, sumY = 0, 0
    local nearestBody, nearestDistSq = nil, math.huge
    local radiusSq = radius * radius

    if type(candidates) == "table" then
        local limit = math.min(#candidates, 32)
        for i = 1, limit do
            local obj = candidates[i]
            if isActualZombie(obj, zombie) and type(obj.getX) == "function" and type(obj.getY) == "function" then
                local oz = type(obj.getZ) == "function" and tonumber(obj:getZ()) or bz
                if math.abs(oz - bz) <= 0.5 then
                    local ox = tonumber(obj:getX()) or bx
                    local oy = tonumber(obj:getY()) or by
                    local dx, dy = ox - bx, oy - by
                    local dSq = dx * dx + dy * dy
                    if dSq <= radiusSq then
                        -- Count zombies in front hemisphere OR very close (< 6 tiles).
                        local dot = dx * hdx + dy * hdy
                        if dot >= -2.0 or dSq <= 36 then
                            count = count + 1
                            sumX = sumX + ox
                            sumY = sumY + oy
                            if dSq < nearestDistSq then
                                nearestDistSq = dSq
                                nearestBody = obj
                            end
                        end
                    end
                end
            end
        end
    end

    if count == 0 then
        return { count = 0 }
    end
    return {
        count = count,
        centroidX = sumX / count,
        centroidY = sumY / count,
        nearestBody = nearestBody,
        nearestDist = math.sqrt(nearestDistSq),
    }
end

function Tactics.Evaluate(record, zombie, target, now)
    if type(record) ~= "table" or not target then
        return { action = "proceed" }
    end
    now = tonumber(now) or (PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0)
    record.runtime = record.runtime or {}
    local cache = record.runtime.travelTactics
    if type(cache) == "table"
        and cache.lastScanAt ~= nil
        and (now - cache.lastScanAt) < Tactics.SCAN_INTERVAL_MS
        and type(cache.lastDecision) == "table"
    then
        return cache.lastDecision
    end

    local threats = scanNearbyThreats(record, zombie, target, Tactics.SCAN_RADIUS)
    local bx, by, bz = bodyPosition(record, zombie)
    local decision = { action = "proceed", threatCount = threats.count }

    if threats.count > 0 then
        local hp = healthRatio(record)
        local power = actorPowerScore(record)
        local overwhelming = threats.count >= Tactics.OVERWHELMING_COUNT
            or hp < 0.35
            or (threats.count >= 6 and threats.count > power * 2.2)

        if overwhelming then
            -- Break contact: sprint directly away from horde centroid.
            local ax = bx - threats.centroidX
            local ay = by - threats.centroidY
            local len = math.sqrt(ax * ax + ay * ay)
            if len < 0.001 then ax, ay, len = -1, 0, 1 end
            local fleeX = math.floor(bx + (ax / len) * Tactics.FLEE_DISTANCE + 0.5)
            local fleeY = math.floor(by + (ay / len) * Tactics.FLEE_DISTANCE + 0.5)
            record.runtime.fleeingFromThreat = true
            -- Apply a short-lived corridor penalty so replanned routes avoid this street.
            if Hazards and type(Hazards.AddTemporaryCorridorPenalty) == "function" then
                local wh = PNC.Travel and PNC.Travel.Service and PNC.Travel.Service.WorldHour
                    and PNC.Travel.Service.WorldHour() or 0
                Hazards.AddTemporaryCorridorPenalty(
                    "live_horde:" .. tostring(math.floor(threats.centroidX / 16))
                        .. ":" .. tostring(math.floor(threats.centroidY / 16)),
                    threats.centroidX,
                    threats.centroidY,
                    28,
                    5.0,
                    wh + 1.5
                )
            end
            decision = {
                action = "flee",
                threatCount = threats.count,
                moveX = fleeX,
                moveY = fleeY,
                moveZ = bz,
                mode = "run",
            }
        elseif threats.count >= Tactics.MEDIUM_COUNT or threats.count > power * 1.3 then
            -- Medium threat: lateral flank detour perpendicular away from horde centroid.
            local dx = (tonumber(target.x) or bx) - bx
            local dy = (tonumber(target.y) or by) - by
            local len = math.sqrt(dx * dx + dy * dy)
            if len < 0.001 then dx, dy, len = 1, 0, 1 end
            -- Pick the perpendicular side further from the horde centroid.
            local px1, py1 = -dy / len, dx / len
            local px2, py2 = dy / len, -dx / len
            local side1X, side1Y = bx + px1 * Tactics.FLANK_DISTANCE, by + py1 * Tactics.FLANK_DISTANCE
            local side2X, side2Y = bx + px2 * Tactics.FLANK_DISTANCE, by + py2 * Tactics.FLANK_DISTANCE
            local d1 = (side1X - threats.centroidX) ^ 2 + (side1Y - threats.centroidY) ^ 2
            local d2 = (side2X - threats.centroidX) ^ 2 + (side2Y - threats.centroidY) ^ 2
            local fx, fy = side1X, side1Y
            if d2 > d1 then fx, fy = side2X, side2Y end
            record.runtime.fleeingFromThreat = nil
            decision = {
                action = "flank",
                threatCount = threats.count,
                moveX = math.floor(fx + 0.5),
                moveY = math.floor(fy + 0.5),
                moveZ = bz,
                mode = (threats.nearestDist and threats.nearestDist < 7.0) and "run" or "walk",
            }
        elseif threats.nearestBody and threats.nearestDist and threats.nearestDist <= Tactics.PROACTIVE_ENGAGE_DIST then
            record.runtime.fleeingFromThreat = nil
            decision = {
                action = "engage",
                threatCount = threats.count,
                combatTarget = {
                    kind = "zombie",
                    target = threats.nearestBody,
                    body = threats.nearestBody,
                },
            }
        else
            record.runtime.fleeingFromThreat = nil
        end
    else
        record.runtime.fleeingFromThreat = nil
    end

    record.runtime.travelTactics = {
        lastScanAt = now,
        lastDecision = decision,
    }
    return decision
end

function Tactics.Clear(record)
    if type(record) == "table" and type(record.runtime) == "table" then
        record.runtime.travelTactics = nil
        record.runtime.fleeingFromThreat = nil
    end
end

return Tactics
