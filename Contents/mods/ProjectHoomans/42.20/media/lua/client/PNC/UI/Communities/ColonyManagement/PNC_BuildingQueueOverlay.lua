PNC = PNC or {}
PNC.BuildingQueueOverlay = PNC.BuildingQueueOverlay or {}

local Overlay = PNC.BuildingQueueOverlay
local Catalog = PNC.BuildRecipeCatalog

Overlay.enabled = Overlay.enabled == true
Overlay.queue = Overlay.queue or {}
Overlay.ghosts = Overlay.ghosts or {}
Overlay.drawer = Overlay.drawer or nil
Overlay.eventsInstalled = Overlay.eventsInstalled == true

local COLORS = {
    queued = { r = 1.00, g = 0.68, b = 0.12, a = 0.30 },
    working = { r = 0.20, g = 0.82, b = 1.00, a = 0.30 },
    blocked = { r = 1.00, g = 0.20, b = 0.12, a = 0.34 },
}

local function active(order)
    local status = tostring(order and order.status or "")
    return status ~= "COMPLETED" and status ~= "CANCELLED"
        and status ~= "FAILED"
end

local function blueprintFor(order)
    return order and order.blueprint or nil
end

local function pointFor(order)
    local blueprint = blueprintFor(order)
    if not blueprint then return nil end
    local x, y, z = tonumber(blueprint.x), tonumber(blueprint.y),
        tonumber(blueprint.z)
    if not x or not y or not z then return nil end
    return { x = math.floor(x), y = math.floor(y), z = math.floor(z) }
end

local function statusColor(order)
    if order and order.blockedReason then return COLORS.blocked end
    if tostring(order and order.status or "") == "WORKING" then
        return COLORS.working
    end
    return COLORS.queued
end

local function orderKey(order)
    return tostring(order and order.id or "")
end

local function loadBuildingCursorBase()
    if not ISBaseObject then pcall(require, "ISBaseObject") end
    if not ISBuildingObject then
        pcall(require, "BuildingObjects/ISBuildingObject")
    end
    if not ISBuildIsoEntity then
        pcall(require, "BuildingObjects/ISBuildIsoEntity")
    end
end

local function nativeInfoFor(order)
    local blueprint = blueprintFor(order)
    local objectInfoName = blueprint and blueprint.objectInfoName or nil
    if not objectInfoName then return nil end
    local descriptor = Catalog and Catalog.Get
        and Catalog.Get(objectInfoName) or nil
    local info = descriptor and descriptor.nativeObjectInfo or nil
    if not info and SpriteConfigManager
        and SpriteConfigManager.GetObjectInfo
    then
        local ok, resolved = pcall(SpriteConfigManager.GetObjectInfo,
            objectInfoName)
        info = ok and resolved or nil
    end
    return info
end

local function buildGhost(order, character)
    loadBuildingCursorBase()
    if not ISBuildIsoEntity or not character then return nil end
    local info = nativeInfoFor(order)
    if not info then return nil end
    local blueprint = blueprintFor(order) or {}
    local nSprite = math.max(1, math.min(4, math.floor(
        tonumber(blueprint.nSprite) or 1)))
    local key = tostring(blueprint.objectInfoName or "") .. ":" .. tostring(nSprite)
    local cached = Overlay.ghosts[orderKey(order)]
    if cached and cached.key == key and cached.character == character then
        return cached.cursor
    end
    local ok, cursor = pcall(ISBuildIsoEntity.new, ISBuildIsoEntity,
        character, info, nSprite, nil, nil)
    if not ok or not cursor then return nil end
    cursor.player = character.getPlayerNum and character:getPlayerNum() or 0
    cursor.haveMaterial = function() return true end
    cursor.skipBuildAction = true
    cursor.dragNilAfterPlace = false
    Overlay.ghosts[orderKey(order)] = {
        key = key, character = character, cursor = cursor,
    }
    return cursor
end

