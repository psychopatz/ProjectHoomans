local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

PNC = PNC or {}
PNC.SettlementLayoutOverlay = PNC.SettlementLayoutOverlay or {}

local Overlay = PNC.SettlementLayoutOverlay
Overlay.enabled = Overlay.enabled == true
Overlay.layers = Overlay.layers or {}
Overlay.markers = Overlay.markers or {}

local COLORS = {
    -- Territory is context only. Keep it visible without washing out rooms,
    -- construction state, or point components above it.
    base = { r = 0.10, g = 0.70, b = 1.00, a = 0.025 },
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

local function facilityColor(facility, color)
    local state = tostring(facility.constructionState
        or facility.cachedState or "BUILT")
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
        and getText and getText(key) or nil
    if value and value ~= key and value ~= "" then return value end
    return fallback
end

local function facilityName(facility)
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
        return ownerLabel or facilityName(facility)
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
        ["work.research"] = "Research Station",
        ["work.blueprint"] = "Architect Bench",
        ["work.reverse"] = "Laboratory",
        ["work.craft"] = "Craft Station",
        ["work.disassemble"] = "Disassembly Station",
        ["water.spigot"] = "Spigot",
        ["water.tank"] = "Water Tank",
        ["water.catcher"] = "Rain Catcher",
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
    local definition = PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.Get
        and PNC.FacilityDefinitions.Get(facility and facility.definitionId)
        or nil
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

local function addLayer(layers, region, color, kind, id, role, componentId,
    hoverOnly)
    if region and GridRegion.countTiles(region) > 0 then
        layers[#layers + 1] = { region = GridRegion.normalize(region),
            color = color, kind = kind, id = id, role = role,
            componentId = componentId, hoverOnly = hoverOnly == true }
    end
end

function Overlay.BuildLayers(settlement, includeBase)
    local layers = {}
    if includeBase ~= false then
        addLayer(layers, settlement and settlement.geometry
            and settlement.geometry.region, COLORS.base, "base",
            settlement and settlement.id)
    end
    for _, facility in ipairs(settlement and settlement.facilities or {}) do
        local sourceColor = COLORS[facility.definitionId] or COLORS.facility
        local color = facilityColor(facility, sourceColor)
        local directWorkstation = isDirectWorkstation(facility)
        local hasRegion = false
        for _, component in ipairs(facility.components or {}) do
            if component.kind == "region" then hasRegion = true end
            local region = component.kind == "region" and component.region
                or pointRegion(component.x, component.y, component.z)
            local workZone = component.role == "work.zone"
            local componentColor = workZone and COLORS.workZone
                or component.kind == "anchor" and COLORS.anchor or color
            local layerKind = workZone and "work_zone"
                or directWorkstation and component.kind == "anchor"
                and "workstation" or "facility"
            addLayer(layers, region, componentColor, layerKind,
                facility.id, component.role, component.id,
                component.kind == "region" and not workZone)
        end
        -- Direct workstations have a one-tile construction footprint only so
        -- collision/revision infrastructure can remain shared. It is not a
        -- room and must not become a room-zone overlay or room marker.
        if not hasRegion and not directWorkstation then
            addLayer(layers, facility.constructionRegion, color,
                "facility", facility.id, "facility.footprint",
                "footprint:" .. tostring(facility.id))
        end
    end
    for _, node in ipairs(settlement and settlement.stockpileNodes or {}) do
        addLayer(layers, pointRegion(node.x, node.y, node.z),
            COLORS.stockpile, "stockpile", node.id, "stockpile.access")
    end
    return layers
end

function Overlay.BuildMarkers(settlement)
    local markers = {}
    local totals, seen = {}, {}
    for _, facility in ipairs(settlement and settlement.facilities or {}) do
        local key = tostring(facility.definitionId or "")
        totals[key] = (totals[key] or 0) + 1
    end
    for _, facility in ipairs(settlement and settlement.facilities or {}) do
        local definitionKey = tostring(facility.definitionId or "")
        seen[definitionKey] = (seen[definitionKey] or 0) + 1
        local label = facilityLabel(facility, seen[definitionKey],
            totals[definitionKey])
        local hasRoom = false
        local hasWorkZone = false
        local directWorkstation = isDirectWorkstation(facility)
        local ordinals = {}
        for _, component in ipairs(facility.components or {}) do
            local role = tostring(component.role or "")
            ordinals[role] = (ordinals[role] or 0) + 1
            if role == "work.zone" then
                hasWorkZone = true
                local point = component.kind == "region"
                    and regionCenter(component.region)
                    or { x = (tonumber(component.x) or 0) + 0.5,
                        y = (tonumber(component.y) or 0) + 0.5,
                        z = tonumber(component.z) or 0 }
                addMarker(markers, point, "work_zone", component.id,
                    component.role, 1)
                if markers[#markers] then markers[#markers].label = label end
            elseif component.kind == "region" then
                hasRoom = true
                addMarker(markers, regionCenter(component.region), "room",
                    facility.id, component.role, 1)
                if markers[#markers] then
                    markers[#markers].label = componentName(facility,
                        component, nil, label)
                end
            elseif component.kind == "anchor" then
                local workstationMarker = directWorkstation
                    and component.managedByFacility == true
                addMarker(markers, {
                    x = (tonumber(component.x) or 0) + 0.5,
                    y = (tonumber(component.y) or 0) + 0.5,
                    z = tonumber(component.z) or 0,
                }, workstationMarker and "workstation" or "component",
                    component.id, component.role, 1)
                markers[#markers].label = workstationMarker
                    and label
                    or componentName(facility, component, ordinals[role])
            end
        end
        if not hasRoom and not directWorkstation and not hasWorkZone then
            addMarker(markers, regionCenter(facility.constructionRegion),
                "room", facility.id, "facility.footprint", 1)
            if markers[#markers] then markers[#markers].label = label end
        end
    end
    for _, node in ipairs(settlement and settlement.stockpileNodes or {}) do
        addMarker(markers, {
            x = (tonumber(node.x) or 0) + 0.5,
            y = (tonumber(node.y) or 0) + 0.5,
            z = tonumber(node.z) or 0,
        }, "component", node.id, "stockpile.access", 1)
        markers[#markers].label = componentName(nil, {
            role = "stockpile.access", kind = "anchor",
        }, 1)
    end
    return markers
end

function Overlay.SetSettlement(settlement)
    Overlay.settlementId = settlement and settlement.id or nil
    Overlay.revision = settlement and settlement.revision or nil
    Overlay.layers = Overlay.BuildLayers(settlement, true)
    Overlay.markers = Overlay.BuildMarkers(settlement)
end

function Overlay.SetEnabled(enabled)
    Overlay.enabled = enabled == true
    return Overlay.enabled
end

function Overlay.Toggle(settlement)
    if settlement then Overlay.SetSettlement(settlement) end
    return Overlay.SetEnabled(not Overlay.enabled)
end

function Overlay.IsEnabled()
    return Overlay.enabled == true
end

local function iconDrawer(playerNum)
    if not ISUIElement or not ISUIElement.new
        or not getPlayerScreenLeft or not getPlayerScreenTop
    then return nil end
    local x, y = getPlayerScreenLeft(playerNum), getPlayerScreenTop(playerNum)
    local width = getPlayerScreenWidth(playerNum)
    local height = getPlayerScreenHeight(playerNum)
    local drawer = Overlay.iconDrawer
    if not drawer then
        drawer = ISUIElement:new(x, y, width, height)
        if drawer.initialise then drawer:initialise() end
        drawer:setCapture(false)
        Overlay.iconDrawer = drawer
    else
        drawer:setX(x); drawer:setY(y)
        drawer:setWidth(width); drawer:setHeight(height)
    end
    return drawer
end

local function renderMarkers(playerNum)
    if not isoToScreenX or not isoToScreenY then return end
    local drawer = iconDrawer(playerNum)
    if not drawer then return end
    local mouseX = getMouseX and getMouseX() or nil
    local mouseY = getMouseY and getMouseY() or nil
    if mouseX ~= nil then mouseX = mouseX - drawer.x end
    if mouseY ~= nil then mouseY = mouseY - drawer.y end
    local hovered, hoveredDistance
    for _, marker in ipairs(Overlay.markers or {}) do
        marker.hovered = false
        if mouseX ~= nil and mouseY ~= nil then
            local screenX = isoToScreenX(playerNum,
                marker.x, marker.y, marker.z) - drawer.x
            local screenY = isoToScreenY(playerNum,
                marker.x, marker.y, marker.z) - drawer.y
            local xStep = math.abs(isoToScreenX(playerNum,
                marker.x + 1, marker.y, marker.z)
                - isoToScreenX(playerNum, marker.x, marker.y, marker.z))
            local yStep = math.abs(isoToScreenX(playerNum,
                marker.x, marker.y + 1, marker.z)
                - isoToScreenX(playerNum, marker.x, marker.y, marker.z))
            local tileWidth = math.max(16, 2 * math.max(xStep, yStep))
            local size = tileWidth * (tonumber(marker.tileScale) or 1)
            local dx = mouseX ~= nil and mouseX - screenX or nil
            local dy = mouseY ~= nil and mouseY - screenY or nil
            local distance = dx and dy and dx * dx + dy * dy or nil
            local hit = distance and math.abs(dx) <= math.max(12, size / 2)
                and math.abs(dy) <= math.max(12, size / 2)
            if hit and (not hoveredDistance or distance < hoveredDistance) then
                hovered, hoveredDistance = marker, distance
            end
        end
    end
    if hovered then hovered.hovered = true end
    Overlay.hoveredMarker = hovered
    return hovered, drawer
end

local function drawHoverLabel(drawer, marker)
    local label = marker and tostring(marker.label or "") or ""
    if label == "" or not drawer or not drawer.drawText then return end
    local mouseX = getMouseX and getMouseX() or drawer.x + 12
    local mouseY = getMouseY and getMouseY() or drawer.y + 12
    local x = mouseX - drawer.x + 12
    local y = mouseY - drawer.y + 12
    local width = math.max(86, #label * 7 + 18)
    local height = 24
    if x + width > drawer.width then x = drawer.width - width end
    if y + height > drawer.height then y = drawer.height - height end
    x, y = math.max(4, x), math.max(4, y)
    if drawer.drawRect then drawer:drawRect(x, y, width, height, 0.86, 0.02, 0.05, 0.07) end
    if drawer.drawRectBorder then
        drawer:drawRectBorder(x, y, width, height, 0.95, 0.24, 0.72, 0.95)
    end
    drawer:drawText(label, x + 8, y + 5, 1, 1, 1, 1, UIFont and UIFont.Small)
end

function Overlay.Render()
    if not Overlay.enabled or not addAreaHighlightForPlayer then return end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player then return end
    local playerNum = player.getPlayerNum and player:getPlayerNum() or 0
    local hovered = renderMarkers(playerNum)
    for _, layer in ipairs(Overlay.layers or {}) do
        local visible = not layer.hoverOnly
        if not visible and hovered then
            visible = layer.id == hovered.id
                and (not layer.componentId or layer.componentId == hovered.id
                    or hovered.kind == "room")
        end
        if visible then
        for z, level in pairs(layer.region.levels or {}) do
            for y, spans in pairs(level.rows or {}) do
                local index
                for index = 1, #spans, 2 do
                    local color = layer.color
                    addAreaHighlightForPlayer(playerNum, spans[index], y,
                        spans[index + 1] + 1, y + 1, z,
                        color.r, color.g, color.b, color.a)
                end
            end
        end
        end
    end
    if hovered then
        local drawer = Overlay.iconDrawer
        drawHoverLabel(drawer, hovered)
    end
end

function Overlay.Reset()
    Overlay.enabled = false
    Overlay.layers = {}
    Overlay.markers = {}
    Overlay.hoveredMarker = nil
    Overlay.settlementId = nil
    Overlay.revision = nil
end

if Overlay.eventsInstalled ~= true then
    if Events and Events.OnPreUIDraw then Events.OnPreUIDraw.Add(Overlay.Render) end
    if Events and Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(Overlay.Reset) end
    Overlay.eventsInstalled = true
end

return Overlay
