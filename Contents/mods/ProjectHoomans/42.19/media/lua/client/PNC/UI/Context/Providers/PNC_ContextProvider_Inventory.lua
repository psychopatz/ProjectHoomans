PNC = PNC or {}
PNC.ContextHub = PNC.ContextHub or {}

local Provider = { id = "inventory" }
local Commands = PNC.CompanionCommands

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function target(entry)
    return entry and (entry.record or entry.snapshot) or nil
end

function Provider.isEnabled(entry, player)
    return Commands and Commands.CanPlayerCommand
        and Commands.CanPlayerCommand(
            target(entry),
            player,
            tonumber(PNC.Const.INVENTORY_INTERACTION_RADIUS) or 3
        ) == true
end

function Provider.addOptions(menu, entry)
    menu:addOption(
        tr("UI_PNC_Inventory_Open", "Inventory"),
        nil,
        function()
            if PNC.InventoryWindow and PNC.InventoryWindow.Open then
                PNC.InventoryWindow.Open(entry.id)
            end
        end
    )
end

PNC.ContextHub.RegisterProvider(Provider)

return Provider
