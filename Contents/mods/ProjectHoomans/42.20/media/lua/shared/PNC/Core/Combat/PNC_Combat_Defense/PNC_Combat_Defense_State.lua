local Defense = PNC.CombatDefense
local Internal = Defense.Internal
local Core = PNC.Core
local Const = PNC.Const
local Spatial = PNC.SpatialIndex

function Internal.SettingNumber(name, fallback, minimum, maximum)
    local settings = PNC.Sandbox
    local getter = settings and settings[name]
    local value = getter and getter() or fallback
    value = tonumber(value) or tonumber(fallback) or 0
    if minimum ~= nil then value = math.max(value, minimum) end
    if maximum ~= nil then value = math.min(value, maximum) end
    return value
end

function Internal.DamageModelEnabled()
    local settings = PNC.Sandbox
    local getter = settings and settings.NPCZombieDamageModelEnabled
    return getter and getter() == true or false
end

function Internal.Clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

function Internal.RandomUnit()
    if ZombRand then return ZombRand(10000) / 10000 end
    return math.random()
end

function Internal.EnsureState(record)
    if type(record) ~= "table" then return nil end
    record.runtime = record.runtime or {}
    record.runtime.combatDefense = record.runtime.combatDefense or {}
    return record.runtime.combatDefense
end

function Internal.BodyPosition(record, npcBody)
    local x = npcBody and npcBody.getX and npcBody:getX()
        or tonumber(record and record.x) or 0
    local y = npcBody and npcBody.getY and npcBody:getY()
        or tonumber(record and record.y) or 0
    local z = npcBody and npcBody.getZ and npcBody:getZ()
        or tonumber(record and record.z) or 0
    return x, y, z
end

local function isNearbyZombie(zombie, x, y, z, radiusSq)
    return zombie
        and (not zombie.isDead or not zombie:isDead())
        and (not Core.IsManagedNPCBody
            or not Core.IsManagedNPCBody(zombie))
        and zombie.getX and zombie.getY and zombie.getZ
        and math.abs((tonumber(zombie:getZ()) or z) - z) < 1
        and Core.DistanceSq(x, y, zombie:getX(), zombie:getY())
            <= radiusSq
end

function Defense.CountNearbyZombies(record, npcBody, radius)
    local x
    local y
    local z
    local zombies
    local count = 0
    local i
    radius = tonumber(radius)
        or tonumber(Const.NPC_ZOMBIE_DEFENSE_RADIUS) or 2.2
    x, y, z = Internal.BodyPosition(record, npcBody)
    if not Spatial or not Spatial.QueryZombies then return 0 end
    zombies = Spatial.QueryZombies(x, y, radius)
    for i = 1, #zombies do
        if isNearbyZombie(zombies[i], x, y, z, radius * radius) then
            count = count + 1
        end
    end
    return count
end

local function stateIsFresh(state, x, y, z, radius, now)
    return Internal.DamageModelEnabled()
        and state.updatedAt
        and now - state.updatedAt
            < (tonumber(Const.NPC_ZOMBIE_DEFENSE_REFRESH_MS) or 200)
        and state.radius == radius
        and Core.DistanceSq(x, y, state.x or x, state.y or y) <= 0.25
        and math.abs(z - (state.z or z)) < 1
end

function Defense.Refresh(record, npcBody, now)
    local state = Internal.EnsureState(record)
    local radius
    local x
    local y
    local z
    if not state then return nil end
    radius = Internal.DamageModelEnabled()
        and Internal.SettingNumber("NPCZombieDamageHitRadius", 2.2, 0.1, 6)
        or (tonumber(Const.NPC_ZOMBIE_DEFENSE_RADIUS) or 2.2)
    now = tonumber(now) or Core.Now()
    x, y, z = Internal.BodyPosition(record, npcBody)
    if stateIsFresh(state, x, y, z, radius, now) then return state end
    state.radius = radius
    state.nearbyCount = Defense.CountNearbyZombies(record, npcBody, radius)
    state.x = x
    state.y = y
    state.z = z
    state.updatedAt = now
    return state
end
