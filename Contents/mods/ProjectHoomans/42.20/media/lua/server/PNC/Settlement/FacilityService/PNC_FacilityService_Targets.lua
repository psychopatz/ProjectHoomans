if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityService = PNC.FacilityService or {}
PNC.FacilityService.Internal = PNC.FacilityService.Internal or {}

local Service = PNC.FacilityService
local Internal = Service.Internal
local Repository = PNC.SettlementRepository
local Validation = PNC.FacilityValidationService
local Definitions = PNC.FacilityDefinitions
local Costs = PNC.FacilityCostService
local EventsBus = PsychopatzCore and PsychopatzCore.Events

local function facilityRequiresWorkZone(facility)
    if not facility then return false end
    if Definitions.RequiresWorkZone then
        return Definitions.RequiresWorkZone(
            facility.definitionId, facility.level) == true
    end
    return false
end


local function pointFromRegion(region)
    local zKeys = {}
    for z, _ in pairs(region and region.levels or {}) do zKeys[#zKeys + 1] = z end
    table.sort(zKeys)
    for _, z in ipairs(zKeys) do
        local level = region.levels[z]
        local yKeys = {}
        for y, _ in pairs(level.rows or {}) do yKeys[#yKeys + 1] = y end
        table.sort(yKeys)
        for _, y in ipairs(yKeys) do
            local spans = level.rows[y]
            if spans and spans[1] ~= nil then
                return { x = spans[1], y = y, z = z }
            end
        end
    end
end

local function squareAt(x, y, z)
    local rules = PNC.World and PNC.World.SquareRules
    if rules and type(rules.GetSquare) == "function" then
        local ok, square = pcall(rules.GetSquare, x, y, z)
        if ok and square then return square end
    end
    local cell = getCell and getCell() or nil
    return cell and cell:getGridSquare(x, y, z) or nil
end

-- Can a colonist physically stand here? Region facilities such as the
-- stockpile are paved with containers: the region's own tiles are occupied by
-- the furniture the order is supposed to work on, and handing that tile to the
-- pathfinder produces "native_path_unreachable" until the order blocks at 0%.
local function isStandable(x, y, z)
    local square = squareAt(x, y, z)
    if not square then return false end
    -- A square with no floor cannot be walked to at all.
    if square.hasFloor and square:hasFloor() ~= true then return false end
    if square.isFree then return square:isFree(false) == true end
    return true
end

local EDGE_OFFSETS = {
    { x = 0, y = 1 }, { x = 1, y = 0 },
    { x = 0, y = -1 }, { x = -1, y = 0 },
    { x = 1, y = 1 }, { x = 1, y = -1 },
    { x = -1, y = -1 }, { x = -1, y = 1 },
}

--[[
    A region work target must be a tile a colonist can stand on.

    Region facilities such as the stockpile are paved with the containers the
    order is meant to work on, so the region's first tile is usually occupied.
    Handing that tile to the pathfinder produced "native_path_unreachable" and
    the reconstruct blocked at 0% with the worker standing one tile away.

    Order of preference: any free tile inside the region (bounded scan, so a
    huge area cannot stall the scheduler), then a free neighbour expanding
    outwards, then nil so the caller keeps its previous behaviour.
]]
local REGION_SCAN_LIMIT = 24
local function standablePointFromRegion(region)
    local point = pointFromRegion(region)
    if not point then return nil end
    if isStandable(point.x, point.y, point.z) then return point end
    local scanned = 0
    local zKeys = {}
    for z, _ in pairs(region and region.levels or {}) do zKeys[#zKeys + 1] = z end
    table.sort(zKeys)
    for _, z in ipairs(zKeys) do
        local level = region.levels[z]
        local yKeys = {}
        for y, _ in pairs(level.rows or {}) do yKeys[#yKeys + 1] = y end
        table.sort(yKeys)
        for _, y in ipairs(yKeys) do
            local spans = level.rows[y] or {}
            for index = 1, #spans, 2 do
                for x = spans[index], spans[index + 1] do
                    scanned = scanned + 1
                    if scanned > REGION_SCAN_LIMIT then break end
                    if isStandable(x, y, z) then return { x = x, y = y, z = z } end
                end
                if scanned > REGION_SCAN_LIMIT then break end
            end
            if scanned > REGION_SCAN_LIMIT then break end
        end
        if scanned > REGION_SCAN_LIMIT then break end
    end
    for ring = 1, 3 do
        for _, offset in ipairs(EDGE_OFFSETS) do
            local x = point.x + offset.x * ring
            local y = point.y + offset.y * ring
            if isStandable(x, y, point.z) then
                return { x = x, y = y, z = point.z, adjacentToRegion = true }
            end
        end
    end
    return nil
end

function Service.ResolveWorkTarget(facilityOrId)
    local facility = type(facilityOrId) == "table" and facilityOrId
        or Repository.GetFacility(facilityOrId)
    if not facility then return nil, "FACILITY_NOT_FOUND" end
    local componentIds = {}
    for componentId, _ in pairs(facility.componentIds or {}) do
        componentIds[#componentIds + 1] = componentId
    end
    table.sort(componentIds)
    if facilityRequiresWorkZone(facility) then
        -- A labor zone is an explicit standing area for facilities such as
        -- farms. It is never inferred from an unrelated room component.
        for _, componentId in ipairs(componentIds) do
            local component = Repository.GetComponent(componentId)
            if component and component.role == "work.zone" then
                if component.kind == "anchor" then
                    return { x = component.x, y = component.y, z = component.z,
                        componentId = component.id, role = component.role }
                end
                if component.kind == "region" and component.region then
                    local point = standablePointFromRegion(component.region)
                        or pointFromRegion(component.region)
                    if point then
                        point.componentId, point.role = component.id, component.role
                        return point
                    end
                end
            end
        end
    end
    -- Native workstations are the work target when a facility has no
    -- separately configured labor zone. This keeps a forge/table anchor from
    -- being replaced by a room footprint or a stale work-zone component.
    for _, componentId in ipairs(componentIds) do
        local component = Repository.GetComponent(componentId)
        local role = tostring(component and component.role or "")
        if component and component.kind == "anchor"
            and string.sub(role, 1, 5) == "work."
        then
            return { x = component.x, y = component.y, z = component.z,
                componentId = component.id, role = component.role }
        end
    end
    if facilityRequiresWorkZone(facility) then
        -- Farming can still use its plot as a recovery target if an older or
        -- partially-loaded save has not restored the optional labor spot yet.
        for _, componentId in ipairs(componentIds) do
            local component = Repository.GetComponent(componentId)
            if component and component.kind == "region" and component.region then
                local point = pointFromRegion(component.region)
                if point then
                    point.componentId, point.role = component.id, component.role
                    return point
                end
            end
        end
    end
    local point = standablePointFromRegion(facility.constructionRegion)
        or pointFromRegion(facility.constructionRegion)
    if point then
        point.componentId, point.role = "footprint:" .. facility.id,
            "facility.footprint"
        return point
    end
    return nil, "FACILITY_HAS_NO_WORK_TARGET"
end


return Service
