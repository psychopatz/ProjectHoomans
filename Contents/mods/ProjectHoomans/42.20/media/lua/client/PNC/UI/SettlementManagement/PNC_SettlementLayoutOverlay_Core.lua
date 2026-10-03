local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Footprint = require "PNC/Core/Settlement/PNC_BuildingFootprint"
local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"

PNC = PNC or {}
PNC.SettlementLayoutOverlay = PNC.SettlementLayoutOverlay or {}

local Overlay = PNC.SettlementLayoutOverlay
Overlay.enabled = Overlay.enabled == true
Overlay.layers = Overlay.layers or {}
Overlay.markers = Overlay.markers or {}

local function settlementKey(settlement)
    return tostring(settlement and settlement.id or "") .. ":"
        .. tostring(settlement and settlement.revision or "")
end

local COLORS = {
    -- Territory is context only. Keep it visible without washing out rooms,
    -- construction state, or point components above it.
    base = { r = 0.10, g = 0.70, b = 1.00, a = 0.025 },
    bedroom = { r = 0.72, g = 0.38, b = 1.00, a = 0.22 },
    barracks = { r = 0.72, g = 0.38, b = 1.00, a = 0.22 },
    farm = { r = 0.22, g = 0.92, b = 0.28, a = 0.22 },
    research_facility = { r = 0.16, g = 0.72, b = 1.00, a = 0.22 },
    facility = { r = 1.00, g = 0.58, b = 0.15, a = 0.22 },
    -- Ground spots must identify the work location without hiding the native
    -- workstation sprite underneath them.
    workZone = { r = 0.18, g = 0.95, b = 0.82, a = 0.24 },
    anchor = { r = 1.00, g = 0.82, b = 0.25, a = 0.18 },
    stockpile = { r = 0.95, g = 0.82, b = 0.10, a = 0.20 },
    construction = { r = 1.00, g = 0.54, b = 0.08, a = 0.20 },
    deconstruction = { r = 1.00, g = 0.18, b = 0.12, a = 0.18 },
}
Overlay.ZoneColors = COLORS

local function facilityColor(facility, color)
    local state = FacilityState.DisplayState(facility)
    if state == "UNDER_CONSTRUCTION" or state == "RECONSTRUCTING" then
        return COLORS.construction
    end
    if state == "DECONSTRUCTING" then return COLORS.deconstruction end
    if state == "PLANNED" then
        return { r = color.r * 0.65, g = color.g * 0.65,
            b = color.b * 0.65, a = 0.08 }
    end
    -- Completed building/room areas stay deliberately dark so beds, stations,
    -- stockpile nodes, and other anchor components remain visually dominant.
    return { r = color.r * 0.45, g = color.g * 0.45,
        b = color.b * 0.45, a = 0.08 }
end

local function facilityDefinition(facility)
    return PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.Get
        and PNC.FacilityDefinitions.Get(facility and facility.definitionId)
        or nil
end

local function facilityZoneEnabled(facility)
    if facility and facility.zoneOverlay ~= nil then
        return facility.zoneOverlay == true
    end
    local definition = facilityDefinition(facility)
    return definition and definition.zoneOverlay == true
end

local function facilityWorkZoneEnabled(facility)
    if facility and facility.workZoneEnabled ~= nil then
        return facility.workZoneEnabled == true
    end
    local definition = facilityDefinition(facility)
    if PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.RequiresWorkZone
    then
        return PNC.FacilityDefinitions.RequiresWorkZone(
            facility and facility.definitionId, facility and facility.level) == true
    end
    return definition and definition.requiresWorkZone == true or false
end

local function facilityZoneColor(facility, color)
    local state = FacilityState.DisplayState(facility)
    if state == "UNDER_CONSTRUCTION" or state == "RECONSTRUCTING" then
        return COLORS.construction
    end
    if state == "DECONSTRUCTING" then return COLORS.deconstruction end
    if state == "PLANNED" then
        return { r = color.r * 0.80, g = color.g * 0.80,
            b = color.b * 0.80, a = 0.16 }
    end
    -- Zone-backed facilities need a readable persistent tint. Component
    -- layers remain darker/hoverable; this is the room's primary identity.
    return { r = color.r * 0.75, g = color.g * 0.75,
        b = color.b * 0.75, a = 0.16 }
