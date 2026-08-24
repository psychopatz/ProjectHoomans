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

return Locations

