-- Client-only orchestration for the perception debug overlay.  Rendering
-- primitives live beside this module so future perception layers can reuse
-- them without coupling their state to this overlay.
PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}

local Overlay = PNC.PerceptionDebug.Overlay or {}
PNC.PerceptionDebug.Overlay = Overlay

local Settings = PNC.PerceptionDebug.Settings
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Settings"
local Model = PNC.PerceptionDebug.Model
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Model"
local Perception = PNC.Perception and PNC.Perception.WorldObjects
    or require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception"
local Primitives = PNC.PerceptionDebug.OverlayPrimitives
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_OverlayPrimitives"

Overlay.VERSION = 1
Overlay.eventsInstalled = Overlay.eventsInstalled == true
-- This is intentionally runtime-only.  It must not share the persistent
-- nameplate `enabled` setting and it must never be restored on startup.
Overlay.enabled = false
Overlay.drawer = Overlay.drawer
Overlay.hovered = nil
Overlay.hoveredZone = nil
Overlay.snapshot = nil
Overlay.visibleObjects = {}
Overlay.settings = nil
Overlay.settingsRevision = nil
Overlay.settingsKey = nil
Overlay.renderPlan = nil
Overlay.renderPlanSnapshot = nil
Overlay.renderPlanSettingsKey = nil
Overlay.hoverKey = nil
Overlay.hoverPlan = nil
Overlay.tooltipKey = nil
Overlay.tooltipObject = nil
Overlay.tooltipLines = nil
Overlay.tooltipWidth = nil
-- Area highlights are native per-frame quads. Keep the visual debug budget
-- separate from the perception snapshot budget so the dashboard can still
-- inspect every recognized object without flooding the renderer.
Overlay.MAX_RENDER_OBJECTS = 32
Overlay.MAX_RENDER_ZONES = 8

local COLORS = {
    generic = { r = 0.78, g = 0.84, b = 0.92, a = 0.70 },
    semantic = { r = 0.32, g = 0.70, b = 1.00, a = 0.76 },
    sitting = { r = 0.24, g = 1.00, b = 0.46, a = 0.84 },
    sleeping = { r = 0.80, g = 0.42, b = 1.00, a = 0.84 },
    water = { r = 0.18, g = 0.66, b = 1.00, a = 0.82 },
    depleted = { r = 1.00, g = 0.62, b = 0.16, a = 0.78 },
    unsafe = { r = 1.00, g = 0.20, b = 0.16, a = 0.86 },
    job = { r = 1.00, g = 0.82, b = 0.24, a = 0.82 },
    room = { r = 0.38, g = 0.76, b = 1.00, a = 0.25 },
    campfire = { r = 1.00, g = 0.54, b = 0.12, a = 0.86 },
    selected = { r = 1.00, g = 0.86, b = 0.18, a = 0.96 },
}

local function playerFor()
    if type(getSpecificPlayer) ~= "function" then return nil end
    local ok, player = pcall(getSpecificPlayer, 0)
    return ok and player or nil
end

local function playerNum(player)
    if not player or type(player.getPlayerNum) ~= "function" then return 0 end
    local ok, value = pcall(player.getPlayerNum, player)
    return ok and tonumber(value) or 0
end

local function hasValues(values)
    return type(values) == "table" and #values > 0
end

local function objectColor(object, settings)
    settings = type(settings) == "table" and settings or {}
    local facts = object and object.facts or {}
    if facts.waterDetected and settings.showWater ~= false then
        if facts.waterState == "UNSAFE" then return COLORS.unsafe end
        if facts.waterState == "DEPLETED" then return COLORS.depleted end
        if facts.waterState == "ACTIVE" then return COLORS.water end
    end
    if facts.validSleeping and settings.showSleeping ~= false then
        return COLORS.sleeping
    end
    if facts.validSitting and settings.showSitting ~= false then
        return COLORS.sitting
    end
    if facts.isCampfire and settings.showCampZones ~= false then
        return COLORS.campfire
    end
    if (facts.semanticName or facts.commandName)
        and settings.showSemanticNames ~= false
    then
        return COLORS.semantic
    end
    if (hasValues(facts.jobs) or hasValues(facts.capabilities))
        and settings.showJobs ~= false
    then
        return COLORS.job or COLORS.generic
    end
    return COLORS.generic
