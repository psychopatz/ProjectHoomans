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
    Commands.LastTarget = nil
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

local function renderCommandStatus(map)
    if not Commands.Active or not map then return end
    local label = "Commanding " .. selectionLabel()
        .. " — right-click a destination"
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
    local originalRightMouseDown = ISWorldMap.onRightMouseDown
    local originalRightMouseUp = ISWorldMap.onRightMouseUp
    local originalClose = ISWorldMap.close
    function ISWorldMap:onRightMouseDown(x, y)
        if Commands.Active and #Commands.Selection > 0 then
            return true
        end
        return originalRightMouseDown(self, x, y)
    end
    function ISWorldMap:onRightMouseUp(x, y)
        if Commands.Active and #Commands.Selection > 0 then
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
        return originalClose(self)
    end
end

return Commands
