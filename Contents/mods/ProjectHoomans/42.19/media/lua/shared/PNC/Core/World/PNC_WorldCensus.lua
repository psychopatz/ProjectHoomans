-- Shared loaded-zombie census. Spatial indexing, body lifecycle auditing, and
-- zombie aggro consume this snapshot so only one engine zombie-list traversal
-- is needed per refresh window.

PNC = PNC or {}
PNC.WorldCensus = PNC.WorldCensus or {}

local Census = PNC.WorldCensus
local Core = PNC.Core
local Const = PNC.Const
local Performance = PNC.Performance

Census.AllZombies = Census.AllZombies or {}
Census.OrdinaryZombies = Census.OrdinaryZombies or {}
Census.ManagedBodies = Census.ManagedBodies or {}
Census.LifecycleCandidates = Census.LifecycleCandidates or {}
Census.ByOnlineID = Census.ByOnlineID or {}
Census.LastRefreshAt = Census.LastRefreshAt or nil
Census.Generation = tonumber(Census.Generation) or 0

local function clearArray(values)
    local i
    for i = #values, 1, -1 do
        values[i] = nil
    end
end

local function clearMap(values)
    local key
    for key, _ in pairs(values) do
        values[key] = nil
    end
end

local function ensureZombieID(zombie)
    local modData
    if not zombie or not zombie.getModData then return nil end
    modData = zombie:getModData()
    if not modData then return nil end
    if not modData.PNC_ZombieID or tostring(modData.PNC_ZombieID) == "" then
        modData.PNC_ZombieID = Core.GenerateID("pz")
    end
    return tostring(modData.PNC_ZombieID)
end

local function refreshInterval()
    local liveByID = PNC.Registry and PNC.Registry.LiveByID or nil
    local hasLive = false
    local id
    local body
    if liveByID then
        for id, body in pairs(liveByID) do
            hasLive = id ~= nil and body ~= nil
            break
        end
    end
    if hasLive then
        return tonumber(Const.WORLD_CENSUS_REFRESH_MS) or 100
    end
    return tonumber(Const.WORLD_CENSUS_IDLE_REFRESH_MS)
        or tonumber(Const.WORLD_CENSUS_REFRESH_MS)
        or 500
end

function Census.Refresh(now, force)
    local startedAt
    local cell
    local zombieList
    local zombie
    local i
    local lastRefreshAt = tonumber(Census.LastRefreshAt)
    now = tonumber(now) or Core.Now()
    if force ~= true
        and lastRefreshAt ~= nil
        and now - lastRefreshAt
            < refreshInterval()
    then
        return false
    end
    startedAt = Performance and Performance.Begin and Performance.Begin() or nil

    Census.LastRefreshAt = now
    clearArray(Census.AllZombies)
    clearArray(Census.OrdinaryZombies)
    clearArray(Census.ManagedBodies)
    clearArray(Census.LifecycleCandidates)
    clearMap(Census.ByOnlineID)

    cell = getCell and getCell() or nil
    zombieList = cell and cell.getZombieList and cell:getZombieList() or nil
    if zombieList then
        for i = 0, zombieList:size() - 1 do
            zombie = zombieList:get(i)
            if zombie then
                local onlineID = zombie.getOnlineID
                    and tonumber(zombie:getOnlineID()) or nil
                local modData = zombie.getModData and zombie:getModData() or nil
                local managed = Core.IsManagedNPCBody(zombie)
                Census.AllZombies[#Census.AllZombies + 1] = zombie
                if onlineID and onlineID >= 0 then
                    Census.ByOnlineID[tostring(onlineID)] = zombie
                end
                if managed then
                    Census.ManagedBodies[#Census.ManagedBodies + 1] = zombie
                elseif not zombie:isDead() then
                    ensureZombieID(zombie)
                    Census.OrdinaryZombies[#Census.OrdinaryZombies + 1] = zombie
                end
                if managed or (modData and (
                    modData.PNC_DeathMarkerID ~= nil
                    or modData.PNC_BodyKind == "corpse"
                    or modData.PNC_PersistedShell == true
                )) then
                    Census.LifecycleCandidates[
                        #Census.LifecycleCandidates + 1
                    ] = zombie
                end
            end
        end
    end

    Census.Generation = Census.Generation + 1
    if Performance then
        Performance.Count("worldCensus.refreshes", 1)
        Performance.Count("worldCensus.zombiesScanned", #Census.AllZombies)
        Performance.SetGauge("worldCensus.loadedZombies", #Census.OrdinaryZombies)
        Performance.SetGauge("worldCensus.managedBodies", #Census.ManagedBodies)
        Performance.SetGauge(
            "worldCensus.lifecycleCandidates",
            #Census.LifecycleCandidates
        )
        Performance.Finish("worldCensus.refresh", startedAt)
    end
    return true
end

function Census.GetAll(now, force)
    Census.Refresh(now, force)
    return Census.AllZombies
end

function Census.GetOrdinary(now, force)
    Census.Refresh(now, force)
    return Census.OrdinaryZombies
end

function Census.GetManaged(now, force)
    Census.Refresh(now, force)
    return Census.ManagedBodies
end

function Census.GetLifecycleCandidates(now, force)
    Census.Refresh(now, force)
    return Census.LifecycleCandidates
end

function Census.GetGeneration()
    return Census.Generation
end

function Census.FindByOnlineID(onlineID, now)
    if onlineID == nil then return nil end
    Census.Refresh(now, false)
    return Census.ByOnlineID[tostring(onlineID)]
end
