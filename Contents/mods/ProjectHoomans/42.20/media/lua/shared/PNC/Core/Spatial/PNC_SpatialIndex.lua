PNC = PNC or {}
PNC.SpatialIndex = PNC.SpatialIndex or {}

local Spatial = PNC.SpatialIndex
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Census = PNC.WorldCensus
local Performance = PNC.Performance

Spatial.PlayerCells = Spatial.PlayerCells or {}
Spatial.PlayerByOnlineID = Spatial.PlayerByOnlineID or {}
Spatial.PlayerByUsername = Spatial.PlayerByUsername or {}
Spatial.NPCCells = Spatial.NPCCells or {}
Spatial.ZombieCells = Spatial.ZombieCells or {}
Spatial.ZombieByID = Spatial.ZombieByID or {}
Spatial.NPCMembership = Spatial.NPCMembership or {}
Spatial.NPCInitialized = Spatial.NPCInitialized or false
if tonumber(Spatial.IndexSchemaVersion) ~= 3 then
    Spatial.PlayerCells = {}
    Spatial.PlayerByOnlineID = {}
    Spatial.PlayerByUsername = {}
    Spatial.NPCCells = {}
    Spatial.ZombieCells = {}
    Spatial.ZombieByID = {}
    Spatial.NPCMembership = {}
    Spatial.NPCInitialized = false
    Spatial.LastCensusGeneration = nil
    Spatial.IndexSchemaVersion = 3
end

local function getCellCoordinates(x, y)
    local size = Const.SPATIAL_CELL_SIZE
    return math.floor(x / size), math.floor(y / size)
end

