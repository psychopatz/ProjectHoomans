-- Coarse, rebuildable population indexes plus minimal persisted cooldown state.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PopulationSectors = PNC.PopulationSectors or {}

local Sectors = PNC.PopulationSectors
local Config = PNC.DirectorConfig.Population
local Store = PNC.AbstractWorldStore
local Core = PNC.Core

Sectors.Runtime = Sectors.Runtime or {}
Sectors.GroupIDs = Sectors.GroupIDs or {}
Sectors.CommunityIDs = Sectors.CommunityIDs or {}
Sectors.GroupSector = Sectors.GroupSector or {}
Sectors.CommunitySector = Sectors.CommunitySector or {}
Sectors.PlayerPositions = Sectors.PlayerPositions or {}
Sectors.Metrics = Sectors.Metrics or { rebuilds = 0, repairs = 0, mismatches = 0 }
Sectors.History = Sectors.History or {}
Sectors.RepairCursor = Sectors.RepairCursor or 1

local function persistent()
    Store.EnsureLoaded()
    -- Store.Load/Save own normalization. Replacing this table on every read
    -- invalidates references held by bootstrap and reconciliation transactions,
    -- causing otherwise valid mutations (starter attempts/completion) to vanish.
    if type(Store.Registry.population) ~= "table" then
        Store.Registry.population = PNC.AbstractWorldTypes.NormalizePopulation(nil)
    end
    return Store.Registry.population
end

local function coords(x, y)
    local size = Config.SECTOR_SIZE
    return math.floor((tonumber(x) or 0) / size),
        math.floor((tonumber(y) or 0) / size)
end

function Sectors.IDForPosition(x, y)
    local sx, sy = coords(x, y)
    return "psector_" .. tostring(sx) .. "_" .. tostring(sy), sx, sy
end

function Sectors.ParseID(id)
    local sx, sy = string.match(tostring(id or ""),
        "^psector_([%-]?%d+)_([%-]?%d+)$")
    return tonumber(sx), tonumber(sy)
end

function Sectors.Center(id)
    local sx, sy = Sectors.ParseID(id)
    if not sx then return nil end
    return { x = (sx + 0.5) * Config.SECTOR_SIZE,
        y = (sy + 0.5) * Config.SECTOR_SIZE, z = 0 }
end

function Sectors.Ensure(id)
    local data = persistent()
    local state = data.sectors[tostring(id or "")]
    if not state then
        local sx = Sectors.ParseID(id)
        if sx == nil then return nil end
        state = { id = id, discovered = false, hadGroups = false,
            hadSettlements = false,
            groupGenerationCooldownUntil = 0,
            settlementGenerationCooldownUntil = 0,
            lastReconciledAt = 0 }
        data.sectors[id] = state
        Store.Touch("population_sector_created")
    end
    local runtime = Sectors.Runtime[id]
    if not runtime then
        runtime = { id = id, active = false, relevant = false,
            nearbyPlayers = 0, desiredGroups = 0, desiredSettlements = 0,
            groupPressure = 1, settlementPressure = 1 }
        Sectors.Runtime[id] = runtime
    end
    return state, runtime
end

function Sectors.MarkRelevant(id, discovered)
    local state, runtime = Sectors.Ensure(id)
    if not state then return false, "invalid_sector" end
    runtime.relevant = true
    if discovered == true and not state.discovered then
        state.discovered = true
        Store.Touch("population_sector_discovered")
    end
    return true, "relevant"
end

local function add(index, id, entityID)
    index[id] = index[id] or {}
    index[id][entityID] = true
end

local function remove(index, id, entityID)
    if index[id] then index[id][entityID] = nil end
end

function Sectors.RegisterGroup(group)
    if not group or not group.id or not group.location then return false end
    local id = Sectors.IDForPosition(group.location.x, group.location.y)
    local old = Sectors.GroupSector[group.id]
    if old and old ~= id then remove(Sectors.GroupIDs, old, group.id) end
    Sectors.GroupSector[group.id] = id
    add(Sectors.GroupIDs, id, group.id)
    local state, runtime = Sectors.Ensure(id)
    runtime.relevant = true
    state.discovered = true
    state.hadGroups = true
    return true
end