local function drawerFor(playerNum)
    if not ISUIElement or not ISUIElement.new
        or not getPlayerScreenLeft or not getPlayerScreenTop
    then return nil end
    local x, y = getPlayerScreenLeft(playerNum), getPlayerScreenTop(playerNum)
    local width, height = getPlayerScreenWidth(playerNum),
        getPlayerScreenHeight(playerNum)
    local drawer = Overlay.drawer
    if not drawer then
        drawer = ISUIElement:new(x, y, width, height)
        if drawer.initialise then drawer:initialise() end
        drawer:setCapture(false)
        Overlay.drawer = drawer
    else
        drawer:setX(x); drawer:setY(y)
        drawer:setWidth(width); drawer:setHeight(height)
    end
    return drawer
end

local function labelFor(order)
    local name = tostring(order and order.displayName
        or order and order.objectInfoName or "BUILD")
    local percent = math.floor(tonumber(order and order.percent) or 0)
    local state = order and order.blockedReason
        or order and order.status or "QUEUED"
    return name .. "  " .. tostring(percent) .. "%  " .. tostring(state)
end

local function drawLabel(drawer, playerNum, order, point)
    if not drawer or not drawer.drawText or not isoToScreenX
        or not isoToScreenY
    then return end
    local screenX = isoToScreenX(playerNum, point.x + 0.5,
        point.y + 0.5, point.z) - drawer.x
    local screenY = isoToScreenY(playerNum, point.x + 0.5,
        point.y + 0.5, point.z) - drawer.y
    local text = labelFor(order)
    local width = math.max(120, #text * 7 + 14)
    local x = math.max(4, math.min(drawer.width - width - 4,
        screenX - width / 2))
    local y = math.max(4, screenY - 34)
    if drawer.drawRect then
        local color = statusColor(order)
        drawer:drawRect(x, y, width, 22, 0.88,
            color.r * 0.12, color.g * 0.12, color.b * 0.12)
    end
    if drawer.drawRectBorder then
        local color = statusColor(order)
        drawer:drawRectBorder(x, y, width, 22, 0.92,
            color.r, color.g, color.b)
    end
    drawer:drawText(text, x + 7, y + 4, 1, 1, 1, 1,
        UIFont and UIFont.Small)
end

function Overlay.SetQueue(queue)
    local nextQueue = {}
    local live = {}
    for _, order in ipairs(queue or {}) do
        if active(order) and pointFor(order) then
            nextQueue[#nextQueue + 1] = order
            live[orderKey(order)] = true
        end
    end
    Overlay.queue = nextQueue
    for key, _ in pairs(Overlay.ghosts) do
        if not live[key] then Overlay.ghosts[key] = nil end
    end
end

function Overlay.SetEnabled(enabled)
    Overlay.enabled = enabled == true
    return Overlay.enabled
end

function Overlay.Toggle(queue)
    if queue then Overlay.SetQueue(queue) end
    return Overlay.SetEnabled(not Overlay.enabled)
end

function Overlay.IsEnabled()
    return Overlay.enabled == true
end

function Overlay.Render()
    if not Overlay.enabled or not addAreaHighlightForPlayer then return end
    local character = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not character then return end
    local playerNum = character.getPlayerNum and character:getPlayerNum() or 0
    local drawer = drawerFor(playerNum)
    for _, order in ipairs(Overlay.queue or {}) do
        local point = pointFor(order)
        if point then
            local color = statusColor(order)
            addAreaHighlightForPlayer(playerNum, point.x, point.y,
                point.x + 1, point.y + 1, point.z,
                color.r, color.g, color.b, color.a)
            local cursor = buildGhost(order, character)
            if cursor and cursor.render and getCell then
                local square = getCell():getGridSquare(
                    point.x, point.y, point.z)
                pcall(cursor.render, cursor, point.x, point.y, point.z, square)
            end
            drawLabel(drawer, playerNum, order, point)
        end
    end
end

function Overlay.Reset()
    Overlay.enabled = false
    Overlay.queue = {}
    Overlay.ghosts = {}
end

if not Overlay.eventsInstalled then
    local Events = require "PsychopatzCore/Events/PC_EventBus"
    if Events and Events.OnPreUIDraw then
        Events.OnPreUIDraw.Add(Overlay.Render)
    end
    if Events and Events.OnMainMenuEnter then
        Events.OnMainMenuEnter.Add(Overlay.Reset)
    end
    Overlay.eventsInstalled = true
end

return Overlay
