local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Selector = require "PsychopatzCore/UI/World/PsychopatzGridRegionSelector"
local LayoutOverlay = require "PNC/UI/Communities/ColonyManagement/PNC_SettlementLayoutOverlay"

local Support = {}

function Support.Tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

function Support.EmptyRegion() return { levels = {} } end

function Support.BaseRegion(window)
    local geometry = window.snapshot and window.snapshot.settlement
        and window.snapshot.settlement.geometry
    return geometry and geometry.region or Support.EmptyRegion()
end

function Support.FacilityRegion(facility)
    return facility and facility.constructionRegion or Support.EmptyRegion()
end

function Support.WorkZoneRegion(facility)
    local sourceRegion = Support.FacilityRegion(facility)
    -- Older/partial settlement snapshots may carry the component list before
    -- the facility footprint has been copied into the client projection. The
    -- existing work spot is still authoritative enough to keep the editor
    -- usable while the next snapshot repairs the footprint.
    if GridRegion.countTiles(sourceRegion) <= 0 then
        for _, component in ipairs(facility and facility.components or {}) do
            if component.role == "work.zone" and component.region then
                sourceRegion = component.region
                break
            end
        end
    end
    local source = GridRegion.normalize(sourceRegion)
    local levels = {}
    local function add(level, y, first, last)
        levels[level] = levels[level] or { rows = {} }
        local row = levels[level].rows[y] or {}
        row[#row + 1], row[#row + 2] = first, last
        levels[level].rows[y] = row
    end
    for z, level in pairs(source.levels) do
        for y, spans in pairs(level.rows) do
            for index = 1, #spans, 2 do
                local first, last = spans[index], spans[index + 1]
                add(z, y, first - 1, last + 1)
                add(z, y - 1, first, last)
                add(z, y + 1, first, last)
            end
        end
    end
    return GridRegion.normalize({ levels = levels })
end

function Support.Footprint(region)
    local rows = {}
    for _, level in pairs(GridRegion.normalize(region).levels) do
        for y, spans in pairs(level.rows) do
            local row = rows[y] or {}
            rows[y] = row
            local index
            for index = 1, #spans do row[#row + 1] = spans[index] end
        end
    end
    return GridRegion.normalize({ levels = { [0] = { rows = rows } } })
end

function Support.ComponentForRole(facility, role)
    local index
    for index = 1, #(facility and facility.components or {}) do
        local component = facility.components[index]
        if component.role == role then return component end
    end
    return nil
end

function Support.ComponentById(facility, componentId)
    componentId = tostring(componentId or "")
    for index = 1, #(facility and facility.components or {}) do
        local component = facility.components[index]
        if tostring(component.id or "") == componentId then return component end
    end
    return nil
end

function Support.UsedGuideLayers(window, excludedComponentId)
    local settlement = window.snapshot and window.snapshot.settlement or nil
    local layers = LayoutOverlay.BuildLayers(settlement, false)
    local filtered = {}
    local index
    for index = 1, #layers do
        local layer = layers[index]
        if tostring(layer.componentId or "") ~= tostring(excludedComponentId or "") then
            filtered[#filtered + 1] = layer
        end
    end
    return filtered
end

function Support.ApplyLocalResult(window)
    if window and PNC.Core and PNC.Core.IsClientOnly
        and PNC.Core.IsClientOnly() ~= true and window.refresh
    then window:refresh() end
end

function Support.OpenSelector(window, options)
    if type(options) ~= "table" then
        return false, "INVALID_SELECTOR_OPTIONS"
    end
    options.ownerWindow = window
    options.player = getSpecificPlayer(0)
    options.playerNum = 0
    return Selector.Open(options)
end

function Support.ValidateConnected(region)
    if GridRegion.countTiles(region) <= 0 then return false, "EMPTY_REGION" end
    if not GridRegion.isConnected(region, 4) then return false, "BASE_DISCONNECTED" end
    return true
end

return Support
