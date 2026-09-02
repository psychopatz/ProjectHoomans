if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Core = PNC.Core
local Lifecycle = PNC.BodyLifecycle
local Stockpile = PNC.StockpileAccessService
local WorkRepository = PNC.WorkRepository
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"

local function pointKey(x, y, z)
    return tostring(math.floor(tonumber(x) or 0)) .. ":"
        .. tostring(math.floor(tonumber(y) or 0)) .. ":"
        .. tostring(math.floor(tonumber(z) or 0))
end

local function squareAt(x, y, z)
    local cell = getCell and getCell() or nil
    if not cell or not cell.getGridSquare then return nil end
    return cell:getGridSquare(math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0), math.floor(tonumber(z) or 0))
end

local function squareState(x, y, z)
    local square = squareAt(x, y, z)
    local pathInternal = PNC.PathService and PNC.PathService.Internal
    if not square then return "unloaded" end
    if pathInternal and pathInternal.isSquareWalkable then
        local walkable = pathInternal.isSquareWalkable(x, y, z)
        return walkable == true and "walkable" or "blocked"
    end
    if square.isSolid and square:isSolid() == true then return "blocked" end
    if square.isSolidTrans and square:isSolidTrans() == true then return "blocked" end
    if square.isFree then return square:isFree(false) and "walkable" or "blocked" end
    return "walkable"
end

