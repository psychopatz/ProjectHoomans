local Controller = require "PNC/Scavenge/PNC_ScavengeController"

PNC = PNC or {}
PNC.ContextHub = PNC.ContextHub or {}

local ContextHub = PNC.ContextHub
local Commands = PNC.CompanionCommands
local Provider = { id = "scavenge" }

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function target(entry)
    return entry and (entry.record or entry.snapshot) or nil
end

local function followsPlayer(record, player)
    if not record or not player then return false end
    if record.followingCurrentPlayer ~= nil then
        return record.followingCurrentPlayer == true
    end
    local order = record.orderSpec or {}
    if tostring(order.kind or "")
        ~= tostring(PNC.Const.ORDER_FOLLOW or "follow")
    then return false end
    local ownerOnlineID = tonumber(order.ownerOnlineID or record.ownerOnlineID)
    local playerOnlineID = player.getOnlineID
        and tonumber(player:getOnlineID()) or nil
    if ownerOnlineID ~= nil and playerOnlineID ~= nil then
        return ownerOnlineID == playerOnlineID
    end
    local ownerUsername = tostring(
        order.ownerUsername or record.ownerUsername or "")
    local username = player.getUsername
        and tostring(player:getUsername() or "") or ""
    return username ~= "" and ownerUsername == username
end

function Provider.isEnabled(entry, player)
    local record = target(entry)
    local commandable = Commands and Commands.CanPlayerCommand
        and Commands.CanPlayerCommand(record, player,
            PNC.Const.COMPANION_COMMAND_RADIUS) == true
    return commandable and (followsPlayer(record, player)
        or Controller.IsAssigned(entry and entry.id))
end

function Provider.addOptions(menu, entry)
    local scavengingMenu = ISContextMenu:getNew(menu)
    local root = menu:addOption(tr(
        "UI_PNC_Scavenge_Context", "Scavenging"))
    menu:addSubMenu(root, scavengingMenu)

    local assigned = Controller.IsAssigned(entry.id)
    local toggle = scavengingMenu:addOption(assigned and tr(
        "UI_PNC_Scavenge_Remove", "Remove Scavenger") or tr(
        "UI_PNC_Scavenge_Assign", "Assign Scavenger"), nil, function()
            Controller.ToggleAssigned(entry.id)
        end)
    ContextHub.ApplyOptionPresentation(toggle, {
        color = assigned and "bad" or "good",
    })

    scavengingMenu:addOption(tr(
        "UI_PNC_Scavenge_Open", "Open Scavenging UI"), nil, function()
            Controller.Open(entry.id, {
                name = entry.name or entry.displayName or entry.id,
            })
        end)
end

ContextHub.RegisterProvider(Provider)

return Provider
