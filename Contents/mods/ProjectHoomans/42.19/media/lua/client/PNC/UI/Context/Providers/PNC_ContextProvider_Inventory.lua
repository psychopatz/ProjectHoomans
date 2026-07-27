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

local function canManageCompanion(entry, player)
    return Commands and Commands.CanPlayerCommand
        and Commands.CanPlayerCommand(
            target(entry),
            player,
            tonumber(PNC.Const.INVENTORY_INTERACTION_RADIUS) or 3
        ) == true
end

local function isOwnedCompanion(entry, player)
    local record = target(entry)
    if Commands and Commands.IsCompanion and Commands.IsOwnedByPlayer then
        return Commands.IsCompanion(record) == true
            and Commands.IsOwnedByPlayer(record, player) == true
    end
    return canManageCompanion(entry, player)
end

local function canDebug()
    return PNC.Client and PNC.Client.CanUseDebug
        and PNC.Client.CanUseDebug() == true
end

function Provider.isEnabled(entry, player)
    return isOwnedCompanion(entry, player)
        or canManageCompanion(entry, player)
        or canDebug()
end

function Provider.addOptions(menu, entry, player)
    local owned = isOwnedCompanion(entry, player)
    local debugAuthorized = canDebug()
    if owned or debugAuthorized then
        menu:addOption(
            tr("UI_PNC_Character_View", "View Character"),
            nil,
            function()
                if PNC.CharacterWindow and PNC.CharacterWindow.Toggle then
                    PNC.CharacterWindow.Toggle(entry.id)
                end
            end
        )
    end
    if canManageCompanion(entry, player) or debugAuthorized then
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
end

PNC.ContextHub.RegisterProvider(Provider)

return Provider