local function numericKeys(source)
    local keys = {}
    for key, _ in pairs(type(source) == "table" and source or {}) do
        local value = tonumber(key)
        if value then keys[#keys + 1] = value end
    end
    table.sort(keys)
    return keys
end

local function regionRows(level)
    return type(level) == "table" and (level.rows or level) or nil
end

local function forEachRegionTile(region, callback)
    if type(region) ~= "table" or type(callback) ~= "function" then return end
    local levels = region.levels or {}
    for _, z in ipairs(numericKeys(levels)) do
        local rows = regionRows(levels[z]) or {}
        for _, y in ipairs(numericKeys(rows)) do
            local spans = rows[y] or {}
            for index = 1, #spans, 2 do
                local first, last = tonumber(spans[index]),
                    tonumber(spans[index + 1])
                if first and last and first <= last then
                    for x = first, last do callback(x, y, z) end
                end
            end
        end
    end
end

local function terminalWorkOrder(order)
    local status = order and tostring(order.status or "") or ""
    return status == "CANCELLED" or status == "COMPLETED"
        or status == "FAILED"
end

local function workOrderForToken(token, baseId)
    if not WorkRepository or not WorkRepository.Load then return nil end
    WorkRepository.Load()
    for _, order in pairs(WorkRepository.State.byId or {}) do
        local payload = order and order.payload or nil
        if order and order.operation == "CORPSE_HAUL"
            and not terminalWorkOrder(order)
            and (baseId == nil or tostring(order.baseId or "")
                == tostring(baseId or ""))
            and tostring(payload and payload.haulToken or "")
                == tostring(token or "")
        then
            return order
        end
    end
    return nil
end

local function dropReserved(x, y, z)
    local key = pointKey(x, y, z)
    if Service.Runtime.byDrop[key] then return true end
    if not WorkRepository or not WorkRepository.Load then return false end
    WorkRepository.Load()
    for _, order in pairs(WorkRepository.State.byId or {}) do
        local payload = order and order.payload or nil
        if order and order.operation == "CORPSE_HAUL"
            and not terminalWorkOrder(order)
            and tonumber(payload and payload.dropX) == tonumber(x)
            and tonumber(payload and payload.dropY) == tonumber(y)
            and tonumber(payload and payload.dropZ) == tonumber(z)
        then
            return true
        end
    end
    return false
end

local function pendingCorpseOrderCount(baseId)
    local count = 0
    if not WorkRepository or not WorkRepository.Load then return count end
    WorkRepository.Load()
    for _, order in pairs(WorkRepository.State.byId or {}) do
        if order and order.operation == "CORPSE_HAUL"
            and not terminalWorkOrder(order)
            and tostring(order.baseId or "") == tostring(baseId or "")
        then
            count = count + 1
        end
    end
    return count
end

local function transmit(object)
    if object and object.transmitModData then object:transmitModData() end
end

function Service.GetCorpseToken(corpse, create)
    local data = corpse and corpse.getModData and corpse:getModData() or nil
    local token
    if not data then return nil end
    token = data.PNC_CorpseHaulToken
    if token ~= nil and tostring(token) ~= "" then return tostring(token) end
    if create ~= true then return nil end
    token = Core.GenerateID("corpse_haul")
    data.PNC_CorpseHaulToken = token
    transmit(corpse)
    return token
end

local function clearCorpseHaulToken(corpse, expectedToken)
    local data = corpse and corpse.getModData and corpse:getModData() or nil
    local token = data and data.PNC_CorpseHaulToken or nil
    if not data or token == nil or tostring(token) == "" then return false end
    if expectedToken ~= nil
        and tostring(token) ~= tostring(expectedToken)
    then return false end
    data.PNC_CorpseHaulToken = nil
    return true
end

function Service.IsEligibleCorpse(corpse)
    local item = corpse and corpse.getItem and corpse:getItem() or nil
    local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
    if not corpse then return false end
    if corpse.isAnimal and corpse:isAnimal() == true then return false end
    if fullType == "Base.CorpseAnimal" then return false end
    -- forEachCorpse already restricts this object to the engine's corpse
    -- collection. The home-service check belongs to worker authorization, not
    -- corpse ownership: ordinary vanilla human corpses are valid haul targets.
    return true
end

function Service.GetCorpseAt(x, y, z, token, deathMarkerId)
    local square = squareAt(x, y, z)
    local found
    if not square or not Lifecycle or not Lifecycle.Internal
        or not Lifecycle.Internal.forEachCorpse
    then return nil end
    Lifecycle.Internal.forEachCorpse(square, function(corpse)
        local candidateToken = Service.GetCorpseToken(corpse, false)
        local data = corpse and corpse.getModData
            and corpse:getModData() or nil
        local candidateMarker = data and (data.PNC_DeathMarkerID
            or data.PNC_UUID) or nil
        local tokenMatches = token == nil
            or tostring(candidateToken or "") == tostring(token)
        -- The haul token is authoritative for ordinary vanilla corpses. A
        -- lifecycle marker is an additional identity check when present, but
        -- older/untracked bodies may legitimately have no marker at all.
        local markerMatches = deathMarkerId == nil or candidateMarker == nil
            or tostring(candidateMarker or "") == tostring(deathMarkerId)
        if not found and Service.IsEligibleCorpse(corpse)
            and tokenMatches and markerMatches
        then
            found = corpse
        end
    end)
    return found
end

function Service.CountCorpsesInRegion(region)
    local total = 0
    local eligible = 0
    local cell = getCell and getCell() or nil
    if not cell or not cell.getGridSquare
        or not Lifecycle or not Lifecycle.Internal
        or not Lifecycle.Internal.forEachCorpse
    then
        return nil, nil
    end
    forEachRegionTile(region, function(x, y, z)
        local square = squareAt(x, y, z)
        if square then
            Lifecycle.Internal.forEachCorpse(square, function(corpse)
                total = total + 1
                if Service.IsEligibleCorpse(corpse) then
                    eligible = eligible + 1
                end
            end)
        end
    end)
    return total, eligible
end

function Service.GetSourceCorpseCounts(baseOrId)
    local base = type(baseOrId) == "table" and baseOrId
        or PNC.BaseService and PNC.BaseService.Get
            and PNC.BaseService.Get(baseOrId) or nil
    local configuration = Internal.configurationFor(base)
    local baseId = tostring(base and base.id or "")
    local now = Core.Now()
    local cached = Service.Runtime.countsByBase[baseId]
    local total
    local eligible
    if not configuration or not configuration.sourceRegion then
        return nil, nil
    end
    if cached and cached.revision == configuration.revision
        and now < cached.updatedAt + Service.CORPSE_COUNT_CACHE_MS
    then
        return cached.total, cached.eligible
    end
    total, eligible = Service.CountCorpsesInRegion(
        configuration.sourceRegion)
    Service.Runtime.countsByBase[baseId] = {
        revision = configuration.revision,
        total = total, eligible = eligible, updatedAt = now,
    }
    return total, eligible
end

local function hasCorpse(square)
    local result = false
    if not square or not Lifecycle or not Lifecycle.Internal
        or not Lifecycle.Internal.forEachCorpse
    then return false end
    Lifecycle.Internal.forEachCorpse(square, function() result = true end)
    return result
end

local function findDropPoint(facilityId, preferredX, preferredY, preferredZ,
    allowedRegion)
    local region = allowedRegion
    if not region then
        region = Stockpile and Stockpile.GetFacilityRegion
            and Stockpile.GetFacilityRegion(facilityId) or nil
    end
    local best
    local bestDistance
    forEachRegionTile(region, function(x, y, z)
        local square = squareAt(x, y, z)
        local state = squareState(x, y, z)
        if square and state == "walkable" and not hasCorpse(square)
            and not dropReserved(x, y, z)
        then
            local dx = x - (tonumber(preferredX) or x)
            local dy = y - (tonumber(preferredY) or y)
            local dz = z - (tonumber(preferredZ) or z)
            local distance = dx * dx + dy * dy + dz * dz
            if not best or distance < bestDistance then
                best = { x = x, y = y, z = z }
                bestDistance = distance
            end
        end
    end)
    return best
end

local function scanBaseCorpses(base)
    local configuration = Internal.configurationFor(base)
    local zone = base and base.baseZoneId and Zones.get(base.baseZoneId) or nil
    local sourceRegion = configuration and configuration.sourceRegion
        or zone and zone.geometry or nil
    local found = {}
    local seen = {}
    if not sourceRegion then return found end
    forEachRegionTile(sourceRegion, function(x, y, z)
        local square = squareAt(x, y, z)
        if square and Lifecycle and Lifecycle.Internal
            and Lifecycle.Internal.forEachCorpse
        then
            Lifecycle.Internal.forEachCorpse(square, function(corpse)
                local token
                local data
                if Service.IsEligibleCorpse(corpse) then
                    token = Service.GetCorpseToken(corpse, false)
                    data = corpse and corpse.getModData
                        and corpse:getModData() or nil
                    if not seen[corpse] then
                        seen[corpse] = true
                        found[#found + 1] = {
                            corpse = corpse, token = token,
                            x = math.floor(corpse:getX()),
                            y = math.floor(corpse:getY()),
                            z = math.floor(corpse:getZ()),
                            squareX = x, squareY = y, squareZ = z,
                            deathMarkerId = data and (data.PNC_DeathMarkerID
                                or data.PNC_UUID) or nil,
                            taskId = data and data.PNC_CorpseHaulTaskId or nil,
                        }
                    end
                end
            end)
        end
    end)
    return found
end

local function stockpileFacilities(base)
    local output = {}
    for facilityId, present in pairs(base and base.facilityIds or {}) do
        local facility = present == true and PNC.SettlementRepository
            and PNC.SettlementRepository.GetFacility(facilityId) or nil
        if facility and facility.definitionId == "stockpile"
            and (FacilityState.IsBuilt(facility)
                or facility.constructionState == "RECONSTRUCTING")
            and Stockpile and Stockpile.GetFacilityRegion
            and Stockpile.GetFacilityRegion(facility.id)
        then
            output[#output + 1] = facility
        end
    end
    table.sort(output, function(a, b) return tostring(a.id) < tostring(b.id) end)
    return output
end

Internal.pointKey = pointKey
Internal.squareAt = squareAt
Internal.forEachRegionTile = forEachRegionTile
Internal.terminalWorkOrder = terminalWorkOrder
Internal.workOrderForToken = workOrderForToken
Internal.dropReserved = dropReserved
Internal.pendingCorpseOrderCount = pendingCorpseOrderCount
Internal.transmit = transmit
Internal.clearCorpseHaulToken = clearCorpseHaulToken
Internal.findDropPoint = findDropPoint
Internal.scanBaseCorpses = scanBaseCorpses
Internal.stockpileFacilities = stockpileFacilities

return Service