end

local function facilitySourceColor(facility)
    local definition = facilityDefinition(facility)
    local colorKey = facility and facility.zoneColor
        or definition and definition.zoneColor
        or facility and facility.definitionId
        or "facility"
    return COLORS[tostring(colorKey)] or COLORS.facility
end

local function regionCenter(region)
    local count, sumX, sumY, sumZ = 0, 0, 0, 0
    for z, level in pairs(region and region.levels or {}) do
        for y, spans in pairs(level.rows or {}) do
            local index
            for index = 1, #spans, 2 do
                local first = tonumber(spans[index]) or 0
                local last = tonumber(spans[index + 1]) or first
                local width = math.max(0, last - first + 1)
                count = count + width
                sumX = sumX + ((first + last) * width / 2)
                sumY = sumY + (tonumber(y) or 0) * width
                sumZ = sumZ + (tonumber(z) or 0) * width
            end
        end
    end
    if count <= 0 then return nil end
    return { x = sumX / count + 0.5, y = sumY / count + 0.5,
        z = sumZ / count }
end

local function addMarker(markers, point, kind, id, role, tileScale)
    if not point then return end
    markers[#markers + 1] = {
        x = point.x, y = point.y, z = point.z,
        kind = kind, id = id, role = role,
        tileScale = tileScale or 1,
    }
end

local function fallbackName(value)
    local text = tostring(value or "")
    text = string.gsub(text, "[_%.%-]+", " ")
    -- Kahlua's gsub callback can pass a missing second capture for an empty
    -- match. Keep this formatter deliberately simple and callback-free.
    local first = string.sub(text, 1, 1)
    if first ~= "" then
        text = string.upper(first) .. string.sub(text, 2)
    end
    return text ~= "" and text or "Facility"
end

local function localizedName(key, fallback)
    local value = type(key) == "string" and key ~= ""
        and getText and PNC.Translation.GetKey(key) or nil
    if value and value ~= key and value ~= "" then return value end
    return fallback
end

local function facilityName(facility)
    local dynamic = localizedName(facility and facility.roomLabelKey, nil)
    if dynamic then return dynamic end
    local definition = PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.Get
        and PNC.FacilityDefinitions.Get(facility and facility.definitionId)
        or nil
    return localizedName(definition and definition.displayNameKey,
        fallbackName(facility and facility.definitionId))
end

local function facilityLabel(facility, ordinal, total)
    local label = facilityName(facility)
    if tostring(facility and facility.definitionId or "") == "stockpile" then
        local level = math.max(1, math.floor(tonumber(facility.level) or 1))
        local levelLabel = localizedName("UI_PNC_Facility_LevelShort", "Lv")
        label = label .. " " .. levelLabel .. " " .. tostring(level)
    end
    if tonumber(total) and tonumber(total) > 1 then
        return label .. " #" .. tostring(ordinal or 1)
    end
    return label
end

local function componentName(facility, component, ordinal, ownerLabel)
    local role = tostring(component and component.role or "")
    if role == "work.zone" then
        local label = localizedName("UI_PNC_Overlay_WorkZone",
            "Worker Standing Area")
        return label .. " - " .. (ownerLabel or facilityName(facility))
    end
    if component and component.kind == "region"
        or role == "facility.footprint"
    then
        return ownerLabel or facilityName(facility)
    end
    local labels = {
        ["sleep.bed"] = "Bed",
        ["living.chair"] = "Chair",
        ["dining.table"] = "Dining Table",
        ["health.bed"] = "Hospital Bed",
        ["growing.plot"] = "Growing Plot",
        ["work.research"] = "Research Table",
        ["work.blueprint"] = "Research Table",
        ["work.reverse"] = "Research Table",
        ["work.craft"] = "Craft Station",
        ["work.disassemble"] = "Disassembly Station",
        ["stockpile.access"] = "Storage Stockpile",
    }
    local label = localizedName("UI_PNC_Overlay_Component_" ..
        string.gsub(role, "[^%w]", "_"), labels[role] or fallbackName(role))
    if role == "sleep.bed" or role == "living.chair"
        or role == "dining.table" or role == "health.bed"
    then
        return label .. " #" .. tostring(ordinal or 1)
    end
    return label
