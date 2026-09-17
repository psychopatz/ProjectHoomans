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
Overlay.drawer = Overlay.drawer
Overlay.hovered = nil
Overlay.hoveredZone = nil

local COLORS = {
    generic = { r = 0.78, g = 0.84, b = 0.92, a = 0.70 },
    semantic = { r = 0.32, g = 0.70, b = 1.00, a = 0.76 },
    sitting = { r = 0.24, g = 1.00, b = 0.46, a = 0.84 },
    sleeping = { r = 0.80, g = 0.42, b = 1.00, a = 0.84 },
    water = { r = 0.18, g = 0.66, b = 1.00, a = 0.82 },
    depleted = { r = 1.00, g = 0.62, b = 0.16, a = 0.78 },
    unsafe = { r = 1.00, g = 0.20, b = 0.16, a = 0.86 },
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

local function objectColor(object, settings)
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
    if facts.semanticName and settings.showSemanticNames ~= false then
        return COLORS.semantic
    end
    return COLORS.generic
end

local function hasValues(values)
    return type(values) == "table" and #values > 0
end

local function objectVisible(object, settings)
    local facts = object and object.facts or {}
    if settings.showUnknownObjects == true then return true end
    local visible = false
    local recognized = facts.semanticName ~= nil
        or facts.validSitting == true
        or facts.validSleeping == true
        or facts.waterDetected == true
        or facts.isCampfire == true
        or facts.indoor == true
        or hasValues(facts.usage)
        or hasValues(facts.jobs)
        or hasValues(facts.capabilities)
    if recognized and settings.showObjectNames ~= false then
        visible = true
    end
    if (facts.semanticName or facts.commandName)
        and settings.showSemanticNames ~= false
    then
        visible = true
    end
    if hasValues(facts.usage) and settings.showUsage ~= false then
        visible = true
    end
    if (hasValues(facts.jobs) or hasValues(facts.capabilities))
        and settings.showJobs ~= false
    then
        visible = true
    end
    if facts.validSitting == true and settings.showSitting ~= false then
        visible = true
    end
    if facts.validSleeping == true and settings.showSleeping ~= false then
        visible = true
    end
    if facts.waterDetected == true and settings.showWater ~= false then
        visible = true
    end
    if (facts.isCampfire == true or facts.indoor == true)
        and settings.showCampZones ~= false
    then
        visible = true
    end
    return visible
end

local function findHovered(drawer, index, snapshot, settings)
    if type(getMouseX) ~= "function" or type(getMouseY) ~= "function" then
        return nil
    end
    local mouseX = getMouseX() - (Primitives.Number(drawer.x) or 0)
    local mouseY = getMouseY() - (Primitives.Number(drawer.y) or 0)
    local best, bestDistance
    for objectIndex = 1, #(snapshot.objects or {}) do
        local object = snapshot.objects[objectIndex]
        if objectVisible(object, settings) then
            local distance = Primitives.HoveredWorld(drawer, index, object,
                mouseX, mouseY)
            if distance and (not bestDistance or distance < bestDistance) then
                best, bestDistance = object, distance
            end
        end
    end
    Overlay.hovered = best
    Overlay.hoveredZone = nil
    return best
end

local function drawTooltip(drawer, object, settings)
    if settings.showTooltip == false or not object
        or type(getMouseX) ~= "function" or type(getMouseY) ~= "function"
    then return end
    local lines = Model.TooltipLines(object, settings)
    if #lines == 0 then return end
    local width = 190
    for index = 1, #lines do
        width = math.max(width, #tostring(lines[index]) * 7 + 18)
    end
    width = math.min(width, math.max(190, (drawer.width or 1920) - 16))
    local height = #lines * 17 + 12
    local x = getMouseX() - (Primitives.Number(drawer.x) or 0) + 14
    local y = getMouseY() - (Primitives.Number(drawer.y) or 0) + 14
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
    for index = 1, #lines do
        Primitives.DrawText(drawer, lines[index], x + 8,
            y + 5 + (index - 1) * 17, { r = 1, g = 1, b = 1, a = 1 })
    end
end

function Overlay.SetEnabled(enabled)
    enabled = enabled == true
    Settings.Set("enabled", enabled, true)
    if not enabled then
        Overlay.hovered = nil
        Overlay.hoveredZone = nil
    end
    return enabled
end

function Overlay.Toggle()
    return Overlay.SetEnabled(not Settings.Get("enabled", false))
end

function Overlay.IsEnabled()
    return Settings.Get("enabled", false) == true
end

function Overlay.Clear()
    Overlay.hovered = nil
    Overlay.hoveredZone = nil
    Perception.ClearSnapshotCache()
end

function Overlay.Render()
    if not Overlay.IsEnabled() then return end
    local selector = PsychopatzCore and PsychopatzCore.UI
        and PsychopatzCore.UI.GridRegionSelector or nil
    if selector and selector.instance
        and selector.instance.suppressPersistentOverlays == true
    then return end
    local player = playerFor()
    if not player then return end
    local index = playerNum(player)
    local drawer = Primitives.DrawerFor(Overlay, index)
    if not drawer then return end
    local settings = Settings.All()
    local snapshot = Perception.GetSnapshot({
        radius = Perception.DEFAULT_RADIUS,
        maxObjects = Perception.MAX_OBJECTS,
    })
    if not snapshot or snapshot.status ~= "READY" then return end

    if settings.showCampZones ~= false then
        for zoneIndex = 1, #(snapshot.zones or {}) do
            local zone = snapshot.zones[zoneIndex]
            if zone.kind == "room" then
                Primitives.DrawRoomZone(drawer, index, zone, COLORS.room)
            elseif zone.kind == "campfire" then
                Primitives.DrawCampZone(drawer, index, zone, COLORS.campfire)
            end
        end
    end

    for objectIndex = 1, #(snapshot.objects or {}) do
        local object = snapshot.objects[objectIndex]
        local facts = object.facts or {}
        if objectVisible(object, settings) then
            local color = objectColor(object, settings)
            local showTile = facts.validSitting and settings.showSitting ~= false
                or facts.validSleeping and settings.showSleeping ~= false
                or facts.waterDetected and settings.showWater ~= false
                or facts.isCampfire and settings.showCampZones ~= false
            if showTile then
                Primitives.WorldTile(drawer, index, object.x, object.y,
                    object.z, color)
            else
                Primitives.WorldMarker(drawer, index,
                    (Primitives.Number(object.x) or 0) + 0.5,
                    (Primitives.Number(object.y) or 0) + 0.5, object.z,
                    color, 6)
            end
            local label = Model.ObjectLabel(object, settings)
            if label then
                Primitives.DrawLabel(drawer, index,
                    (Primitives.Number(object.x) or 0) + 0.5,
                    (Primitives.Number(object.y) or 0) + 0.5,
                    Primitives.Number(object.z) or 0, label, color, 23)
            end
        end
    end

    local hovered = findHovered(drawer, index, snapshot, settings)
    drawTooltip(drawer, hovered, settings)
end

function Overlay.Install()
    if Overlay.eventsInstalled then return true end
    if Events and Events.OnPreUIDraw then
        Events.OnPreUIDraw.Add(Overlay.Render)
        Overlay.eventsInstalled = true
        return true
    end
    return false
end

function Overlay.Reset()
    Overlay.SetEnabled(false)
    Overlay.Clear()
end

Overlay.Install()

return Overlay
