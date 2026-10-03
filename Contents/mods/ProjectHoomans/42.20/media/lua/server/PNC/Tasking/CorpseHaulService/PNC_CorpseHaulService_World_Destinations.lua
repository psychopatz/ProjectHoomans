if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CorpseHaulService = PNC.CorpseHaulService or {}
PNC.CorpseHaulService.Internal = PNC.CorpseHaulService.Internal or {}

local Service = PNC.CorpseHaulService
local Internal = Service.Internal

local Core = PNC.Core
local Lifecycle = PNC.BodyLifecycle
local Stockpile = PNC.StockpileAccessService
local WorkRepository = PNC.WorkRepository
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"
local forEachRegionTile = Internal.forEachRegionTile
local squareAt = Internal.squareAt
local squareState = Internal.squareState
local dropReserved = Internal.dropReserved
local hasCorpse = Internal.hasCorpse

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


Internal.findDropPoint = findDropPoint
Internal.scanBaseCorpses = scanBaseCorpses
Internal.stockpileFacilities = stockpileFacilities

return Service
