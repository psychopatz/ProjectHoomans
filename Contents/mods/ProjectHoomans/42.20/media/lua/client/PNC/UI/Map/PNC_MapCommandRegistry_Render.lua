PNC = PNC or {}
PNC.MapCommands = PNC.MapCommands or {}

local Commands = PNC.MapCommands
local Core = PNC.Core
local Layers = PNC.MapLayers
local Deps = Commands._ProviderDeps or {}
local mapPoint = Deps.mapPoint
local regionStateBounds = Deps.regionStateBounds
local selectionLabel = Deps.selectionLabel
local finishRegionSelection = Deps.finishRegionSelection

local function drawWorldRectangle(map, bounds, color)
    if not map or not map.mapAPI or not bounds then return end
    local x1 = map.mapAPI:worldToUIX(bounds.minX, bounds.minY)
    local y1 = map.mapAPI:worldToUIY(bounds.minX, bounds.minY)
    local x2 = map.mapAPI:worldToUIX(bounds.maxX + 1, bounds.minY)
    local y2 = map.mapAPI:worldToUIY(bounds.maxX + 1, bounds.minY)
    local x3 = map.mapAPI:worldToUIX(bounds.maxX + 1, bounds.maxY + 1)
    local y3 = map.mapAPI:worldToUIY(bounds.maxX + 1, bounds.maxY + 1)
    local x4 = map.mapAPI:worldToUIX(bounds.minX, bounds.maxY + 1)
    local y4 = map.mapAPI:worldToUIY(bounds.minX, bounds.maxY + 1)
    if map.javaObject and map.javaObject.DrawLine then
        local thickness = 2
        map.javaObject:DrawLine(nil, x1, y1, x2, y2, thickness,
            color.r, color.g, color.b, color.a)
        map.javaObject:DrawLine(nil, x2, y2, x3, y3, thickness,
            color.r, color.g, color.b, color.a)
        map.javaObject:DrawLine(nil, x3, y3, x4, y4, thickness,
            color.r, color.g, color.b, color.a)
        map.javaObject:DrawLine(nil, x4, y4, x1, y1, thickness,
            color.r, color.g, color.b, color.a)
    elseif map.drawRectBorder then
        local left = math.min(x1, x2, x3, x4)
        local top = math.min(y1, y2, y3, y4)
        local right = math.max(x1, x2, x3, x4)
        local bottom = math.max(y1, y2, y3, y4)
        map:drawRectBorder(left, top, right - left, bottom - top,
            color.a, color.r, color.g, color.b)
    end
end

local function renderCommandStatus(map)
    if not Commands.Active or not map then return end
    local regionState = Commands.RegionSelection
    local label
    if regionState and regionState.map == map then
        label = "Select lumber region — drag across the trees"
        local minX, minY, maxX, maxY = regionStateBounds(regionState)
        if minX then
            label = label .. " · "
                .. tostring((maxX - minX + 1) * (maxY - minY + 1))
                .. " tiles"
        end
    else
        label = "Commanding " .. selectionLabel()
            .. " — right-click a destination"
    end
    if Commands.LastResult
        and Core.Now() - (tonumber(Commands.LastResultAt) or 0) <= 5000
    then
        if Commands.LastResult.ok == true then
            label = label .. " · accepted "
                .. tostring(Commands.LastResult.accepted or 0)
        else
            label = label .. " · failed: "
                .. tostring(Commands.LastResult.reason or "unknown")
        end
    end
    local font = UIFont.Small
    local textManager = getTextManager()
    local width = textManager:MeasureStringX(font, label) + 20
    local height = textManager:getFontHeight(font) + 10
    local x = math.max(8, (map.width - width) / 2)
    local y = 8
    map:drawRect(x, y, width, height, 0.88, 0.04, 0.04, 0.04)
    map:drawRectBorder(x, y, width, height, 1, 0.25, 0.75, 1)
    map:drawTextCentre(
        label,
        x + width / 2,
        y + 5,
        1,
        1,
        1,
        1,
        font
    )
    local target = Commands.LastTarget
    if target and target.x and target.y and map.mapAPI then
        local sx = map.mapAPI:worldToUIX(target.x, target.y)
        local sy = map.mapAPI:worldToUIY(target.x, target.y)
        map:drawRect(sx - 5, sy - 1, 10, 2, 1, 0.2, 1, 0.2)
        map:drawRect(sx - 1, sy - 5, 2, 10, 1, 0.2, 1, 0.2)
    end
    if regionState and regionState.map == map then
        local minX, minY, maxX, maxY, z = regionStateBounds(regionState)
        if minX then
            drawWorldRectangle(map, {
                minX = minX, minY = minY, maxX = maxX, maxY = maxY,
                minZ = z, maxZ = z,
            }, { r = 0.25, g = 1, b = 0.25, a = 1 })
        end
    elseif Commands.LastRegionBounds then
        drawWorldRectangle(map, Commands.LastRegionBounds,
            { r = 0.25, g = 1, b = 0.25, a = 1 })
    end