end

local function isDirectWorkstation(facility)
    local definition = facilityDefinition(facility)
    return definition and definition.directWorkstation == true
end

local function pointRegion(x, y, z)
    x = math.floor(tonumber(x) or 0)
    y = math.floor(tonumber(y) or 0)
    z = math.floor(tonumber(z) or 0)
    return GridRegion.normalize({ levels = {
        [z] = { rows = { [y] = { x, x } } },
    } })
end

local function workstationApproachEnabled(facility, component)
    if not isDirectWorkstation(facility)
        or not component or component.managedByFacility ~= true
    then
        return false
    end
    local definition = facilityDefinition(facility)
    return component.targetResolver == "workstationEdge"
        or definition and definition.workstationApproach == true
end

local function workstationApproachPoint(facility, component)
    if not workstationApproachEnabled(facility, component) then return nil end
    local saved = component.approachTarget
    if type(saved) == "table" and tonumber(saved.x)
        and tonumber(saved.y) and tonumber(saved.z)
    then
        return { x = tonumber(saved.x), y = tonumber(saved.y),
            z = tonumber(saved.z) }
    end
    local occupied = component.occupiedRegion
        or pointRegion(component.x, component.y, component.z)
    local offsets = {
        { x = 0, y = 1, order = 1 }, { x = 1, y = 0, order = 2 },
        { x = 0, y = -1, order = 3 }, { x = -1, y = 0, order = 4 },
    }
    local candidates = {}
    local anchorX = (tonumber(component.x) or 0) + 0.5
    local anchorY = (tonumber(component.y) or 0) + 0.5
    Footprint.ForEachTile(occupied, function(sourceX, sourceY, sourceZ)
        for _, offset in ipairs(offsets) do
            local x, y = sourceX + offset.x, sourceY + offset.y
            if not GridRegion.containsPoint(occupied, x, y, sourceZ) then
                local pointX, pointY = x + 0.5, y + 0.5
                candidates[#candidates + 1] = {
                    x = pointX, y = pointY, z = sourceZ,
                    distance = (pointX - anchorX) * (pointX - anchorX)
                        + (pointY - anchorY) * (pointY - anchorY),
                    order = offset.order,
                    key = tostring(x) .. ":" .. tostring(y) .. ":"
                        .. tostring(sourceZ),
                }
            end
        end
        return true
    end)
    table.sort(candidates, function(left, right)
        if left.distance ~= right.distance then
            return left.distance < right.distance
        end
        if left.order ~= right.order then return left.order < right.order end
        return left.key < right.key
    end)
    return candidates[1]
end

local function addLayer(layers, region, color, kind, id, role, componentId,
    hoverOnly)
    if region and GridRegion.countTiles(region) > 0 then
        layers[#layers + 1] = { region = GridRegion.normalize(region),
            color = color, kind = kind, id = id, role = role,
            componentId = componentId, hoverOnly = hoverOnly == true }
    end
end


Overlay.Internal = Overlay.Internal or {}
local Internal = Overlay.Internal
Internal.settlementKey = settlementKey
Internal.facilityColor = facilityColor
Internal.facilityZoneColor = facilityZoneColor
Internal.facilitySourceColor = facilitySourceColor
Internal.facilityZoneEnabled = facilityZoneEnabled
Internal.facilityWorkZoneEnabled = facilityWorkZoneEnabled
Internal.regionCenter = regionCenter
Internal.addMarker = addMarker
Internal.facilityLabel = facilityLabel
Internal.componentName = componentName
Internal.isDirectWorkstation = isDirectWorkstation
Internal.pointRegion = pointRegion
Internal.workstationApproachPoint = workstationApproachPoint
Internal.addLayer = addLayer

return Overlay