local function insertCell(grid, x, y, value)
    local cellX
    local cellY
    local column
    local bucket
    cellX, cellY = getCellCoordinates(x, y)
    column = grid[cellX]
    if not column then
        column = { _count = 0 }
        grid[cellX] = column
    end
    bucket = column[cellY]
    if not bucket then
        bucket = {}
        column[cellY] = bucket
        column._count = (tonumber(column._count) or 0) + 1
    end
    bucket[#bucket + 1] = value
end

local function removeFromCell(grid, cellX, cellY, value)
    local column = grid[cellX]
    local bucket = column and column[cellY] or nil
    local i
    if not bucket then
        return
    end
    for i = #bucket, 1, -1 do
        if bucket[i] == value then
            table.remove(bucket, i)
        end
    end
    if #bucket <= 0 then
        column[cellY] = nil
        column._count = math.max(0, (tonumber(column._count) or 1) - 1)
        if column._count <= 0 then
            grid[cellX] = nil
        end
    end
end

function Spatial.UpdateNPC(record)
    local id
    local cellX
    local cellY
    local previous
    if not record or not record.id then
        return
    end
    id = tostring(record.id)
    previous = Spatial.NPCMembership[id]
    if record.alive == false or record.presenceState == Const.PRESENCE_CORPSE then
        if previous then
            removeFromCell(
                Spatial.NPCCells,
                previous.cellX,
                previous.cellY,
                previous.record
            )
            Spatial.NPCMembership[id] = nil
        end
        return
    end
    cellX, cellY = getCellCoordinates(record.x, record.y)
    if previous
        and previous.cellX == cellX
        and previous.cellY == cellY
        and previous.record == record
    then
        return
    end
    if previous then
        removeFromCell(
            Spatial.NPCCells,
            previous.cellX,
            previous.cellY,
            previous.record
        )
    end
    insertCell(Spatial.NPCCells, record.x, record.y, record)
    Spatial.NPCMembership[id] = {
        cellX = cellX,
        cellY = cellY,
        record = record,
    }
end

function Spatial.RemoveNPC(id)
    local previous = id ~= nil and Spatial.NPCMembership[tostring(id)] or nil
    if previous then
        removeFromCell(
            Spatial.NPCCells,
            previous.cellX,
            previous.cellY,
            previous.record
        )
        Spatial.NPCMembership[tostring(id)] = nil
    end
end

local function ensureZombieID(zombie)
    local modData
    if not zombie or not zombie.getModData then
        return nil
    end
    modData = zombie:getModData()
    if not modData then
        return nil
    end
    if not modData.PNC_ZombieID or tostring(modData.PNC_ZombieID) == "" then
        modData.PNC_ZombieID = Core.GenerateID("pz")
    end
    return tostring(modData.PNC_ZombieID)
end

function Spatial.Rebuild(now, force)
    local startedAt
    local zombieList
    local censusZombies
    local zombie
    local zombieID
    local i
    local lastRebuildAt = tonumber(Spatial.LastRebuildAt)
    now = tonumber(now) or Core.Now()
    if force ~= true
        and lastRebuildAt ~= nil
        and now - lastRebuildAt
            < (tonumber(Const.SPATIAL_REBUILD_MS) or 100)
    then
        return false
    end
    startedAt = Performance and Performance.Begin and Performance.Begin() or nil
    Spatial.LastRebuildAt = now
    Spatial.PlayerCells = {}
    Spatial.PlayerByOnlineID = {}
    Spatial.PlayerByUsername = {}

    Core.ForEachPlayer(function(player)
        local onlineID
        local username
        insertCell(Spatial.PlayerCells, player:getX(), player:getY(), player)
        onlineID = player.getOnlineID and player:getOnlineID() or nil
        username = player.getUsername and player:getUsername() or nil
        if onlineID ~= nil then
            Spatial.PlayerByOnlineID[tostring(onlineID)] = player
        end
        if username and tostring(username) ~= "" then
            Spatial.PlayerByUsername[tostring(username)] = player
        end
    end)

    if not Spatial.NPCInitialized then
        Spatial.NPCCells = {}
        Spatial.NPCMembership = {}
        Registry.ForEach(function(record)
            Spatial.UpdateNPC(record)
        end)
        Spatial.NPCInitialized = true
    end

    if Census and Census.GetOrdinary then
        censusZombies = Census.GetOrdinary(now, force)
        local generation = Census.GetGeneration
            and Census.GetGeneration() or nil
        if force == true
            or generation == nil
            or generation ~= Spatial.LastCensusGeneration
        then
            Spatial.ZombieCells = {}
            Spatial.ZombieByID = {}
            for i = 1, #censusZombies do
                zombie = censusZombies[i]
                insertCell(
                    Spatial.ZombieCells,
                    zombie:getX(),
                    zombie:getY(),
                    zombie
                )
                zombieID = ensureZombieID(zombie)
                if zombieID then
                    Spatial.ZombieByID[zombieID] = zombie
                end
            end
            Spatial.LastCensusGeneration = generation
            if Performance then
                Performance.Count("spatial.zombieIndexRebuilds", 1)
            end
        end
    elseif getCell then
        Spatial.ZombieCells = {}
        Spatial.ZombieByID = {}
        zombieList = getCell():getZombieList()
        if zombieList then
            for i = 0, zombieList:size() - 1 do
                zombie = zombieList:get(i)
                if zombie and (not zombie:isDead()) and (not Core.IsManagedNPCBody(zombie)) then
                    insertCell(Spatial.ZombieCells, zombie:getX(), zombie:getY(), zombie)
                    zombieID = ensureZombieID(zombie)
                    if zombieID then
                        Spatial.ZombieByID[zombieID] = zombie
                    end
                end
            end
        end
    end
    if Performance then
        Performance.Count("spatial.rebuilds", 1)
        Performance.Finish("spatial.rebuild", startedAt)
    end
    return true
end

local function queryGrid(grid, x, y, radius)
    local size = Const.SPATIAL_CELL_SIZE
    local minCellX = math.floor((x - radius) / size)
    local maxCellX = math.floor((x + radius) / size)
    local minCellY = math.floor((y - radius) / size)
    local maxCellY = math.floor((y + radius) / size)
    local results = {}
    local cellX
    local cellY
    local bucket
    local column
    local i

    for cellX = minCellX, maxCellX do
        for cellY = minCellY, maxCellY do
            column = grid[cellX]
            bucket = column and column[cellY] or nil
            if bucket then
                for i = 1, #bucket do
                    results[#results + 1] = bucket[i]
                end
            end
        end
    end
    return results
end

function Spatial.QueryPlayers(x, y, radius)
    return queryGrid(Spatial.PlayerCells, x, y, radius)
end

function Spatial.QueryNPCs(x, y, radius)
    return queryGrid(Spatial.NPCCells, x, y, radius)
end

function Spatial.QueryZombies(x, y, radius)
    return queryGrid(Spatial.ZombieCells, x, y, radius)
end

function Spatial.FindZombieByID(zombieID)
    if not zombieID then
        return nil
    end
    return Spatial.ZombieByID[tostring(zombieID)]
end

function Spatial.GetZombieID(zombie)
    return ensureZombieID(zombie)
end

function Spatial.FindPlayerByOnlineID(onlineID)
    if onlineID == nil then return nil end
    return Spatial.PlayerByOnlineID[tostring(onlineID)]
end

function Spatial.FindPlayerByUsername(username)
    if username == nil then return nil end
    return Spatial.PlayerByUsername[tostring(username)]
end