end

if Layers and Layers.Register then
    Layers.Register("pnc_map_command_status", {
        order = 1000,
        isVisible = function() return Commands.Active end,
        render = renderCommandStatus,
    })
end

if ISWorldMap and not ISWorldMap._pncMapCommandsPatched then
    ISWorldMap._pncMapCommandsPatched = true
    local originalMouseDown = ISWorldMap.onMouseDown
    local originalMouseMove = ISWorldMap.onMouseMove
    local originalMouseMoveOutside = ISWorldMap.onMouseMoveOutside
    local originalMouseUp = ISWorldMap.onMouseUp
    local originalMouseUpOutside = ISWorldMap.onMouseUpOutside
    local originalRightMouseDown = ISWorldMap.onRightMouseDown
    local originalRightMouseUp = ISWorldMap.onRightMouseUp
    local originalClose = ISWorldMap.close
    function ISWorldMap:onMouseDown(x, y)
        local state = Commands.RegionSelection
        if state and state.map == self then
            local point = mapPoint(self, x, y, state.z)
            if point then
                state.dragging = true
                state.startX, state.startY = point.x, point.y
                state.currentX, state.currentY = point.x, point.y
            end
            return true
        end
        if originalMouseDown then return originalMouseDown(self, x, y) end
        return false
    end
    function ISWorldMap:onMouseMove(dx, dy)
        local state = Commands.RegionSelection
        if state and state.map == self then
            if state.dragging then
                local point = mapPoint(self, self:getMouseX(),
                    self:getMouseY(), state.z)
                if point then
                    state.currentX, state.currentY = point.x, point.y
                end
            end
            return true
        end
        if originalMouseMove then return originalMouseMove(self, dx, dy) end
        return false
    end
    function ISWorldMap:onMouseMoveOutside(dx, dy)
        local state = Commands.RegionSelection
        if state and state.map == self then
            if state.dragging then
                local point = mapPoint(self, self:getMouseX(),
                    self:getMouseY(), state.z)
                if point then
                    state.currentX, state.currentY = point.x, point.y
                end
            end
            return true
        end
        if originalMouseMoveOutside then
            return originalMouseMoveOutside(self, dx, dy)
        end
        return false
    end
    function ISWorldMap:onMouseUp(x, y)
        if Commands.RegionSelection
            and Commands.RegionSelection.map == self
        then
            return finishRegionSelection(self, x, y)
        end
        if originalMouseUp then return originalMouseUp(self, x, y) end
        return false
    end
    function ISWorldMap:onMouseUpOutside(x, y)
        if Commands.RegionSelection
            and Commands.RegionSelection.map == self
        then
            return finishRegionSelection(self, x, y)
        end
        if originalMouseUpOutside then
            return originalMouseUpOutside(self, x, y)
        end
        return false
    end
    function ISWorldMap:onRightMouseDown(x, y)
        if Commands.Active and #Commands.Selection > 0 then
            return true
        end
        return originalRightMouseDown(self, x, y)
    end
    function ISWorldMap:onRightMouseUp(x, y)
        if Commands.Active and #Commands.Selection > 0 then
            if Commands.RegionSelection then
                Commands.CancelRegionSelection()
                return true
            end
            local target = {
                x = self.mapAPI:uiToWorldX(x, y),
                y = self.mapAPI:uiToWorldY(x, y),
                z = 0,
            }
            Commands.BuildContext(self, x, y, target)
            return true
        end
        return originalRightMouseUp(self, x, y)
    end
    function ISWorldMap:close()
        self._pncCommandMode = nil
        Commands.ClearSelection()
        if originalClose then return originalClose(self) end
        return false
    end
end

return Commands
