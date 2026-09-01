local Renderer = PNC.NameplateRenderer
local Internal = Renderer.Internal
local drawWorldLine = Internal.DrawWorldLine
local drawWorldMarker = Internal.DrawWorldMarker
local drawWorldTile = Internal.DrawWorldTile
local drawWorldCircle = Internal.DrawWorldCircle

local CAMP_RESOURCE_COLORS = {
    bed = { r = 0.78, g = 0.42, b = 1.0, a = 0.78 },
    water = { r = 0.22, g = 0.62, b = 1.0, a = 0.78 },
    seating = { r = 0.28, g = 1.0, b = 0.44, a = 0.78 },
    other = { r = 1.0, g = 0.72, b = 0.2, a = 0.78 },
}
local CAMP_RESOURCE_SELECTED_COLOR = { r = 1.0, g = 0.84, b = 0.18, a = 0.98 }
local CAMP_RESOURCE_BLOCKED_COLOR = { r = 1.0, g = 0.2, b = 0.16, a = 0.92 }
local CAMP_RESOURCE_TILE_COLOR = { r = 0.86, g = 0.9, b = 1.0, a = 0.42 }
local CAMP_RADIUS_COLOR = { r = 1.0, g = 0.64, b = 0.16, a = 0.88 }
local CAMP_RESOURCE_RADIUS_COLOR = { r = 0.72, g = 0.78, b = 0.96, a = 0.45 }
local SEATING_COLOR = { r = 0.16, g = 0.92, b = 1.0, a = 0.78 }
local SEATING_SELECTED_COLOR = { r = 1.0, g = 0.82, b = 0.16, a = 0.95 }
local SEATING_SPOT_COLOR = { r = 0.28, g = 1.0, b = 0.44, a = 0.82 }
local SEATING_BLOCKED_COLOR = { r = 1.0, g = 0.22, b = 0.18, a = 0.9 }
local SEATING_TILE_COLOR = { r = 0.2, g = 0.84, b = 1.0, a = 0.32 }

local function campResourcePoint(resource)
    local x = tonumber(resource and resource.x)
    local y = tonumber(resource and resource.y)
    local z = tonumber(resource and resource.z)
    if x == nil and resource and resource.originX ~= nil then
        x = tonumber(resource.originX) + 0.5
    end
    if y == nil and resource and resource.originY ~= nil then
        y = tonumber(resource.originY) + 0.5
    end
    if z == nil and resource then z = tonumber(resource.originZ) end
    if x == nil or y == nil or z == nil then return nil end
    return x, y, z
end

local function campResourceTile(resource)
    local x = tonumber(resource and resource.originX)
    local y = tonumber(resource and resource.originY)
    local z = tonumber(resource and resource.originZ)
    if x == nil or y == nil then
        local pointX, pointY, pointZ = campResourcePoint(resource)
        if pointX == nil then return nil end
        x, y, z = math.floor(pointX), math.floor(pointY), pointZ
    end
    return math.floor(x), math.floor(y), tonumber(z) or 0
end

local function campResourceColor(resource)
    if resource and resource.available == false then
        return CAMP_RESOURCE_BLOCKED_COLOR
    end
    if resource and resource.selected == true then
        return CAMP_RESOURCE_SELECTED_COLOR
    end
    return CAMP_RESOURCE_COLORS[tostring(resource and resource.category or "other")]
        or CAMP_RESOURCE_COLORS.other
end

local function hoveredWorldPoint(manager, x, y, z)
    if type(getMouseX) ~= "function" or type(getMouseY) ~= "function"
        or not isoToScreenX or not isoToScreenY
    then return nil end
    local mouseX = getMouseX() - (tonumber(manager.x) or 0)
    local mouseY = getMouseY() - (tonumber(manager.y) or 0)
    local screenX = isoToScreenX(manager.playerIndex, x, y, z)
        - (tonumber(manager.x) or 0)
    local screenY = isoToScreenY(manager.playerIndex, x, y, z)
        - (tonumber(manager.y) or 0)
    local xStep = math.abs(isoToScreenX(manager.playerIndex, x + 1, y, z)
        - isoToScreenX(manager.playerIndex, x, y, z))
    local yStep = math.abs(isoToScreenX(manager.playerIndex, x, y + 1, z)
        - isoToScreenX(manager.playerIndex, x, y, z))
    local size = math.max(16, 2 * math.max(xStep, yStep))
    local dx = mouseX - screenX
    local dy = mouseY - screenY
    if math.abs(dx) <= math.max(12, size / 2)
        and math.abs(dy) <= math.max(12, size / 2)
    then
        return dx * dx + dy * dy
    end
    return nil
