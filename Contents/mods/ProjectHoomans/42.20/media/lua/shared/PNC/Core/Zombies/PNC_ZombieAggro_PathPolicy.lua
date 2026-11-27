--[[
    PNC Zombie Aggro Path Policy
    Shared pursuit pathing guardrails for both SP authority and MP owning
    clients: A* token bucket, inflight cap, finder target deduplication,
    short velocity lead prediction, and exponential stall backoff.
]]

PNC = PNC or {}
PNC.ZombieAggro = PNC.ZombieAggro or {}
PNC.ZombieAggro.PathPolicy = PNC.ZombieAggro.PathPolicy or {}

local ZombieAggro = PNC.ZombieAggro
local Policy = ZombieAggro.PathPolicy
local Core = PNC.Core
local Const = PNC.Const or {}

Policy.State = Policy.State or {
    tokens = nil,
    lastTokenAt = nil,
    inflight = {},
    inflightCount = 0,
    lastSweepAt = 0,
}

local function nowMs(now)
    if type(now) == "number" then return now end
    return Core and Core.Now and Core.Now() or 0
end

local function numberConst(key, fallback)
    local value = tonumber(Const[key])
    if value ~= nil then return value end
    return fallback
end

function Policy.Reset()
    local state = Policy.State
    state.tokens = nil
    state.lastTokenAt = nil
    state.inflight = {}
    state.inflightCount = 0
    state.lastSweepAt = 0
end

function Policy.SweepInflight(now)
    local state = Policy.State
    local expireMs = numberConst("ZOMBIE_AGGRO_ASTAR_EXPIRE_MS", 8000)
    local count = 0
    now = nowMs(now)
    if now - (tonumber(state.lastSweepAt) or 0) < 1000
        and now >= (tonumber(state.lastSweepAt) or 0)
    then
        return state.inflightCount
    end
    state.lastSweepAt = now
    for zombie, issuedAt in pairs(state.inflight) do
        local expired = (now - issuedAt) >= expireMs or now < issuedAt
        local dead = zombie.isDead and zombie:isDead() == true or false
        if expired or dead then
            state.inflight[zombie] = nil
        else
            count = count + 1
        end
    end
    state.inflightCount = count
    return count
end

function Policy.NotePathIssued(zombie, now, enteredPathfind)
    local state = Policy.State
    if not zombie then return end
    now = nowMs(now)
    if enteredPathfind == true then
        if state.inflight[zombie] == nil then
            state.inflightCount = (tonumber(state.inflightCount) or 0) + 1
        end
        state.inflight[zombie] = now
    else
        Policy.SettlePath(zombie)
    end
end

function Policy.SettlePath(zombie)
    local state = Policy.State
    if zombie and state.inflight[zombie] ~= nil then
        state.inflight[zombie] = nil
        state.inflightCount = math.max(
            0, (tonumber(state.inflightCount) or 0) - 1
        )
    end
end

function Policy.ConsumeToken(now)
    local state = Policy.State
    local perSec = math.max(1, numberConst("ZOMBIE_AGGRO_ASTAR_PER_SEC", 16))
    local burst = math.max(1, numberConst("ZOMBIE_AGGRO_ASTAR_BURST", 8))
    now = nowMs(now)
    if state.lastTokenAt == nil or now < state.lastTokenAt then
        state.lastTokenAt = now
        state.tokens = burst
    elseif now > state.lastTokenAt then
        local refill = (now - state.lastTokenAt) * perSec / 1000
        state.tokens = math.min(burst, (state.tokens or 0) + refill)
        state.lastTokenAt = now
    end
    if (state.tokens or 0) < 1 then
        return false
    end
    state.tokens = state.tokens - 1
    return true
end

function Policy.CanAdmitAStar(zombie, now, targetChanged, closeSameFloor)
    local state = Policy.State
    local maxInflight = math.max(
        4, numberConst("ZOMBIE_AGGRO_ASTAR_INFLIGHT_MAX", 24)
    )
    now = nowMs(now)
    if closeSameFloor == true then
        return targetChanged == true or Policy.ConsumeToken(now)
    end
    Policy.SweepInflight(now)
    if state.inflight[zombie] == nil
        and (tonumber(state.inflightCount) or 0) >= maxInflight
    then
        return false, "inflight_capped"
    end
    if not Policy.ConsumeToken(now) then
        return false, "token_capped"
    end
    return true, "admitted"
