-- Admin/debug world-map markers for persistent abstract survivor groups.

require "ISUI/Maps/ISWorldMap"

PNC = PNC or {}
PNC.AbstractGroupMapLayer = PNC.AbstractGroupMapLayer or {}

local GroupLayer = PNC.AbstractGroupMapLayer
local Layers = PNC.MapLayers
local ClientState = PNC.Network.ClientState

GroupLayer.lastRequestAt = GroupLayer.lastRequestAt or 0

local COLORS = {
    LOOTER = { r = 1.00, g = 0.22, b = 0.16 },
    REFUGEE = { r = 0.20, g = 0.72, b = 1.00 },
    SCAVENGER = { r = 0.95, g = 0.72, b = 0.18 },
    WANDERER = { r = 0.72, g = 0.72, b = 0.72 },
}

local function isVisible()
    return PNC.MapDisplay and PNC.MapDisplay.AreBasesVisible
        and PNC.MapDisplay.AreBasesVisible()
        and PNC.Client and PNC.Client.CanUseDebug
        and PNC.Client.CanUseDebug()
end

function GroupLayer.Update(force)
    if not isVisible() then return false end
    local now = PNC.Core.Now()
    if force ~= true
        and now - (tonumber(GroupLayer.lastRequestAt) or 0) < 1500
    then return false end
    GroupLayer.lastRequestAt = now
    local snapshot = ClientState.directorDebug or {}
    return PNC.Client.RequestDirectorDebug(
        snapshot.selectedGroupId, snapshot.selectedLocationId,
        snapshot.population and snapshot.population.selectedSectorId)
end

local function markerColor(group)
    return COLORS[tostring(group and group.groupType or "")]
        or COLORS.WANDERER
end

local function drawHover(map, group, x, y, color)
    local members = #(group.memberIds or {})
    local lines = {
        tostring(group.groupType or "SURVIVOR GROUP"),
        "Members: " .. tostring(members),
        tostring(group.mission or "IDLE") .. " / "
            .. tostring(group.state or "IDLE"),
        "Faction: " .. tostring(group.factionId or "independent"),
    }
    local width, height = 250, 74
    x = math.min((map.width or 0) - width - 5, x + 12)
    y = math.min((map.height or 0) - height - 5, y + 12)
    x, y = math.max(5, x), math.max(5, y)
    map:drawRect(x, y, width, height, 0.94, 0.04, 0.04, 0.04)
    map:drawRectBorder(x, y, width, height, 1,
        color.r, color.g, color.b)
    for index, line in ipairs(lines) do
        map:drawText(line, x + 8, y + 5 + (index - 1) * 16,
            index == 1 and color.r or 0.88,
            index == 1 and color.g or 0.88,
            index == 1 and color.b or 0.88, 1, UIFont.Small)
    end
end

function GroupLayer.Render(map)
    if not isVisible() or not map or not map.mapAPI then return end
    GroupLayer.Update(false)
    if ClientState.directorDebugAuthorized ~= true then return end
    local snapshot = ClientState.directorDebug or {}
    local mouseX, mouseY = map:getMouseX(), map:getMouseY()
    local hovered, hoveredX, hoveredY, hoveredColor
    local showNames = PNC.MapDisplay.AreNamesVisible
        and PNC.MapDisplay.AreNamesVisible()
    for _, group in ipairs(snapshot.groups or {}) do
        local location = group.location
        if location and location.x and location.y then
            local x = map.mapAPI:worldToUIX(location.x, location.y)
            local y = map.mapAPI:worldToUIY(location.x, location.y)
            local color = markerColor(group)
            local dx, dy = mouseX - x, mouseY - y
            local isHovered = dx * dx + dy * dy <= 64
            local size = isHovered and 10 or 7
            map:drawRect(x - size / 2, y - size / 2, size, size, 1,
                color.r, color.g, color.b)
            map:drawRectBorder(x - size / 2, y - size / 2, size, size, 1,
                0.05, 0.05, 0.05)
            if showNames or isHovered then
                map:drawTextCentre(tostring(group.groupType or "GROUP"), x,
                    y - 18, color.r, color.g, color.b, 1, UIFont.Small)
            end
            if isHovered then
                hovered, hoveredX, hoveredY, hoveredColor = group, mouseX,
                    mouseY, color
            end
        end
    end
    if hovered then
        drawHover(map, hovered, hoveredX, hoveredY, hoveredColor)
    end
end

if Layers and Layers.Register then
    Layers.Register("pnc_abstract_groups", {
        order = 105,
        isVisible = isVisible,
        render = GroupLayer.Render,
    })
end

return GroupLayer
