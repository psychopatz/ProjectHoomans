-- Lazy abstract locations, coarse spatial lookup, and occupancy ownership.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractLocations = PNC.AbstractLocations or {}

local Locations = PNC.AbstractLocations
local Store = PNC.AbstractWorldStore
local Types = PNC.AbstractWorldTypes
local Config = PNC.DirectorConfig
local Core = PNC.Core

Locations.Cells = Locations.Cells or {}
Locations.Membership = Locations.Membership or {}
Locations.IndexedRevision = Locations.IndexedRevision or -1
Locations.DiscoveryCursor = Locations.DiscoveryCursor or 0
Locations.LastMetaDiscovery = Locations.LastMetaDiscovery or nil

local function authority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

local function cellKey(x, y)
    local size = Config.LOCATION_CELL_SIZE
    return tostring(math.floor((tonumber(x) or 0) / size)) .. ":"
        .. tostring(math.floor((tonumber(y) or 0) / size))
end

local function ref(location)
    return location and { id = location.id, type = location.type,
        x = location.x, y = location.y, z = location.z } or nil
end

local function index(location)
    local key = cellKey(location.x, location.y)
    Locations.Cells[key] = Locations.Cells[key] or {}
    Locations.Cells[key][location.id] = location
    Locations.Membership[location.id] = key
end

function Locations.RebuildIndex()
    Store.EnsureLoaded()
    Locations.Cells, Locations.Membership = {}, {}
    for _, location in pairs(Store.Registry.locationsByID) do index(location) end
    Locations.IndexedRevision = Store.Registry.revision
end

function Locations.ReconcileOccupancy()
    Store.EnsureLoaded()
    local expected = {}
    for _, group in pairs(Store.Registry.groupsByID) do
        local lod = group.simulation and group.simulation.lod or "ABSTRACT"
        if lod == "ABSTRACT" and group.state ~= "TRAVELING"
            and group.state ~= "ACTIVE" and group.location
            and Store.Registry.locationsByID[group.location.id]
        then
            expected[group.location.id] = expected[group.location.id] or {}
            expected[group.location.id][group.id] = true
        end
    end
    local changed = false
    for _, location in pairs(Store.Registry.locationsByID) do
        local occupants = location.occupants.groups
        for groupID in pairs(occupants) do
            if not (expected[location.id] and expected[location.id][groupID]) then
                occupants[groupID] = nil
                changed = true
            end
        end
        for groupID in pairs(expected[location.id] or {}) do
            if not occupants[groupID] then
                occupants[groupID] = { arrivedAt = Store.WorldAgeHours(),
                    plannedDepartureAt = 0 }
                changed = true
            end
        end
    end
    if changed then Store.Touch("occupancy_reconciled") end
    return changed
end

local function ensureIndex()
    if Locations.IndexedRevision < 0 then Locations.RebuildIndex() end
end

function Locations.Get(locationID)
    Store.EnsureLoaded()
    return Store.Registry.locationsByID[tostring(locationID or "")]
end

