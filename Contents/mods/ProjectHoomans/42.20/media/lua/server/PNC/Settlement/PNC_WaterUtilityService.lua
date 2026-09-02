if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WaterUtilityService = PNC.WaterUtilityService or {}

local Service = PNC.WaterUtilityService
local Repository = PNC.SettlementRepository
local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"
local LITERS_PER_TANK = 25
local MINUTES_PER_CATCH = 10

local function worldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and tonumber(gameTime:getWorldAgeHours()) or 0
end

local function rainState(forced)
    if forced ~= nil then return forced == true end
    local climate = getClimateManager and getClimateManager() or nil
    if not climate then return false end
    if climate.getPrecipitationIntensity then
        local ok, value = pcall(function()
            return climate:getPrecipitationIntensity()
        end)
        if ok then return (tonumber(value) or 0) > 0 end
    end
    if climate.isRaining then
        local ok, value = pcall(function() return climate:isRaining() end)
        if ok then return value == true end
    end
    return false
end

local function moduleCounts(facility)
    local tanks, catchers, spigots = 0, 0, 0
    for componentId, present in pairs(facility.componentIds or {}) do
        local component = present and Repository.GetComponent(componentId) or nil
        if component and component.role == "water.tank" then tanks = tanks + 1
        elseif component and component.role == "water.catcher" then
            catchers = catchers + 1
        elseif component and component.role == "water.spigot" then
            spigots = spigots + 1
        end
    end
    return tanks, catchers, spigots
end

local function stateFor(facility, now)
    facility.utilityState = type(facility.utilityState) == "table"
        and facility.utilityState or {}
    local state = facility.utilityState
    state.waterLiters = math.max(0, tonumber(state.waterLiters) or 0)
    state.rainCarry = math.max(0, tonumber(state.rainCarry) or 0)
    state.lastWaterUpdateHour = tonumber(state.lastWaterUpdateHour) or now
    return state
end

function Service.Tick(nowHours, forcedRaining)
    Repository.Load()
    local now = tonumber(nowHours) or worldAgeHours()
    local raining = rainState(forcedRaining)
    local changed = false
    for _, facility in pairs(Repository.State.facilities or {}) do
        if facility.definitionId == "water_collector" then
            local state = stateFor(facility, now)
            local tanks, catchers, spigots = moduleCounts(facility)
            local capacity = tanks * LITERS_PER_TANK
            local elapsedHours = math.max(0,
                math.min(1, now - state.lastWaterUpdateHour))
            local before = state.waterLiters
            if raining and FacilityState.IsBuilt(facility)
                and catchers > 0 and tanks > 0 and spigots > 0
            then
                local raw = state.rainCarry
                    + catchers * (elapsedHours * 60 / MINUTES_PER_CATCH)
                -- World-age hours are floating point; tolerate the tiny error
                -- around exact ten-minute boundaries.
                local whole = math.floor(raw + 0.000001)
                state.rainCarry = raw - whole
                state.waterLiters = math.min(capacity,
                    state.waterLiters + whole)
            else
                state.waterLiters = math.min(capacity, state.waterLiters)
            end
            state.lastWaterUpdateHour = now
            if state.waterLiters ~= before or elapsedHours > 0 then changed = true end
        end
    end
    Service.LastRaining = raining
    if changed then Repository.MarkDirty() end
    return changed
end

function Service.Consume(facilityId, liters)
    local facility = Repository.GetFacility(facilityId)
    if not facility or facility.definitionId ~= "water_collector" then
        return false, "WATER_COLLECTOR_NOT_FOUND"
    end
    local state = stateFor(facility, worldAgeHours())
    local amount = math.max(0, tonumber(liters) or 0)
    if state.waterLiters < amount then return false, "INSUFFICIENT_WATER" end
    state.waterLiters = state.waterLiters - amount
    Repository.MarkDirty()
    return true, state.waterLiters
end

function Service.BuildSnapshot(baseId)
    local output = { waterLiters = 0, capacityLiters = 0, tanks = 0,
        catchers = 0, spigots = 0, litersPerTenMinutes = 0,
        raining = Service.LastRaining == true, facilities = {} }
    local now = worldAgeHours()
    for _, facility in pairs(Repository.State.facilities or {}) do
        if facility.definitionId == "water_collector"
            and tostring(facility.baseId) == tostring(baseId)
        then
            local tanks, catchers, spigots = moduleCounts(facility)
            local state = stateFor(facility, now)
            local capacity = tanks * LITERS_PER_TANK
            local row = { facilityId = facility.id, level = facility.level,
                waterLiters = math.min(capacity, state.waterLiters),
                capacityLiters = capacity, tanks = tanks, catchers = catchers,
                spigots = spigots, litersPerTenMinutes = catchers,
                operational = facility.cachedState == "OPERATIONAL" }
            output.facilities[#output.facilities + 1] = row
            output.waterLiters = output.waterLiters + row.waterLiters
            output.capacityLiters = output.capacityLiters + capacity
            output.tanks = output.tanks + tanks
            output.catchers = output.catchers + catchers
            output.spigots = output.spigots + spigots
            output.litersPerTenMinutes = output.litersPerTenMinutes + catchers
        end
    end
    table.sort(output.facilities, function(a, b)
        return tostring(a.facilityId) < tostring(b.facilityId)
    end)
    return output
end

if Events and Events.EveryTenMinutes and not Service.TickHookRegistered then
    Events.EveryTenMinutes.Add(function() Service.Tick() end)
    Service.TickHookRegistered = true
end

return Service