end

function Policy.IsFinderNearGoal(zombie, targetX, targetY, targetZ, reach)
    local behavior
    local fx, fy, fz
    local action
    if not zombie or not zombie.getPathFindBehavior2 then
        return false
    end
    -- If vanilla spotted a player since the last tick, never skip the refresh:
    -- WalkTowardState would otherwise steer toward zombie.target instead of
    -- the NPC coordinate goal.
    if zombie.getTarget and zombie:getTarget() ~= nil then
        return false
    end
    action = zombie.getActionStateName
        and string.lower(tostring(zombie:getActionStateName() or "")) or ""
    if action ~= "pathfind" and action ~= "walktoward"
        and action ~= "walktoward-network"
    then
        return false
    end
    behavior = zombie:getPathFindBehavior2()
    if not behavior
        or type(behavior.getTargetX) ~= "function"
        or type(behavior.getTargetY) ~= "function"
    then
        return false
    end
    fx = tonumber(behavior:getTargetX())
    fy = tonumber(behavior:getTargetY())
    if fx == nil or fy == nil then return false end
    if type(behavior.getTargetZ) == "function" then
        fz = tonumber(behavior:getTargetZ())
        if fz ~= nil and math.floor(fz) ~= math.floor(targetZ) then
            return false
        end
    end
    reach = tonumber(reach)
        or numberConst("ZOMBIE_AGGRO_FINDER_DEDUP_TILES", 2.0)
    return math.abs(fx - targetX) <= reach
        and math.abs(fy - targetY) <= reach
end

function Policy.UpdateProgress(zombie, modData, now)
    local zx, zy, progX, progY, progAt, dx, dy
    local stallMs = numberConst("ZOMBIE_AGGRO_STALL_MS", 2500)
    if not zombie or not modData then return false end
    now = nowMs(now)
    zx = tonumber(zombie:getX()) or 0
    zy = tonumber(zombie:getY()) or 0
    progX = tonumber(modData.PNC_AggroProgX)
    progY = tonumber(modData.PNC_AggroProgY)
    progAt = tonumber(modData.PNC_AggroProgAt)
    if progX == nil or progY == nil or progAt == nil then
        modData.PNC_AggroProgX = zx
        modData.PNC_AggroProgY = zy
        modData.PNC_AggroProgAt = now
        modData.PNC_AggroBackoffMs = nil
        return false
    end
    dx = zx - progX
    dy = zy - progY
    if (dx * dx) + (dy * dy) >= 0.0625 then
        modData.PNC_AggroProgX = zx
        modData.PNC_AggroProgY = zy
        modData.PNC_AggroProgAt = now
        modData.PNC_AggroBackoffMs = nil
        return false
    end
    return (now - progAt) >= stallMs
end

function Policy.ComputeRepathCooldown(modData, stalled, targetChanged)
    local baseMs = numberConst("ZOMBIE_NPC_PATH_REFRESH_MS", 500)
    local maxMs = numberConst("ZOMBIE_AGGRO_STALL_BACKOFF_MAX_MS", 6400)
    if not modData then return baseMs end
    if targetChanged == true or stalled ~= true then
        modData.PNC_AggroBackoffMs = nil
        return baseMs
    end
    local prev = tonumber(modData.PNC_AggroBackoffMs) or baseMs
    local nextWait = math.min(maxMs, math.max(baseMs, prev * 2))
    modData.PNC_AggroBackoffMs = nextWait
    return nextWait
end

