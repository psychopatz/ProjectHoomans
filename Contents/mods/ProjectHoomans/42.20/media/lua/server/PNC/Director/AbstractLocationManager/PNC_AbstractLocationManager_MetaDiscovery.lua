if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractLocations = PNC.AbstractLocations or {}
PNC.AbstractLocationManagerInternal =
    PNC.AbstractLocationManagerInternal or {}

local Locations = PNC.AbstractLocations
local H = PNC.AbstractLocationManagerInternal
local Store = PNC.AbstractWorldStore
local Types = PNC.AbstractWorldTypes
local Config = PNC.DirectorConfig
local Core = PNC.Core

function Locations.DiscoverMetaBuildingsInBounds(bounds, z, seed, limit,
    inspectionLimit)
    bounds = type(bounds) == "table" and bounds or {}
    limit = math.max(1, math.floor(tonumber(limit) or 1))
    inspectionLimit = math.max(limit,
        math.floor(tonumber(inspectionLimit) or limit))
    local diagnostic = { found = 0, matched = 0, inspected = 0,
        residential = 0, locationIds = {}, reason = "META_GRID_UNAVAILABLE" }
    local world = getWorld and getWorld() or nil
    local metaGrid = world and world.getMetaGrid and world:getMetaGrid() or nil
    if not metaGrid or not metaGrid.getBuildingsIntersecting
        or not ArrayList or not ArrayList.new
        or not PNC.CommunitySiteResolver
    then
        Locations.LastMetaDiscovery = diagnostic
        return 0, diagnostic
    end
    local definitions = ArrayList.new()
    local minX = math.floor(tonumber(bounds.minX) or 0)
    local minY = math.floor(tonumber(bounds.minY) or 0)
    local maxX = math.floor(tonumber(bounds.maxX) or minX)
    local maxY = math.floor(tonumber(bounds.maxY) or minY)
    local ok = pcall(metaGrid.getBuildingsIntersecting, metaGrid,
        minX, minY, maxX, maxY, definitions)
    if not ok then
        diagnostic.reason = "META_QUERY_FAILED"
        Locations.LastMetaDiscovery = diagnostic
        return 0, diagnostic
    end
    local count = definitions.size and tonumber(definitions:size()) or 0
    diagnostic.matched = math.max(0, math.floor(count or 0))
    if diagnostic.matched <= 0 then
        diagnostic.reason = "NO_META_BUILDINGS_IN_SECTOR"
        Locations.LastMetaDiscovery = diagnostic
        return 0, diagnostic
    end
    local maximum = math.min(diagnostic.matched, inspectionLimit)
    local start = math.floor(tonumber(seed) or 0) % diagnostic.matched
    local inspectedDefinitions = {}
    for offset = 0, maximum - 1 do
        local indexValue = (start + offset) % diagnostic.matched
        local definition = definitions.get and definitions:get(indexValue) or nil
        if definition then
            inspectedDefinitions[#inspectedDefinitions + 1] = definition
            diagnostic.inspected = diagnostic.inspected + 1
        end
    end
    local seen = {}
    local function register(definition, residential)
        if #diagnostic.locationIds >= limit then return end
        local site = PNC.CommunitySiteResolver.DescribeBuildingDefinition(
            definition, tonumber(z) or 0, {})
        if not site or seen[site.id] then return end
        seen[site.id] = true
        local location, reason = Locations.RegisterSite(site, {
            tags = residential and { HOUSE = true, RESIDENTIAL = true }
                or { BUILDING = true },
        })
        if location and (reason == "registered" or reason == "existing") then
            diagnostic.locationIds[#diagnostic.locationIds + 1] = location.id
            if residential then diagnostic.residential = diagnostic.residential + 1 end
        end
    end
    for _, definition in ipairs(inspectedDefinitions) do
        if PNC.CommunitySiteResolver.IsResidentialDefinition(definition) then
            register(definition, true)
        end
    end
    if #diagnostic.locationIds == 0 then
        for _, definition in ipairs(inspectedDefinitions) do
            register(definition, false)
        end
    end
    diagnostic.found = #diagnostic.locationIds
    diagnostic.reason = diagnostic.found > 0 and "META_BUILDINGS_REGISTERED"
        or "NO_USABLE_META_BUILDINGS"
    Locations.LastMetaDiscovery = diagnostic
    return diagnostic.found, diagnostic
end

return Locations

