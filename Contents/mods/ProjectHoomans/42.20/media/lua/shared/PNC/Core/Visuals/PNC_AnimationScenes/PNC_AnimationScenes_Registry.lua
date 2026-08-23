local Scenes = PNC.AnimationScenes
local Internal = Scenes.Internal

Scenes.Definitions = Scenes.Definitions or {}
Scenes.Pools = Scenes.Pools or {}

function Internal.PoolEntry(poolName, sceneId)
    local pool = Scenes.Pools[poolName]
    local i
    for i = 1, #(pool or {}) do
        if pool[i].id == sceneId then
            return pool[i]
        end
    end
    return nil
end

function Internal.RemoveFromPools(sceneId)
    local pool
    local i
    local poolName
    for poolName, pool in pairs(Scenes.Pools) do
        for i = #pool, 1, -1 do
            if pool[i].id == sceneId then
                table.remove(pool, i)
            end
        end
        if #pool <= 0 then
            Scenes.Pools[poolName] = nil
        end
    end
end

function Internal.AddToPool(definition)
    local poolName = definition.pool
    local entry
    if not poolName or poolName == "" or definition.weight <= 0 then
        return
    end
    Scenes.Pools[poolName] = Scenes.Pools[poolName] or {}
    entry = Internal.PoolEntry(poolName, definition.id)
    if entry then
        entry.weight = definition.weight
    else
        Scenes.Pools[poolName][#Scenes.Pools[poolName] + 1] = {
            id = definition.id,
            weight = definition.weight,
        }
    end
end

function Internal.ChoosePoolScene(poolName, excludedSceneId)
    local pool = Scenes.Pools[poolName]
    local total = 0
    local roll
    local i
    for i = 1, #(pool or {}) do
        if pool[i].id ~= excludedSceneId or #pool <= 1 then
            total = total + math.max(0, tonumber(pool[i].weight) or 0)
        end
    end
    if total <= 0 then return nil end
    roll = Internal.NextRandom(total)
    for i = 1, #pool do
        if pool[i].id ~= excludedSceneId or #pool <= 1 then
            roll = roll - math.max(0, tonumber(pool[i].weight) or 0)
            if roll < 0 then
                return pool[i].id
            end
        end
    end
    return pool[#pool] and pool[#pool].id or nil
end

function Scenes.Register(sceneId, definition)
    local steps
    local stepError
    local normalized
    sceneId = tostring(sceneId or "")
    if sceneId == "" or type(definition) ~= "table" then
        return false, "invalid_scene"
    end
    steps, stepError = Internal.NormalizeSteps(definition)
    if not steps then return false, stepError end
    normalized = Internal.NormalizeDefinition(sceneId, definition, steps)
    Internal.RemoveFromPools(sceneId)
    Scenes.Definitions[sceneId] = normalized
    Internal.AddToPool(normalized)
    return true, normalized
end

function Scenes.Unregister(sceneId)
    sceneId = tostring(sceneId or "")
    if not Scenes.Definitions[sceneId] then
        return false
    end
    Scenes.Definitions[sceneId] = nil
    Internal.RemoveFromPools(sceneId)
    return true
end

function Scenes.Get(sceneId)
    return Scenes.Definitions[tostring(sceneId or "")]
end

function Scenes.List()
    local entries = {}
    local sceneId
    local definition
    for sceneId, definition in pairs(Scenes.Definitions) do
        entries[#entries + 1] = definition
    end
    table.sort(entries, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return entries
end

function Scenes.ListPools()
    local names = {}
    local poolName
    for poolName in pairs(Scenes.Pools) do
        names[#names + 1] = poolName
    end
    table.sort(names)
    return names
end

function Scenes.ChoosePoolScene(poolName, excludedSceneId)
    return Internal.ChoosePoolScene(
        tostring(poolName or ""),
        excludedSceneId and tostring(excludedSceneId) or nil
    )
end