end

local function updateCampResourceHover(manager, resource, hoverState)
    local x, y, z = campResourcePoint(resource)
    if not x then return end
    local distance = hoveredWorldPoint(manager, x, y, z)
    if distance and (not hoverState.distance or distance < hoverState.distance) then
        hoverState.resource = resource
        hoverState.distance = distance
    end
end

local function campResourceJobsText(resource)
    local jobs = resource and resource.supportedJobs or nil
    if type(jobs) == "table" and #jobs > 0 then
        local labels = {}
        for index = 1, #jobs do labels[#labels + 1] = tostring(jobs[index]) end
        return table.concat(labels, ", ")
    end
    return tostring(resource and (resource.capability
        or resource.role or resource.resourceKind) or "unknown")
end

local function drawCampResourceHover(manager, resource)
    if not resource or type(getMouseX) ~= "function"
        or type(getMouseY) ~= "function" or not manager.drawText
    then return end
    local category = tostring(resource.category or "other")
    local state = resource.blocked == true and "BLOCKED"
        or resource.available == false and "RESERVED" or "AVAILABLE"
    local lines = {
        "CAMP RESOURCE: " .. category,
        "jobs: " .. campResourceJobsText(resource),
        "state: " .. state,
        "key: " .. tostring(resource.resourceKey or "-"),
    }
    local width = 190
    for index = 1, #lines do
        width = math.max(width, #lines[index] * 7 + 18)
    end
    local height = #lines * 18 + 10
    local x = getMouseX() - (tonumber(manager.x) or 0) + 14
    local y = getMouseY() - (tonumber(manager.y) or 0) + 14
    local managerWidth = tonumber(manager.width) or 1920
    local managerHeight = tonumber(manager.height) or 1080
    if x + width > managerWidth then x = managerWidth - width - 4 end
    if y + height > managerHeight then y = managerHeight - height - 4 end
    x, y = math.max(4, x), math.max(4, y)
    manager:drawRect(x, y, width, height, 0.88, 0.02, 0.05, 0.07)
    manager:drawRectBorder(x, y, width, height, 0.96,
        CAMP_RESOURCE_TILE_COLOR.r,
        CAMP_RESOURCE_TILE_COLOR.g,
        CAMP_RESOURCE_TILE_COLOR.b)
    for index = 1, #lines do
        manager:drawText(lines[index], x + 8, y + 5 + ((index - 1) * 18),
            1, 1, 1, 1, UIFont and UIFont.Small)
    end
end

local function campDebugKey(camp)
    if tostring(camp and camp.campId or "") ~= "" then
        return tostring(camp.campId)
    end
    local anchor = camp and camp.anchor or {}
    return tostring(anchor.x or "?") .. ":" .. tostring(anchor.y or "?")
        .. ":" .. tostring(anchor.z or "?")
end

local function drawCampResourceDebug(manager, entry, hoverState, drawnCamps)
    local camp = entry.snapshot and (
        entry.snapshot.campResourceDebug
            or entry.snapshot.debugState
            and entry.snapshot.debugState.campResourceDebug
    )
    if type(camp) ~= "table" then return end
    local anchor = camp.anchor
    local campKey = campDebugKey(camp)
    drawnCamps = drawnCamps or {}
    if camp.active == true and type(anchor) == "table"
        and anchor.x and anchor.y and anchor.z
        and not drawnCamps[campKey]
    then
        drawnCamps[campKey] = true
        drawWorldCircle(
            manager,
            anchor.x,
            anchor.y,
            anchor.z,
            camp.campRadius or 3,
            CAMP_RADIUS_COLOR,
            false
        )
        if tonumber(camp.resourceRadius)
            and tonumber(camp.resourceRadius) > tonumber(camp.campRadius or 3)
        then
            drawWorldCircle(
                manager,
                anchor.x,
                anchor.y,
                anchor.z,
                camp.resourceRadius,
                CAMP_RESOURCE_RADIUS_COLOR,
                true
            )
        end
    end
    for index = 1, #(camp.facilities or {}) do
        local resource = camp.facilities[index]
        if type(resource) == "table" then
            local color = campResourceColor(resource)
            local tileX, tileY, tileZ = campResourceTile(resource)
            if tileX ~= nil then
                drawWorldTile(manager, tileX, tileY, tileZ, color)
            end
            local x, y, z = campResourcePoint(resource)
            if x ~= nil then
                drawWorldMarker(manager, x, y, z, color,
                    resource.selected == true and 10 or 6)
                updateCampResourceHover(manager, resource, hoverState)
            end
        end
    end
end

local function drawSeatingDebug(manager, entry)
    local seating = entry.snapshot and (
        entry.snapshot.seatingDebug
            or entry.snapshot.debugState
            and entry.snapshot.debugState.seatingDebug
    )
    if type(seating) ~= "table" then return end
    local facilities = seating.facilities or {}
    for facilityIndex = 1, #facilities do
        local facility = facilities[facilityIndex]
        if type(facility) == "table" then
            local resourceColor = facility.selected == true
                and SEATING_SELECTED_COLOR or facility.available == false
                and SEATING_BLOCKED_COLOR or SEATING_COLOR
            if facility.x and facility.y and facility.z then
                drawWorldMarker(
                    manager,
                    facility.x,
                    facility.y,
                    facility.z,
                    resourceColor,
                    facility.selected == true and 11 or 7
                )
            end
            if facility.originX and facility.originY and facility.originZ then
                -- The resource tile and the SeatingManager anchor are
                -- different things. Draw both for unambiguous diagnostics.
                drawWorldTile(
                    manager,
                    facility.originX,
                    facility.originY,
                    facility.originZ,
                    SEATING_TILE_COLOR
                )
            end
            for spotIndex = 1, #(facility.spots or {}) do
                local spot = facility.spots[spotIndex]
                if type(spot) == "table" and spot.x and spot.y and spot.z then
                    local color = spot.valid == false
                        and SEATING_BLOCKED_COLOR
                        or spot.selected == true
                        and SEATING_SELECTED_COLOR
                        or SEATING_SPOT_COLOR
                    drawWorldTile(manager, spot.x, spot.y, spot.z, color)
                    -- Tile outlines are deliberately aligned to integer tile
                    -- coordinates; this point is the actual sub-tile anchor.
                    drawWorldMarker(manager, spot.x, spot.y, spot.z, color,
                        spot.selected == true and 8 or 4)
                    if facility.x and facility.y and facility.z then
                        drawWorldLine(
                            manager,
                            facility.x,
                            facility.y,
                            facility.z,
                            spot.x,
                            spot.y,
                            spot.z,
                            SEATING_TILE_COLOR
                        )
                    end
                end
            end
        end
    end
    local target = seating.target
    if type(target) == "table" and target.x and target.y and target.z then
        drawWorldMarker(
            manager,
            target.x,
            target.y,
            target.z,
            SEATING_SELECTED_COLOR,
            14
        )
    end
    if type(seating.body) == "table"
        and seating.body.x and seating.body.y and seating.body.z
    then
        drawWorldMarker(
            manager,
            seating.body.x,
            seating.body.y,
            seating.body.z,
            SEATING_BLOCKED_COLOR,
            9
        )
        if type(target) == "table" and target.x and target.y and target.z then
            drawWorldLine(
                manager,
                seating.body.x,
                seating.body.y,
                seating.body.z,
                target.x,
                target.y,
                target.z,
                SEATING_BLOCKED_COLOR
            )
        end
    end
    if type(seating.anchor) == "table"
        and seating.anchor.x and seating.anchor.y and seating.anchor.z
    then
        drawWorldMarker(
            manager,
            seating.anchor.x,
            seating.anchor.y,
            seating.anchor.z,
            SEATING_SELECTED_COLOR,
            10
        )
    end
end

Renderer.RenderSeatingDebug = drawSeatingDebug
Renderer.RenderCampResourceDebug = drawCampResourceDebug
Renderer.DrawCampResourceHover = drawCampResourceHover

return Renderer