function Sectors.UnregisterGroup(groupID)
    local id = Sectors.GroupSector[tostring(groupID or "")]
    if not id then return false end
    remove(Sectors.GroupIDs, id, groupID)
    Sectors.GroupSector[groupID] = nil
    return true, id
end

function Sectors.RegisterCommunity(community)
    local home = community and (community.home
        or community.site and community.site.home) or nil
    if not community or not community.id or not home then return false end
    local id = Sectors.IDForPosition(home.x, home.y)
    local old = Sectors.CommunitySector[community.id]
    if old and old ~= id then remove(Sectors.CommunityIDs, old, community.id) end
    Sectors.CommunitySector[community.id] = id
    add(Sectors.CommunityIDs, id, community.id)
    local state, runtime = Sectors.Ensure(id)
    runtime.relevant = true
    state.discovered = true
    state.hadSettlements = true
    return true
end

function Sectors.UnregisterCommunity(communityID)
    local id = Sectors.CommunitySector[tostring(communityID or "")]
    if not id then return false end
    remove(Sectors.CommunityIDs, id, communityID)
    Sectors.CommunitySector[communityID] = nil
    return true, id
end

local function count(map)
    local total = 0
    for _ in pairs(map or {}) do total = total + 1 end
    return total
end

function Sectors.CountGroups(id)
    local total = 0
    for groupID in pairs(Sectors.GroupIDs[id] or {}) do
        local group = PNC.AbstractGroups.Get(groupID)
        if group and not group.homeCommunityId then total = total + 1 end
    end
    return total
end
function Sectors.CountAllGroups(id) return count(Sectors.GroupIDs[id]) end
function Sectors.CountSettlements(id) return count(Sectors.CommunityIDs[id]) end

function Sectors.Get(id)
    local state, runtime = Sectors.Ensure(id)
    if not state then return nil end
    local output = Core.DeepCopy(runtime)
    for key, value in pairs(state) do output[key] = value end
    output.groupCount = Sectors.CountGroups(id)
    output.settlementCount = Sectors.CountSettlements(id)
    local survivors = {}
    for groupID in pairs(Sectors.GroupIDs[id] or {}) do
        local group = PNC.AbstractGroups.Get(groupID)
        for _, npcID in ipairs(group and group.memberIds or {}) do survivors[npcID] = true end
    end
    for communityID in pairs(Sectors.CommunityIDs[id] or {}) do
        local community = PNC.Communities.Get(communityID)
        for npcID in pairs(community and community.memberIDs or {}) do survivors[npcID] = true end
    end
    output.survivorCount = count(survivors)
    return output
end

