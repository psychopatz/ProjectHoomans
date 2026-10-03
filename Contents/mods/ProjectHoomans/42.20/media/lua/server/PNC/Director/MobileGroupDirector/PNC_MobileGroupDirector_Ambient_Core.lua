if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.MobileGroupDirector = PNC.MobileGroupDirector or {}
PNC.MobileGroupDirectorInternal = PNC.MobileGroupDirectorInternal or {}

local Director = PNC.MobileGroupDirector
local H = PNC.MobileGroupDirectorInternal
H.Internal = H.Internal or {}

local function shelterTargetIsLocal(mobile, target)
    local providers = H.Internal.AmbientTargets
    return providers
        and providers.shelterTargetIsLocal
        and providers.shelterTargetIsLocal(mobile, target)
        or false
end
local Constants = PNC.FactionConstants
local Factions = PNC.Factions
local Resolver = PNC.CommunitySiteResolver
local Core = PNC.Core
local Const = PNC.Const
local Config = PNC.DirectorConfig or {}
local Diagnostics = PNC.PerformanceScalingDiagnostics
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

-- These helpers are intentionally sampled by the shared diagnostics service.
-- They avoid clock reads and table work when diagnostics are unavailable or
-- disabled, and they do not alter any director decisions.
local function beginDiagnosticTiming(name)
    if Diagnostics and Diagnostics.BeginTiming then
        return Diagnostics.BeginTiming(name)
    end
    return nil, nil
end

local function endDiagnosticTiming(name, startedAt, context)
    if name and Diagnostics and Diagnostics.EndTiming then
        Diagnostics.EndTiming(name, startedAt, context)
    end
end

local function incrementDiagnostic(name, amount)
    if Diagnostics and Diagnostics.Increment then
        Diagnostics.Increment(name, amount)
    end
end

local function setDiagnosticGauge(name, value)
    if Diagnostics and Diagnostics.SetGauge then
        Diagnostics.SetGauge(name, value)
    end
end

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return fallback
    end
    return value
end

-- Shared by ambient refresh and order repair after the ambient director split.
local function memberRecords(faction)
    local output = {}
    for npcID in pairs(faction and faction.memberIDs or {}) do
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcID) or nil
        if record and record.alive ~= false then
            output[#output + 1] = record
        end
    end
    return output
end

local function rectangleRegion(bounds)
    local helper = PNC.BaseValidationService
        and PNC.BaseValidationService.Internal
        and PNC.BaseValidationService.Internal.RectangleRegion
    if helper then
        return helper(
            bounds.minX,
            bounds.minY,
            bounds.maxX,
            bounds.maxY,
            bounds.minZ,
            bounds.maxZ
        )
    end
    local region = { levels = {} }
    local minZ = math.floor(finite(bounds.minZ, 0))
    local maxZ = math.floor(finite(bounds.maxZ, minZ))
    local z
    for z = minZ, maxZ do
        local rows = {}
        local y
        for y = math.floor(finite(bounds.minY, 0)),
            math.floor(finite(bounds.maxY, bounds.minY or 0))
        do
            rows[y] = {
                math.floor(finite(bounds.minX, 0)),
                math.floor(finite(bounds.maxX, bounds.minX or 0)),
            }
        end
        region.levels[z] = { rows = rows }
    end
    return GridRegion.normalize(region)
end

local function safehouseValue(safehouse, method)
    if not safehouse or not safehouse[method] then return nil end
    return finite(safehouse[method](safehouse), nil)
end

local function loadSafehouses()
    local output = {}
    if not SafeHouse or not SafeHouse.getSafehouseList then
        return output
    end
    local list = SafeHouse.getSafehouseList()
    if not list then return output end
    local count = list.size and list:size() or #list
    local index
    for index = 0, count - 1 do
        local safehouse = list.get
            and list:get(index) or list[index + 1]
        local x = safehouseValue(safehouse, "getX")
        local y = safehouseValue(safehouse, "getY")
        local width = safehouseValue(safehouse, "getW")
        local height = safehouseValue(safehouse, "getH")
        if x and y and width and height and width > 0 and height > 0 then
            output[#output + 1] = {
                minX = x,
                minY = y,
                maxX = x + width - 1,
                maxY = y + height - 1,
            }
        end
    end
    return output
end

function H.PlayerOwnershipSnapshot()
    local zones = Zones.export and Zones.export() or { byID = {} }
    local ownedZones = {}
    for _, zone in pairs(zones.byID or {}) do
        if zone.ownerType == "projecthoomans.base"
            or zone.ownerType == "projecthoomans.facility"
        then
            ownedZones[#ownedZones + 1] = zone
        end
    end
    return { zones = ownedZones, safehouses = loadSafehouses() }
end

local function boundsOverlap(left, right)
    return left.minX <= right.maxX and right.minX <= left.maxX
        and left.minY <= right.maxY and right.minY <= left.maxY
end

function H.IsPlayerOwnedShelterSite(site, snapshot)
    if type(site) ~= "table" or site.kind ~= "building" then
        return false
    end
    if site.claimantKey or site.status == "claimed"
        or site.occupantCommunityID
        or site.status == "occupied"
    then
        return true
    end
    local bounds = site.bounds
    if type(bounds) ~= "table" then return true end
    snapshot = snapshot or H.PlayerOwnershipSnapshot()
    local candidateRegion = rectangleRegion(bounds)
    for _, zone in ipairs(snapshot.zones or {}) do
        if zone.geometry and GridRegion.intersects(
            candidateRegion,
            zone.geometry
        ) then
            return true
        end
    end
    for _, safehouse in ipairs(snapshot.safehouses or {}) do
        if boundsOverlap(bounds, safehouse) then return true end
    end
    return false
end

function H.IsValidShelterSite(site, snapshot)
    if type(site) ~= "table" or site.kind ~= "building"
        or type(site.home) ~= "table"
        or type(site.bounds) ~= "table"
    then
        return false
    end
    if not Resolver or not Resolver.FindSpawnPoints then return false end
    return not H.IsPlayerOwnedShelterSite(site, snapshot)
        and site.status ~= "claimed"
        and site.status ~= "occupied"
end

function H.ShelterFilter(snapshot)
    snapshot = snapshot or H.PlayerOwnershipSnapshot()
    return function(site)
        return H.IsValidShelterSite(site, snapshot)
    end
end

H.Internal.AmbientTargets = {
    beginDiagnosticTiming = beginDiagnosticTiming,
    endDiagnosticTiming = endDiagnosticTiming,
    finite = finite,
}
H.Internal.memberRecords = memberRecords
H.Internal.incrementDiagnostic = incrementDiagnostic
H.Internal.setDiagnosticGauge = setDiagnosticGauge

return H