end

-- A tile can contain more than one object (floor, furniture, and a fixture).
-- Pick a deterministic semantic winner before drawing the tile so a valid
-- chair cannot be hidden behind a lower-value object on the same square.
local function objectPriority(object, settings)
    settings = type(settings) == "table" and settings or {}
    local facts = object and object.facts or {}
    if facts.waterDetected and settings.showWater ~= false then return 60 end
    if facts.validSleeping and settings.showSleeping ~= false then return 50 end
    if facts.validSitting and settings.showSitting ~= false then return 45 end
    if facts.isCampfire and settings.showCampZones ~= false then return 40 end
    if (facts.semanticName or facts.commandName)
        and settings.showSemanticNames ~= false
    then
        return 30
    end
    if (hasValues(facts.jobs) or hasValues(facts.capabilities))
        and settings.showJobs ~= false
    then
        return 20
    end
    return 10
end

Overlay.ColorForObject = objectColor
Overlay.PriorityForObject = objectPriority

local function objectVisible(object, settings)
    return Model.ObjectVisible(object, settings) == true
end

local function boolKey(value)
    return value == true and "1" or "0"
end

local function settingsKey(settings)
    settings = type(settings) == "table" and settings or {}
    return boolKey(settings.showObjectNames ~= false) .. ":"
        .. boolKey(settings.showSemanticNames ~= false) .. ":"
        .. boolKey(settings.showUsage ~= false) .. ":"
        .. boolKey(settings.showSitting ~= false) .. ":"
        .. boolKey(settings.showSleeping ~= false) .. ":"
        .. boolKey(settings.showWater ~= false) .. ":"
        .. boolKey(settings.showCampZones ~= false) .. ":"
        .. boolKey(settings.showJobs ~= false) .. ":"
        .. boolKey(settings.showUnknownObjects == true) .. ":"
        .. boolKey(settings.showTooltip ~= false)
end

-- Object names, usage text, tooltips, and the camp preview are presentation
-- details. They must not keep the world renderer active by themselves. Only
-- these options can produce a world-space marker or zone highlight.
local function hasRenderableLayers(settings)
    settings = type(settings) == "table" and settings or {}
    return settings.showSemanticNames ~= false
        or settings.showSitting ~= false
        or settings.showSleeping ~= false
        or settings.showWater ~= false
        or settings.showCampZones ~= false
        or settings.showJobs ~= false
        or settings.showUnknownObjects == true
end

local function settingsForRender()
    local revision = Settings.GetRevision and Settings.GetRevision() or nil
    if Overlay.settings and Overlay.settingsRevision == revision then
        return Overlay.settings, Overlay.settingsKey
    end
    local settings = Settings.All()
    local key = settingsKey(settings)
    Overlay.settings = settings
    Overlay.settingsRevision = revision
    Overlay.settingsKey = key
    return settings, key
end

function Overlay.HasRenderableLayers(settings)
    if settings == nil then settings = settingsForRender() end
    return hasRenderableLayers(settings)
end

local function invalidateRenderCaches()
    Overlay.settings = nil
    Overlay.settingsRevision = nil
    Overlay.settingsKey = nil
    Overlay.renderPlan = nil
    Overlay.renderPlanSnapshot = nil
    Overlay.renderPlanSettingsKey = nil
    Overlay.hoverKey = nil
    Overlay.hoverPlan = nil
    Overlay.tooltipKey = nil
    Overlay.tooltipObject = nil
    Overlay.tooltipLines = nil
    Overlay.tooltipWidth = nil
end

local function playerValue(player, method)
    local fn = player and player[method]
    if type(fn) ~= "function" then return "" end
    local ok, value = pcall(fn, player)
    return ok and tostring(value or "") or ""
end

local function cameraValue(fn)
    if type(fn) ~= "function" then return "" end
    local ok, value = pcall(fn)
    return ok and tostring(value or "") or ""
end

