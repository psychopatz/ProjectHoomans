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
                displayName = Identity.GetName(source),
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
        return Commands.Selection[1].displayName
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



Commands._ProviderDeps = {
    finiteNumber = finiteNumber,
    mapPoint = mapPoint,
    regionStateBounds = regionStateBounds,
    selectionLabel = selectionLabel,
    finishRegionSelection = finishRegionSelection,
    isProviderVisible = isProviderVisible,
    populateProvider = populateProvider,
}

return Commands