function Locations.List()
    Store.EnsureLoaded()
    local output = {}
    for _, location in pairs(Store.Registry.locationsByID) do
        output[#output + 1] = location
    end
    table.sort(output, function(a, b) return a.id < b.id end)
    return output
end

function Locations.Register(spec)
    if not authority() then return nil, "not_authority" end
    Store.EnsureLoaded()
    spec = type(spec) == "table" and spec or {}
    local normalized = Types.NormalizeLocation(spec, spec.id)
    if not normalized then return nil, "invalid_location" end
    local existing = Store.Registry.locationsByID[normalized.id]
    if existing then return existing, "existing" end
    Store.Registry.locationsByID[normalized.id] = normalized
    index(normalized)
    Store.Touch("location_registered")
    Store.Emit("LOCATION_REGISTERED", { locationId = normalized.id })
    return normalized, "registered"
end

local function siteLocationID(site)
    local raw = tostring(site and site.id or "")
    raw = string.gsub(raw, "[^%w_%-%.:]", "_")
    return raw ~= "" and ("aloc_" .. raw) or nil
end

function Locations.RegisterSite(site, spec)
    if type(site) ~= "table" or type(site.home) ~= "table" then
        return nil, "invalid_site"
    end
    spec = type(spec) == "table" and spec or {}
    local tags = type(spec.tags) == "table" and spec.tags or {}
    tags.SHELTER = tags.SHELTER ~= false
    if site.kind == "building" then tags.BUILDING = true end
    return Locations.Register({
        id = siteLocationID(site),
        type = spec.type or (site.occupantCommunityID
            and "SETTLEMENT" or "BUILDING"),
        x = site.home.x, y = site.home.y, z = site.home.z,
        tags = tags,
        resourcePotential = spec.resourcePotential or {},
        danger = spec.danger or 0,
        sourceSite = Core.DeepCopy(site),
    })
end

-- Only loaded buildings are considered here. This is deliberately bounded and
-- never walks the world meta-grid.
function Locations.DiscoverLoadedNear(x, y, z, radius, limit)
    local cell = getCell and getCell() or nil
    local list = cell and cell.getBuildingList and cell:getBuildingList() or nil
    local found, inspected = 0, 0
    radius = math.max(1, tonumber(radius) or Config.DESTINATION_QUERY_RADIUS)
    limit = math.max(1, math.floor(tonumber(limit)
        or Config.LOADED_BUILDING_DISCOVERY_LIMIT))
    if not list or not PNC.CommunitySiteResolver then return 0 end
    local count = list.size and list:size() or #list
    local first = list.size and 0 or 1
    local last = list.size and count - 1 or count
    if count <= 0 then return 0 end
    local start = first + (Locations.DiscoveryCursor % count)
    local scanBudget = math.min(count, limit * 4)
    for step = 0, scanBudget - 1 do
        local indexValue = first + ((start - first + step) % count)
        if found >= limit then break end
        inspected = inspected + 1
        local building = list.get and list:get(indexValue) or list[indexValue]
        local definition = building and building.getDef and building:getDef() or nil
        local site = definition and PNC.CommunitySiteResolver
            .DescribeBuildingDefinition(definition, z, {}) or nil
        if site and site.home then
            local dx, dy = site.home.x - x, site.home.y - y
            if dx * dx + dy * dy <= radius * radius then
                local location, reason = Locations.RegisterSite(site, {
                    tags = { HOUSE = building.isResidential
                        and building:isResidential() == true },
                })
                if location and reason == "registered" then found = found + 1 end
            end
        end
    end
    Locations.DiscoveryCursor = (Locations.DiscoveryCursor + inspected) % count
    return found
end

-- Bounded strategic-site discovery for starter population. Unlike the legacy
-- random-house helper, this asks the meta-grid for one explicit rectangle and
-- inspects only a capped, seed-rotated slice of that result.
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

function Locations.GetNearby(x, y, radius, limit)
    Store.EnsureLoaded()
    ensureIndex()
    local size = Config.LOCATION_CELL_SIZE
    radius = math.max(0, tonumber(radius) or 0)
    limit = math.max(1, math.floor(tonumber(limit) or 2147483647))
    local minX, maxX = math.floor((x - radius) / size),
        math.floor((x + radius) / size)
    local minY, maxY = math.floor((y - radius) / size),
        math.floor((y + radius) / size)
    local output = {}
    for cx = minX, maxX do
        for cy = minY, maxY do
            local bucket = Locations.Cells[tostring(cx) .. ":" .. tostring(cy)]
            for _, location in pairs(bucket or {}) do
                local dx, dy = location.x - x, location.y - y
                local distanceSq = dx * dx + dy * dy
                if distanceSq <= radius * radius then
                    output[#output + 1] = { location = location,
                        distance = math.sqrt(distanceSq) }
                end
            end
        end
    end
    table.sort(output, function(a, b)
        return a.distance == b.distance and a.location.id < b.location.id
            or a.distance < b.distance
    end)
    while #output > limit do table.remove(output) end
    return output
end

function Locations.Depart(group, at)
    local location = group and group.location and Locations.Get(group.location.id)
    local visit = location and location.occupants.groups[group.id] or nil
    if not visit then return false end
    location.occupants.groups[group.id] = nil
    location.visitHistory[#location.visitHistory + 1] = {
        groupId = group.id, arrivedAt = visit.arrivedAt,
        departedAt = tonumber(at) or Store.WorldAgeHours(),
    }
    while #location.visitHistory > Config.OCCUPANCY_HISTORY_LIMIT do
        table.remove(location.visitHistory, 1)
    end
    location.revision = location.revision + 1
    Store.Touch("group_departed")
    return true
end

function Locations.Arrive(group, at, plannedDepartureAt)
    local location = group and group.location and Locations.Get(group.location.id)
    if not location then return nil, "location_not_found" end
    location.occupants.groups[group.id] = {
        arrivedAt = tonumber(at) or Store.WorldAgeHours(),
        plannedDepartureAt = tonumber(plannedDepartureAt) or 0,
    }
    location.revision = location.revision + 1
    Store.Touch("group_arrived")
    return location, "arrived"
end

function Locations.GetGroupOccupants(locationOrID, excludeGroupID)
    local location = type(locationOrID) == "table" and locationOrID
        or Locations.Get(locationOrID)
    local output = {}
    for groupID, visit in pairs(location and location.occupants.groups or {}) do
        if groupID ~= excludeGroupID then
            output[#output + 1] = { groupId = groupID, visit = visit }
        end
    end
    table.sort(output, function(a, b) return a.groupId < b.groupId end)
    return output
end

Locations.Ref = ref

return Locations