local function hoverKey(drawer, index, player, mouseX, mouseY, plan)
    return tostring(plan) .. ":" .. tostring(index) .. ":"
        .. tostring(mouseX) .. ":" .. tostring(mouseY) .. ":"
        .. playerValue(player, "getX") .. ":"
        .. playerValue(player, "getY") .. ":"
        .. playerValue(player, "getZ") .. ":"
        .. cameraValue(getCameraOffX) .. ":"
        .. cameraValue(getCameraOffY) .. ":"
        .. tostring(Primitives.Number(drawer.width) or 0) .. ":"
        .. tostring(Primitives.Number(drawer.height) or 0)
end

local function mousePosition(drawer)
    if type(getMouseX) ~= "function" or type(getMouseY) ~= "function" then
        return nil, nil
    end
    local mouseX = getMouseX() - (Primitives.Number(drawer.x) or 0)
    local mouseY = getMouseY() - (Primitives.Number(drawer.y) or 0)
    return mouseX, mouseY
end

local function findHovered(drawer, index, objects, player, plan, mouseX, mouseY)
    if mouseX == nil or mouseY == nil then return nil end
    local key = hoverKey(drawer, index, player, mouseX, mouseY, plan)
    if Overlay.hoverKey == key and Overlay.hoverPlan == plan then
        return Overlay.hovered
    end
    local best, bestDistance
    for objectIndex = 1, #(objects or {}) do
        local object = objects[objectIndex]
        local distance = Primitives.HoveredWorld(drawer, index, object,
            mouseX, mouseY)
        if distance and (not bestDistance or distance < bestDistance) then
            best, bestDistance = object, distance
        end
    end
    Overlay.hovered = best
    Overlay.hoveredZone = nil
    Overlay.hoverKey = key
    Overlay.hoverPlan = plan
    if Overlay.tooltipKey and Overlay.tooltipObject ~= best then
        Overlay.tooltipKey = nil
        Overlay.tooltipLines = nil
        Overlay.tooltipWidth = nil
    end
    Overlay.tooltipObject = best
    return best
end

