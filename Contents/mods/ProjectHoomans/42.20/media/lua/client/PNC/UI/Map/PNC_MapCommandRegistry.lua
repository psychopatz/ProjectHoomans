--[[
    Extensible world-map command surface.

    This owns selection, context-menu composition, and transport dispatch. Each
    gameplay action registers an independent provider; the map hook never needs
    to know whether an option means move, scavenge, guard, build, or trade.
]]

require "ISUI/Maps/ISWorldMap"
require "ISUI/ISContextMenu"
require "PNC/Knowledge/PNC_NPCIdentityPresentation"

PNC = PNC or {}
PNC.MapCommands = PNC.MapCommands or {}

local Commands = PNC.MapCommands
local Core = PNC.Core
local Layers = PNC.MapLayers
local Identity = PNC.NPCIdentityPresentation

Commands.Providers = Commands.Providers or {}
Commands.Ordered = Commands.Ordered or {}
Commands.Selection = Commands.Selection or {}
Commands.Active = Commands.Active == true
Commands.RegionSelection = Commands.RegionSelection or nil

local function finiteNumber(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return nil
    end
    return value
end

local function mapPoint(map, x, y, z)
    if not map or not map.mapAPI then return nil end
    local worldX = finiteNumber(map.mapAPI:uiToWorldX(x, y))
    local worldY = finiteNumber(map.mapAPI:uiToWorldY(x, y))
    if not worldX or not worldY then return nil end
    return {
        x = math.floor(worldX),
        y = math.floor(worldY),
        z = math.floor(finiteNumber(z) or 0),
    }
end

local function regionForBounds(minX, minY, maxX, maxY, z)
    local width = maxX - minX + 1
    local height = maxY - minY + 1
    local maximum = math.max(1, math.floor(
        tonumber(PNC.Const and PNC.Const.LUMBER_MAX_ZONE_TILES) or 10000
    ))
    if width < 1 or height < 1 or width * height > maximum then
        return nil, "selection_too_large"
    end
    local rows = {}
    local y
    for y = minY, maxY do rows[y] = { minX, maxX } end
    return {
        levels = { [z] = { rows = rows } },
    }, {
        minX = minX, minY = minY, maxX = maxX, maxY = maxY,
        minZ = z, maxZ = z,
        tileCount = width * height,
    }
end

local function regionStateBounds(state)
    if not state or state.startX == nil or state.startY == nil
        or state.currentX == nil or state.currentY == nil
    then
        return nil
    end
    return math.min(state.startX, state.currentX),
        math.min(state.startY, state.currentY),
        math.max(state.startX, state.currentX),
        math.max(state.startY, state.currentY),
        state.z or 0
end

local function setFailure(commandID, reason)
    Commands.LastResult = {
        ok = false, commandID = commandID, reason = reason,
    }
    Commands.LastResultAt = Core.Now()
    return false
end

local function rebuildOrder()
    local output = {}
    local _, provider
    for _, provider in pairs(Commands.Providers) do
        output[#output + 1] = provider
    end
    table.sort(output, function(left, right)
        local leftOrder = tonumber(left.order) or 100
        local rightOrder = tonumber(right.order) or 100
        if leftOrder == rightOrder then
            return tostring(left.id) < tostring(right.id)
        end
        return leftOrder < rightOrder
    end)
    Commands.Ordered = output
end

local function normalizedSelection(raw)
    local output = {}
    local seen = {}
    local maximum = math.max(
        1,
        math.floor(tonumber(PNC.Const.MAP_COMMAND_MAX_SELECTION) or 32)
    )
    local i
    local source
    local id
    if type(raw) ~= "table" then raw = { raw } end
    if raw.id ~= nil then raw = { raw } end
    for i = 1, math.min(#raw, maximum) do
        source = type(raw[i]) == "table" and raw[i] or { id = raw[i] }
        id = tostring(source.id or "")
        if id ~= "" and not seen[id] then
            seen[id] = true
            output[#output + 1] = {
                id = id,
                name = Identity.GetName(source),
                x = tonumber(source.x),
                y = tonumber(source.y),
                z = tonumber(source.z) or 0,
            }
        end
    end
    return output
end

local function selectionLabel()
    if #Commands.Selection == 1 then
        return Commands.Selection[1].name
    end
    return tostring(#Commands.Selection) .. " NPCs"
end

function Commands.RegisterProvider(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or (
            type(definition.execute) ~= "function"
            and type(definition.populate) ~= "function"
        )
    then
        return false
    end
    definition.id = id
    Commands.Providers[id] = definition
    rebuildOrder()
    return true
end

function Commands.UnregisterProvider(id)
    id = tostring(id or "")
    if id == "" or Commands.Providers[id] == nil then return false end
    Commands.Providers[id] = nil
    rebuildOrder()
    return true
end

function Commands.SetSelection(raw)
    Commands.Selection = normalizedSelection(raw)
    Commands.Active = #Commands.Selection > 0
    Commands.RegionSelection = nil
    Commands.LastTarget = nil
    Commands.LastRegion = nil
    Commands.LastRegionBounds = nil
    Commands.LastResult = nil
    Commands.LastResultAt = nil
    return #Commands.Selection
end

function Commands.GetSelection()
    return Commands.Selection
end

function Commands.GetSelectionIDs()
    local output = {}
    local i
    for i = 1, #Commands.Selection do
        output[i] = Commands.Selection[i].id
    end
    return output
end

function Commands.IsSelected(npcId)
    npcId = tostring(npcId or "")
    local i
    for i = 1, #Commands.Selection do
        if Commands.Selection[i].id == npcId then return true end
    end
    return false
end

function Commands.ClearSelection()
    Commands.Selection = {}
    Commands.Active = false
    Commands.RegionSelection = nil
    Commands.LastRegion = nil
    Commands.LastRegionBounds = nil
end

function Commands.BeginRegionSelection(provider, target, map)
    if not provider or provider.region ~= true or not map
        or not map.mapAPI
    then
        return false
    end
    local selection = Commands.Selection[1]
    Commands.RegionSelection = {
        provider = provider,
        map = map,
        z = math.floor(tonumber(target and target.z)
            or tonumber(selection and selection.z) or 0),
        dragging = false,
        startX = nil,
        startY = nil,
        currentX = nil,
        currentY = nil,
    }
    Commands.LastTarget = nil
    Commands.LastRegion = nil
    Commands.LastRegionBounds = nil
    Commands.LastResult = nil
    Commands.LastResultAt = nil
    return true
end

function Commands.CancelRegionSelection()
    if not Commands.RegionSelection then return false end
    Commands.RegionSelection = nil
    return true
end

function Commands.ExecuteRegionProvider(provider, target, map, region)
    if not provider or type(provider.executeRegion) ~= "function" then
        return false
    end
    local ok
    local result
    ok, result = pcall(
        provider.executeRegion,
        Commands.Selection,
        target,
        map,
        region,
        provider
    )
    if not ok then
        setFailure(provider.id, "client_provider_failed")
        if Core and Core.LogWarn then
            Core.LogWarn(
                "PNC map region provider failed id="
                    .. tostring(provider.id) .. " error=" .. tostring(result)
            )
        end
        return false
    end
    return result ~= false
end

local function finishRegionSelection(map, x, y)
    local state = Commands.RegionSelection
    if not state or state.map ~= map then return false end
    local point = mapPoint(map, x, y, state.z)
    if point then
        state.currentX, state.currentY = point.x, point.y
    end
    local minX, minY, maxX, maxY, z = regionStateBounds(state)
    if not minX then
        Commands.RegionSelection = nil
        return setFailure(state.provider and state.provider.id,
            "selection_empty")
    end
    local region, bounds = regionForBounds(minX, minY, maxX, maxY, z)
    local provider = state.provider
    Commands.RegionSelection = nil
    if not region then
        return setFailure(provider and provider.id, "selection_too_large")
    end
    local target = {
        x = math.floor((minX + maxX) / 2),
        y = math.floor((minY + maxY) / 2),
        z = z,
    }
    Commands.LastTarget = {
        x = target.x, y = target.y, z = target.z,
    }
    Commands.LastRegionBounds = bounds
    return Commands.ExecuteRegionProvider(provider, target, map, region)
end

function Commands.HandleResult(result)
    Commands.LastResult = type(result) == "table" and result or {
        ok = false,
        reason = "result_invalid",
    }
    Commands.LastResultAt = Core.Now()
    if result and result.commandID == "fishing_zone"
        and result.ok == true and result.details
        and PNC.FishingZoneOverlay
        and PNC.FishingZoneOverlay.SetZone
    then
        PNC.FishingZoneOverlay.SetZone(result.details)
    end
    if result and result.commandID == "lumber_zone"
        and result.ok == true and result.details
    then
        Commands.LastRegion = result.details.geometry
        Commands.LastRegionBounds = result.details.bounds
    end
    if result and result.target then
        Commands.LastTarget = {
            x = tonumber(result.target.x),
            y = tonumber(result.target.y),
            z = tonumber(result.target.z) or 0,
        }
    end
    return Commands.LastResult
end

function Commands.Dispatch(commandID, target, options)
    if not PNC.Client or not PNC.Client.SendMapCommand then return false end
    return PNC.Client.SendMapCommand(
        commandID,
        Commands.GetSelectionIDs(),
        target,
        options
    )
end

function Commands.ExecuteProvider(provider, target, map)
    if not provider or type(provider.execute) ~= "function" then return false end
    local ok
    local result
    ok, result = pcall(
        provider.execute,
        Commands.Selection,
        target,
        map,
        provider
    )
    if not ok then
        Commands.HandleResult({
            ok = false,
            commandID = provider.id,
            reason = "client_provider_failed",
        })
        if Core and Core.LogWarn then
            Core.LogWarn(
                "PNC map command provider failed id="
                    .. tostring(provider.id)
                    .. " error=" .. tostring(result)
            )
        end
        return false
    end
    return result ~= false
end

local function isProviderVisible(provider, target, map)
    if provider.enabled == false then return false end
    if type(provider.isVisible) ~= "function" then return true end
    local ok
    local visible
    ok, visible = pcall(
        provider.isVisible,
        Commands.Selection,
        target,
        map
    )
    return ok and visible ~= false
end

local function getProviderAvailability(provider, target, map)
    if type(provider.canExecute) ~= "function" then return true end
    local ok
    local allowed
    local reason
    ok, allowed, reason = pcall(
        provider.canExecute,
        Commands.Selection,
        target,
        map
    )
    if not ok then return false, "provider check failed" end
    return allowed ~= false, reason
end

local function getProviderLabel(provider, target, map)
    if type(provider.label) ~= "function" then
        return tostring(provider.label or provider.id)
    end
    local ok
    local label
    ok, label = pcall(
        provider.label,
        Commands.Selection,
        target,
        map
    )
    return ok and tostring(label) or tostring(provider.id)
end

local function populateProvider(submenu, provider, target, map)
    local allowed, reason = getProviderAvailability(
        provider,
        target,
        map
    )
    if type(provider.populate) == "function" then
        local ok
        local providerError
        ok, providerError = pcall(
            provider.populate,
            submenu,
            Commands.Selection,
            target,
            map,
            allowed,
            reason
        )
        if not ok and Core and Core.LogWarn then
            Core.LogWarn(
                "PNC map command menu provider failed id="
                    .. tostring(provider.id)
                    .. " error=" .. tostring(providerError)
            )
        end
        return
    end

    local label = getProviderLabel(provider, target, map)
    local providerForOption = provider
    local option = submenu:addOption(
        label,
        Commands,
        function()
            Commands.ExecuteProvider(providerForOption, target, map)
        end
    )
    option.notAvailable = allowed ~= true
    if option.notAvailable and reason then
        option.name = label .. " (" .. tostring(reason) .. ")"
    end
end

function Commands.BuildContext(map, x, y, target)
    local playerNum = tonumber(map and map.playerNum) or 0
    local context = ISContextMenu.get(
        playerNum,
        x + map:getAbsoluteX(),
        y + map:getAbsoluteY()
    )
    local root = context:addOption(
        "NPC Commands — " .. selectionLabel()
    )
    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(root, submenu)
    local i
    local provider

    for i = 1, #Commands.Ordered do
        provider = Commands.Ordered[i]
        if isProviderVisible(provider, target, map) then
            populateProvider(submenu, provider, target, map)
        end
    end
    return context
end

function Commands.OpenForSelection(raw, centerX, centerY, zoom)
    if Commands.SetSelection(raw) <= 0 then return false end
    local first = Commands.Selection[1]
    centerX = tonumber(centerX) or first.x
    centerY = tonumber(centerY) or first.y
    if not ISWorldMap or not ISWorldMap.ShowWorldMap then return false end
    ISWorldMap.ShowWorldMap(0, centerX, centerY, tonumber(zoom) or 15)
    local map = ISWorldMap_instance or ISWorldMap.instance
    if not map then
        Commands.ClearSelection()
        return false
    end
    map._pncCommandMode = true
    -- The normal single-player map may pause simulation. Command mode is a
    -- live tactical/debug view, so journeys must keep advancing while open.
    if ISWorldMap.shouldPause and ISWorldMap.shouldPause()
        and getGameSpeed and getGameSpeed() == 0
        and setGameSpeed
    then
        setGameSpeed(1)
    end
    return true
end

function Commands.OpenForNPC(snapshot)
    return Commands.OpenForSelection(
        snapshot,
        snapshot and snapshot.x,
        snapshot and snapshot.y,
        15
    )
end

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
