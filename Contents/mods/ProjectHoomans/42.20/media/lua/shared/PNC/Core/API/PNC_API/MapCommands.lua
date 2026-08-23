PNC = PNC or {}
PNC.API = PNC.API or {}
PNC.API.Internal = PNC.API.Internal or {}

local API = PNC.API
local Internal = API.Internal
local Core = PNC.Core
local Types = PNC.Types
local Registry = PNC.Registry
local OrderSystem = PNC.OrderSystem
local Presence = PNC.Presence
local Equipment = PNC.Equipment
local Health = PNC.Health
local Inventory = PNC.Inventory
local Network = PNC.Network

function API.MapCommands.RegisterHandler(id, definition)
    return PNC.MapCommandService.RegisterHandler(id, definition)
end

function API.MapCommands.UnregisterHandler(id)
    return PNC.MapCommandService.UnregisterHandler(id)
end

function API.MapCommands.RegisterProvider(id, definition)
    if not PNC.MapCommands or not PNC.MapCommands.RegisterProvider then
        return false
    end
    return PNC.MapCommands.RegisterProvider(id, definition)
end

function API.MapCommands.UnregisterProvider(id)
    if not PNC.MapCommands or not PNC.MapCommands.UnregisterProvider then
        return false
    end
    return PNC.MapCommands.UnregisterProvider(id)
end

function API.MapCommands.OpenForSelection(selection, centerX, centerY, zoom)
    if not PNC.MapCommands or not PNC.MapCommands.OpenForSelection then
        return false
    end
    return PNC.MapCommands.OpenForSelection(
        selection,
        centerX,
        centerY,
        zoom
    )
end