function Policy.ComputeLeadGoal(modData, zx, zy, zz, tx, ty, tz, now)
    local lastAt, lastX, lastY, span, vx, vy, ax, ay
    local leadMs = numberConst("ZOMBIE_AGGRO_LEAD_MS", 500)
    local maxLead = numberConst("ZOMBIE_AGGRO_LEAD_MAX_TILES", 2.0)
    if not modData or math.floor(zz) ~= math.floor(tz) then
        return tx, ty
    end
    now = nowMs(now)
    lastAt = tonumber(modData.PNC_AggroSampleAt)
    lastX = tonumber(modData.PNC_AggroSampleX)
    lastY = tonumber(modData.PNC_AggroSampleY)
    modData.PNC_AggroSampleAt = now
    modData.PNC_AggroSampleX = tx
    modData.PNC_AggroSampleY = ty
    if lastAt == nil or lastX == nil or lastY == nil then
        return tx, ty
    end
    span = now - lastAt
    if span < 100 or span > 1500 then
        return tx, ty
    end
    vx = tx - lastX
    vy = ty - lastY
    ax = tx - zx
    ay = ty - zy
    if (vx * ax) + (vy * ay) <= 0 or (ax * ax) + (ay * ay) <= 4 then
        return tx, ty
    end
    local scale = leadMs / span
    local lx, ly = vx * scale, vy * scale
    local lenSq = (lx * lx) + (ly * ly)
    if lenSq > (maxLead * maxLead) then
        local inv = maxLead / math.sqrt(lenSq)
        lx, ly = lx * inv, ly * inv
    end
    return tx + lx, ty + ly
end

function Policy.UpdateLungeVisual(zombie, wanted)
    if not zombie or type(zombie.setVariable) ~= "function" then
        return false
    end
    local shouldLunge = wanted == true
    if shouldLunge then
        if (zombie.isCrawling and zombie:isCrawling() == true)
            or (zombie.isProne and zombie:isProne() == true)
            or (zombie.isDead and zombie:isDead() == true)
        then
            shouldLunge = false
        end
    end
    local current = type(zombie.getVariableBoolean) == "function"
        and zombie:getVariableBoolean("PNCZombieLunge") == true
        or false
    if current ~= shouldLunge then
        zombie:setVariable("PNCZombieLunge", shouldLunge)
    end
    return shouldLunge
end

-- Reusable, budgeted sound-lure helper for distant/off-screen horde attraction
-- (e.g. base raids, gunfire, alarms). Never overrides an active NPC pursuit
-- lease or close player combat, and rate-limits per zombie + global A* cap.
function Policy.AttractZombieToSound(zombie, x, y, z, now, options)
    if not zombie or type(zombie.pathToSound) ~= "function" then
        return false, "pathToSound_unavailable"
    end
    if (zombie.isDead and zombie:isDead() == true)
        or (Core and Core.IsManagedNPCBody and Core.IsManagedNPCBody(zombie) == true)
    then
        return false, "invalid_zombie"
    end
    now = nowMs(now)
    local modData = zombie.getModData and zombie:getModData() or nil
    if modData then
        if modData.PNC_ZombiePursuitOwner ~= nil
            and (tonumber(modData.PNC_ZombiePursuitUntil) or 0) > now
        then
            return false, "pursuit_leased"
        end
        local cooldownMs = (type(options) == "table" and tonumber(options.cooldownMs))
            or numberConst("ZOMBIE_AGGRO_SOUND_LURE_COOLDOWN_MS", 5000)
        local lastLure = tonumber(modData.PNC_SoundLureAt) or -1e12
        if now >= lastLure and (now - lastLure) < cooldownMs then
            return false, "lure_cooldown"
        end
    end
    if not Policy.CanAdmitAStar(zombie, now, false, false) then
        return false, "budget_capped"
    end
    local gx = math.floor(tonumber(x) or zombie:getX())
    local gy = math.floor(tonumber(y) or zombie:getY())
    local gz = math.floor(tonumber(z) or zombie:getZ())
    zombie:pathToSound(gx, gy, gz)
    local enteredPathfind = type(zombie.getVariableBoolean) == "function"
        and zombie:getVariableBoolean("bPathfind") == true
    Policy.NotePathIssued(zombie, now, enteredPathfind)
    if modData then
        modData.PNC_SoundLureAt = now
    end
    return true, enteredPathfind and "sound_lure_pathfind" or "sound_lure_walktoward"
end

return Policy