function Sectors.ListRelevant()
    local output = {}
    for id, state in pairs(persistent().sectors) do
        local runtime = Sectors.Runtime[id]
        if state.discovered or runtime and runtime.relevant then
            output[#output + 1] = Sectors.Get(id)
        end
    end
    table.sort(output, function(a, b)
        if a.active ~= b.active then return a.active == true end
        return a.id < b.id
    end)
    return output
end

function Sectors.NeighborIDs(id)
    local sx, sy = Sectors.ParseID(id)
    local output = {}
    if not sx then return output end
    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                output[#output + 1] = "psector_" .. tostring(sx + dx)
                    .. "_" .. tostring(sy + dy)
            end
        end
    end
    return output
end

function Sectors.RefreshPlayers()
    Sectors.PlayerPositions = {}
    local changed = false
    local previouslyActive = {}
    for _, runtime in pairs(Sectors.Runtime) do
        previouslyActive[runtime.id] = runtime.active == true
        runtime.active, runtime.nearbyPlayers = false, 0
    end
    Core.ForEachPlayer(function(player)
        local position = { x = player:getX(), y = player:getY(), z = player:getZ() }
        Sectors.PlayerPositions[#Sectors.PlayerPositions + 1] = position
        local id, sx, sy = Sectors.IDForPosition(position.x, position.y)
        local state, runtime = Sectors.Ensure(id)
        if not state.discovered then changed = true end
        state.discovered, runtime.active, runtime.relevant = true, true, true
        if not previouslyActive[id] then
            Store.Emit("POPULATION_SECTOR_ACTIVATED", { sectorId = id })
            previouslyActive[id] = true
        end
        runtime.nearbyPlayers = runtime.nearbyPlayers + 1
        for dx = -Config.ACTIVE_NEIGHBOR_RADIUS, Config.ACTIVE_NEIGHBOR_RADIUS do
            for dy = -Config.ACTIVE_NEIGHBOR_RADIUS, Config.ACTIVE_NEIGHBOR_RADIUS do
                local neighborID = "psector_" .. tostring(sx + dx)
                    .. "_" .. tostring(sy + dy)
                local neighborState, neighbor = Sectors.Ensure(neighborID)
                if not neighborState.discovered then changed = true end
                neighborState.discovered, neighbor.relevant = true, true
            end
        end
    end)
    if changed then Store.Touch("population_player_footprint_discovered") end
    return #Sectors.PlayerPositions
end

function Sectors.PlayerDistance(x, y)
    local best = math.huge
    for _, player in ipairs(Sectors.PlayerPositions) do
        local distance = Core.Distance(x, y, player.x, player.y)
        if distance < best then best = distance end
    end
    return best
end

function Sectors.LivePlayerDistance(x, y)
    local best = math.huge
    Core.ForEachPlayer(function(player)
        local distance = Core.Distance(x, y, player:getX(), player:getY())
        if distance < best then best = distance end
    end)
    return best
end

function Sectors.RebuildIndexes()
    Sectors.GroupIDs, Sectors.CommunityIDs = {}, {}
    Sectors.GroupSector, Sectors.CommunitySector = {}, {}
    for _, group in ipairs(PNC.AbstractGroups.List()) do Sectors.RegisterGroup(group) end
    for _, community in ipairs(PNC.Communities.List()) do
        if community.status == "active" and community.mode ~= "nomadic" then
            Sectors.RegisterCommunity(community)
        end
    end
    Sectors.Metrics.rebuilds = Sectors.Metrics.rebuilds + 1
    return true
end

function Sectors.Repair(budget)
    budget = math.max(1, math.floor(tonumber(budget) or Config.INDEX_REPAIR_BUDGET))
    local entities = {}
    for _, group in ipairs(PNC.AbstractGroups.List()) do
        entities[#entities + 1] = { kind = "GROUP", id = group.id, value = group }
    end
    for _, community in ipairs(PNC.Communities.List()) do
        if community.status == "active" and community.mode ~= "nomadic" then
            entities[#entities + 1] = { kind = "SETTLEMENT", id = community.id,
                value = community }
        end
    end
    table.sort(entities, function(a, b)
        return a.kind == b.kind and a.id < b.id or a.kind < b.kind
    end)
    if #entities == 0 then return 0 end
    Sectors.RepairCursor = math.max(1,
        math.min(#entities, tonumber(Sectors.RepairCursor) or 1))
    local checked = 0
    while checked < budget and checked < #entities do
        local entity = entities[Sectors.RepairCursor]
        local expected
        if entity.kind == "GROUP" then
            expected = entity.value.location and Sectors.IDForPosition(
                entity.value.location.x, entity.value.location.y) or nil
        else
            local home = entity.value.home
            expected = home and Sectors.IDForPosition(home.x, home.y) or nil
        end
        local actual = entity.kind == "GROUP" and Sectors.GroupSector[entity.id]
            or Sectors.CommunitySector[entity.id]
        if expected ~= actual then
            Sectors.Metrics.mismatches = Sectors.Metrics.mismatches + 1
            if entity.kind == "GROUP" then Sectors.RegisterGroup(entity.value)
            else Sectors.RegisterCommunity(entity.value) end
        end
        checked = checked + 1
        Sectors.RepairCursor = Sectors.RepairCursor % #entities + 1
    end
    Sectors.Metrics.repairs = Sectors.Metrics.repairs + 1
    return checked
end

function Sectors.SetSuppression(id, kind, reason)
    local _, runtime = Sectors.Ensure(id)
    local field = kind == "SETTLEMENT" and "settlementSuppressionReason"
        or "groupSuppressionReason"
    local normalized = tostring(reason or "NONE")
    if runtime[field] == normalized then return false end
    runtime[field] = normalized
    if PNC.PopulationLog and PNC.PopulationLog.Info then
        PNC.PopulationLog.Info("SUPPRESSION_CHANGED", { sectorId = id,
            kind = kind, reason = normalized })
    end
    return true
end

function Sectors.NextGenerationID(kind)
    local data = persistent()
    local serial = data.nextGenerationSerial
    data.nextGenerationSerial = serial + 1
    Store.Touch("population_generation_sequence")
    return "POP_" .. tostring(kind or "ENTITY") .. "_"
        .. string.format("%07d", serial), serial
end

function Sectors.Seed(text)
    local value = 5381
    text = tostring(text or "")
    for index = 1, #text do
        value = (value * 33 + string.byte(text, index)) % 2147483647
    end
    return value
end

local function engineSeedString()
    local instance = WorldGenParams and WorldGenParams.INSTANCE or nil
    if not instance or not instance.getSeedString then return nil end
    local ok, value = pcall(instance.getSeedString, instance)
    value = ok and tostring(value or "") or ""
    return value ~= "" and value or nil
end

function Sectors.WorldSeed()
    local data = persistent()
    if (tonumber(data.worldSeed) or 0) > 0 then
        return data.worldSeed, data.worldSeedString
    end
    local seedString = engineSeedString()
    local seed
    if seedString then
        seed = Sectors.Seed("PZ_WORLD:" .. seedString)
    elseif ZombRand then
        local ok, value = pcall(ZombRand, 2147483646)
        seed = ok and tonumber(value) and math.floor(value) + 1 or nil
    end
    seed = math.max(1, math.min(2147483647,
        tonumber(seed) or Sectors.Seed("PNC_POPULATION_WORLD")))
    data.worldSeed = seed
    data.worldSeedString = seedString or ("PNC-" .. tostring(seed))
    Store.Touch("population_world_seed")
    return data.worldSeed, data.worldSeedString
end

function Sectors.GenerationSeed(kind, sectorID, serial, qualifier)
    local worldSeed = Sectors.WorldSeed()
    return Sectors.Seed(table.concat({ tostring(worldSeed),
        tostring(kind or "ENTITY"), tostring(sectorID or ""),
        tostring(serial or 0), tostring(qualifier or "") }, ":"))
end

function Sectors.WeightedChoice(weights, seed)
    local keys, total = {}, 0
    for key, value in pairs(type(weights) == "table" and weights or {}) do
        value = math.max(0, tonumber(value) or 0)
        if value > 0 then
            keys[#keys + 1] = tostring(key)
            total = total + value
        end
    end
    if total <= 0 then return nil end
    table.sort(keys)
    local roll = (Sectors.Seed(tostring(seed) .. ":WEIGHTED_ROLL")
        % 1000000) / 1000000 * total
    for _, key in ipairs(keys) do
        roll = roll - math.max(0, tonumber(weights[key]) or 0)
        if roll <= 0 then return key end
    end
    return keys[#keys]
end

function Sectors.IsCommitted(generationID)
    return persistent().committedGenerationIds[tostring(generationID or "")] == true
end

function Sectors.MarkCommitted(generationID)
    local data = persistent()
    generationID = tostring(generationID or "")
    if data.committedGenerationIds[generationID] then return false end
    data.committedGenerationIds[generationID] = true
    data.committedOrder[#data.committedOrder + 1] = generationID
    while #data.committedOrder > Config.COMMITTED_GENERATION_HISTORY_LIMIT do
        local expired = table.remove(data.committedOrder, 1)
        data.committedGenerationIds[expired] = nil
    end
    Store.Touch("population_generation_committed")
    return true
end

function Sectors.SetProvenance(entityID, generation)
    if not entityID or type(generation) ~= "table" then return false end
    persistent().provenance[tostring(entityID)] = Core.DeepCopy(generation)
    Store.Touch("population_provenance")
    return true
end

function Sectors.AddHistory(eventName, details, now)
    local entry = Core.DeepCopy(details or {})
    entry.event = tostring(eventName or "POPULATION_EVENT")
    entry.at = tonumber(now) or Store.WorldAgeHours()
    Sectors.History[#Sectors.History + 1] = entry
    while #Sectors.History > Config.GENERATION_HISTORY_LIMIT do
        table.remove(Sectors.History, 1)
    end
    return entry
end

return Sectors