local function drawTooltip(drawer, object, settings, settingsKeyValue,
    mouseX, mouseY)
    if settings.showTooltip == false or not object
        or mouseX == nil or mouseY == nil
    then return end
    local key = tostring(object) .. ":" .. tostring(settingsKeyValue or "")
    if Overlay.tooltipKey ~= key then
        local lines = Model.TooltipLines(object, settings)
        local displayLines = {}
        local width = 190
        for index = 1, #lines do
            displayLines[index] = Primitives.TruncateText(lines[index], 72)
            width = math.max(width, #displayLines[index] * 7 + 18)
        end
        Overlay.tooltipKey = key
        Overlay.tooltipObject = object
        Overlay.tooltipLines = displayLines
        Overlay.tooltipWidth = width
    end
    local displayLines = Overlay.tooltipLines or {}
    if #displayLines == 0 then return end
    local width = Overlay.tooltipWidth or 190
    width = math.min(width, 560,
        math.max(190, (drawer.width or 1920) - 16))
    local height = #displayLines * 17 + 12
    local x = mouseX + 14
    local y = mouseY + 14
    if x + width > drawer.width then x = drawer.width - width - 4 end
    if y + height > drawer.height then y = drawer.height - height - 4 end
    x, y = math.max(4, x), math.max(4, y)
    if drawer.drawRect then
        drawer:drawRect(x, y, width, height, 0.92, 0.01, 0.02, 0.04)
    end
    if drawer.drawRectBorder then
        drawer:drawRectBorder(x, y, width, height, 0.95,
            COLORS.selected.r, COLORS.selected.g, COLORS.selected.b)
    end
    for index = 1, #displayLines do
        Primitives.DrawText(drawer, displayLines[index], x + 8,
            y + 5 + (index - 1) * 17, { r = 1, g = 1, b = 1, a = 1 })
    end
end

function Overlay.SyncRenderHook()
    if not Overlay.enabled then
        if Overlay.eventsInstalled then return Overlay.Uninstall() end
        return true
    end
    local settings = settingsForRender()
    if hasRenderableLayers(settings) then return Overlay.Install() end
    if Overlay.eventsInstalled then return Overlay.Uninstall() end
    return true
end

function Overlay.SetEnabled(enabled)
    enabled = enabled == true
    Overlay.enabled = enabled
    Overlay.SyncRenderHook()
    if not enabled then
        Overlay.hovered = nil
        Overlay.hoveredZone = nil
        Overlay.visibleObjects = {}
        Overlay.snapshot = nil
        invalidateRenderCaches()
    end
    return Overlay.enabled
end

function Overlay.Toggle()
    return Overlay.SetEnabled(not Overlay.enabled)
end

function Overlay.IsEnabled()
    return Overlay.enabled == true
end

function Overlay.SetSnapshot(snapshot)
    local nextSnapshot
    if type(snapshot) == "table" and snapshot.status == "READY" then
        nextSnapshot = snapshot
    end
    if Overlay.snapshot ~= nextSnapshot then
        Overlay.snapshot = nextSnapshot
        invalidateRenderCaches()
    end
    return Overlay.snapshot
end

function Overlay.Clear(clearPerception)
    Overlay.hovered = nil
    Overlay.hoveredZone = nil
    Overlay.visibleObjects = {}
    Overlay.snapshot = nil
    invalidateRenderCaches()
    if clearPerception == true then Perception.ClearSnapshotCache() end
end

local function zoneKey(zone)
    local bounds = zone and zone.roomBounds or nil
    return tostring(zone and zone.kind or "") .. ":"
        .. tostring(zone and (zone.siteID or zone.campfireID or zone.roomID)
            or "") .. ":" .. tostring(zone and zone.x or "") .. ":"
        .. tostring(zone and zone.y or "") .. ":"
        .. tostring(zone and zone.z or bounds and bounds.z or "") .. ":"
        .. tostring(bounds and bounds.minX or "") .. ":"
        .. tostring(bounds and bounds.minY or "") .. ":"
        .. tostring(bounds and bounds.maxX or "") .. ":"
        .. tostring(bounds and bounds.maxY or "")
end

local function buildRenderPlan(snapshot, settings)
    local plan = { zones = {}, tiles = {}, objects = {} }
    if settings.showCampZones ~= false then
        local seenZones = {}
        for zoneIndex = 1, math.min(Overlay.MAX_RENDER_ZONES,
            #(snapshot.zones or {})) do
            local zone = snapshot.zones[zoneIndex]
            if zone and (zone.kind == "room" or zone.kind == "campfire") then
                local key = zoneKey(zone)
                if not seenZones[key] then
                    seenZones[key] = true
                    plan.zones[#plan.zones + 1] = zone
                end
            end
        end
    end

    local selectedByTile = {}
    local selectedTileOrder = {}
    for objectIndex = 1, #(snapshot.objects or {}) do
        local object = snapshot.objects[objectIndex]
        if objectVisible(object, settings) then
            local tileX = math.floor(Primitives.Number(object.x) or 0)
            local tileY = math.floor(Primitives.Number(object.y) or 0)
            local tileZ = math.floor(Primitives.Number(object.z) or 0)
            local tileKey = tostring(tileX) .. ":" .. tostring(tileY)
                .. ":" .. tostring(tileZ)
            local priority = objectPriority(object, settings)
            local selected = selectedByTile[tileKey]
            if selected then
                if priority > selected.priority then
                    selected.object = object
                    selected.priority = priority
                end
            elseif #selectedTileOrder < Overlay.MAX_RENDER_OBJECTS then
                selectedByTile[tileKey] = {
                    object = object,
                    priority = priority,
                    x = tileX, y = tileY, z = tileZ,
                }
                selectedTileOrder[#selectedTileOrder + 1] = tileKey
            end
        end
    end

    for tileIndex = 1, #selectedTileOrder do
        local selected = selectedByTile[selectedTileOrder[tileIndex]]
        if selected then
            plan.tiles[#plan.tiles + 1] = {
                x = selected.x,
                y = selected.y,
                z = selected.z,
                color = objectColor(selected.object, settings),
            }
            plan.objects[#plan.objects + 1] = selected.object
        end
    end
    return plan
end

local function renderPlanFor(snapshot, settings, key)
    if Overlay.renderPlan and Overlay.renderPlanSnapshot == snapshot
        and Overlay.renderPlanSettingsKey == key
    then
        return Overlay.renderPlan
    end
    local plan = buildRenderPlan(snapshot, settings)
    Overlay.renderPlan = plan
    Overlay.renderPlanSnapshot = snapshot
    Overlay.renderPlanSettingsKey = key
    Overlay.hoverKey = nil
    Overlay.hoverPlan = nil
    Overlay.tooltipKey = nil
    Overlay.tooltipObject = nil
    Overlay.tooltipLines = nil
    Overlay.tooltipWidth = nil
    return plan
end

function Overlay.Render()
    if not Overlay.IsEnabled() then return end
    local settings, settingsKeyValue = settingsForRender()
    -- An enabled debug session with every world layer unchecked is still a
    -- valid state, but it must be indistinguishable from an idle renderer.
    -- In particular, do not create/update the screen drawer or run hover
    -- projection work just because the dashboard is open.
    if not hasRenderableLayers(settings) then return end
    local selector = PsychopatzCore and PsychopatzCore.UI
        and PsychopatzCore.UI.GridRegionSelector or nil
    if selector and selector.instance
        and selector.instance.suppressPersistentOverlays == true
    then return end
    -- The snapshot is refreshed only by the dashboard's explicit Refresh
    -- action. Never run the scanner, provider chain, or camp preview from a
    -- frame renderer.
    local snapshot = Overlay.snapshot
    if not snapshot or snapshot.status ~= "READY" then return end

    local plan = renderPlanFor(snapshot, settings, settingsKeyValue)
    if #plan.tiles == 0 and #plan.zones == 0 then
        Overlay.visibleObjects = plan.objects
        return
    end
    local player = playerFor()
    if not player then return end
    local index = playerNum(player)
    local drawer = Primitives.DrawerFor(Overlay, index)
    if not drawer then return end
    if settings.showCampZones ~= false then
        for zoneIndex = 1, #plan.zones do
            local zone = plan.zones[zoneIndex]
            if zone.kind == "room" then
                Primitives.DrawRoomZone(drawer, index, zone, COLORS.room)
                Primitives.DrawZoneLabel(drawer, index, zone, COLORS.room)
            elseif zone.kind == "campfire" then
                Primitives.DrawCampZone(drawer, index, zone, COLORS.campfire)
                Primitives.DrawZoneLabel(drawer, index, zone, COLORS.campfire)
            end
        end
    end

    for tileIndex = 1, #plan.tiles do
        local tile = plan.tiles[tileIndex]
        Primitives.WorldTile(drawer, index, tile.x, tile.y, tile.z,
            tile.color)
    end

    Overlay.visibleObjects = plan.objects
    local mouseX, mouseY = mousePosition(drawer)
    local hovered = findHovered(drawer, index, plan.objects, player, plan,
        mouseX, mouseY)
    drawTooltip(drawer, hovered, settings, settingsKeyValue, mouseX, mouseY)
end

function Overlay.Install()
    if Overlay.eventsInstalled then return true end
    if not Overlay.enabled or not Overlay.HasRenderableLayers() then
        return true
    end
    if Events and Events.OnPreUIDraw
        and type(Events.OnPreUIDraw.Add) == "function"
    then
        Events.OnPreUIDraw.Add(Overlay.Render)
        Overlay.eventsInstalled = true
        return true
    end
    return false
end

function Overlay.Uninstall()
    if not Overlay.eventsInstalled then return true end
    if Events and Events.OnPreUIDraw
        and type(Events.OnPreUIDraw.Remove) == "function"
    then
        Events.OnPreUIDraw.Remove(Overlay.Render)
        Overlay.eventsInstalled = false
        return true
    end
    -- Some test/runtime shims expose Add without Remove.  Keep the one
    -- listener in that case; SetEnabled(false) still makes Render return
    -- before touching the world or UI state.
    return false
end

function Overlay.Reset()
    Overlay.SetEnabled(false)
    Overlay.Clear(true)
end

return Overlay
