-- Shared loaded-zombie census. Spatial indexing, body lifecycle auditing, and
-- zombie aggro consume this snapshot so only one engine zombie-list traversal
-- is needed per refresh window.

PNC = PNC or {}
PNC.WorldCensus = PNC.WorldCensus or {}

local Census = PNC.WorldCensus
local Core = PNC.Core
local Const = PNC.Const
local Diagnostics = PNC.PerformanceScalingDiagnostics

Census.AllZombies = Census.AllZombies or {}
Census.OrdinaryZombies = Census.OrdinaryZombies or {}
Census.ManagedBodies = Census.ManagedBodies or {}
Census.BanditBodies = Census.BanditBodies or {}
Census.LifecycleCandidates = Census.LifecycleCandidates or {}
Census.ByOnlineID = Census.ByOnlineID or {}
Census.LastRefreshAt = Census.LastRefreshAt or nil
Census.UrgentUntil = tonumber(Census.UrgentUntil) or 0
Census.CellAvailable = Census.CellAvailable ~= false
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

local function hasCombatOrUrgentActivity(now)
    if (tonumber(now) or 0) < (tonumber(Census.UrgentUntil) or 0) then
        return true
    end
    local liveByID = PNC.Registry and PNC.Registry.LiveByID or nil
    local records = PNC.Registry and PNC.Registry.Data or nil
    local runtimeViews = PNC.Registry and PNC.Registry.RuntimeViews or nil
    if liveByID then
        for id, body in pairs(liveByID) do
            if id ~= nil and body ~= nil then
                local record = (records and records[id])
                    or (runtimeViews and runtimeViews[id])
                    or nil
                local runtime = record and record.runtime or nil
                if runtime and (
                    runtime.attackAction ~= nil
                    or runtime.target ~= nil
                    or (tonumber(now) or 0) < (tonumber(runtime.inCombatUntil) or 0)
                ) then
                    return true
                end
            end
        end
    end
    local aggro = PNC.ZombieAggro
    local bites = aggro and aggro.State and aggro.State.bites or nil
    if bites then
        for _, _ in pairs(bites) do
            return true
        end
    end
    return false
end

local function isBanditCandidate(zombie, modData)
    if modData and (modData.Bandit == true or modData.isBandit == true) then
        return true
    end
    return zombie
        and zombie.getVariableBoolean
        and zombie:getVariableBoolean("Bandit") == true
        or false
end

local function refreshInterval(now)
    local liveByID = PNC.Registry and PNC.Registry.LiveByID or nil
    local hasLive = false
    local id
    local body
    if liveByID then
        for id, body in pairs(liveByID) do
            if id ~= nil and body ~= nil then
                hasLive = true
                break
            end
        end
    end
    if hasLive then
        if hasCombatOrUrgentActivity(now) then
            return tonumber(Const.WORLD_CENSUS_REFRESH_MS) or 100
        end
        return tonumber(Const.WORLD_CENSUS_CALM_REFRESH_MS) or 250
    end
    return tonumber(Const.WORLD_CENSUS_IDLE_REFRESH_MS)
        or tonumber(Const.WORLD_CENSUS_REFRESH_MS)
        or 1000
end

function Census.MarkUrgent(now, durationMs, invalidateThrottle)
    now = tonumber(now) or (Core.Now and Core.Now()) or 0
    durationMs = math.max(100, tonumber(durationMs) or 2000)
    local untilAt = now + durationMs
    if untilAt > (tonumber(Census.UrgentUntil) or 0) then
        Census.UrgentUntil = untilAt
    end
    if invalidateThrottle == true then
        Census.LastRefreshAt = nil
    end
    return Census.UrgentUntil
end

function Census.Refresh(now, force)
    local cell
    local zombieList
    local zombie
    local i
    local lastRefreshAt = tonumber(Census.LastRefreshAt)
    now = tonumber(now) or Core.Now()
    if force ~= true
        and lastRefreshAt ~= nil
        and now - lastRefreshAt
            < refreshInterval(now)
    then
        return false
    end
    Census.LastRefreshAt = now
    local timerName
    local timerStart
    if Diagnostics then
        timerName, timerStart = Diagnostics.BeginTiming(
            "WorldCensus.Refresh", now)
    end
    clearArray(Census.AllZombies)
    clearArray(Census.OrdinaryZombies)
    clearArray(Census.ManagedBodies)
    clearArray(Census.BanditBodies)
    clearArray(Census.LifecycleCandidates)
    clearMap(Census.ByOnlineID)

    cell = getCell and getCell() or nil
    zombieList = cell and cell.getZombieList and cell:getZombieList() or nil
    Census.CellAvailable = zombieList ~= nil
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
                    local onlineKey = tostring(onlineID)
                    if Census.ByOnlineID[onlineKey] ~= nil
                        and Census.ByOnlineID[onlineKey] ~= zombie
                    then
                        -- An online ID is not sufficient to distinguish two
                        -- engine bodies. Fail closed until identity-aware
                        -- resolution can select the correct instance.
                        Census.ByOnlineID[onlineKey] = false
                    elseif Census.ByOnlineID[onlineKey] == nil then
                        Census.ByOnlineID[onlineKey] = zombie
                    end
                end
                if managed then
                    Census.ManagedBodies[#Census.ManagedBodies + 1] = zombie
                elseif not zombie:isDead() then
                    ensureZombieID(zombie)
                    Census.OrdinaryZombies[#Census.OrdinaryZombies + 1] = zombie
                    if isBanditCandidate(zombie, modData) then
                        Census.BanditBodies[#Census.BanditBodies + 1] = zombie
                    end
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
    if Diagnostics then
        Diagnostics.SetGauge("WorldCensus.AllZombies", #Census.AllZombies)
        Diagnostics.SetGauge(
            "WorldCensus.OrdinaryZombies", #Census.OrdinaryZombies)
        Diagnostics.SetGauge(
            "WorldCensus.ManagedBodies", #Census.ManagedBodies)
    end
    if timerName then Diagnostics.EndTiming(timerName, timerStart) end
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

function Census.GetBandits(now, force)
    Census.Refresh(now, force)
    return Census.BanditBodies
end

function Census.GetLifecycleCandidates(now, force)
    Census.Refresh(now, force)
    return Census.LifecycleCandidates
end

function Census.GetGeneration()
    return Census.Generation
end

function Census.FindByOnlineID(onlineID, now)
    local body
    if onlineID == nil then return nil end
    Census.Refresh(now, false)
    body = Census.ByOnlineID[tostring(onlineID)]
    return body ~= false and body or nil
end
