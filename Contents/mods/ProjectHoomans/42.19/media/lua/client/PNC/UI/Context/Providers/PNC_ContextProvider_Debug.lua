PNC = PNC or {}
PNC.ContextHub = PNC.ContextHub or {}

local ContextHub = PNC.ContextHub
local Const = PNC.Const
local ClientState = PNC.Network.ClientState

local Provider = {
    id = "debug",
}

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == "" or value == key then
        return fallback
    end
    return value
end

function Provider.isEnabled()
    return PNC.Client and PNC.Client.CanUseDebug and PNC.Client.CanUseDebug() == true
end

local function sendDebug(action, payload)
    if PNC.Client and PNC.Client.SendDebug then
        PNC.Client.SendDebug(action, payload)
    end
end

local function isRecording(entry)
    local snapshot = entry and (entry.snapshot
        or (ClientState.snapshots and ClientState.snapshots[entry.id])) or nil
    return entry and entry.debugRecording == true
        or entry and entry.record and entry.record.runtime and entry.record.runtime.debug == true
        or snapshot and snapshot.debugState and snapshot.debugState.debugEnabled == true
        or false
end

function Provider.addOptions(menu, entry, player, contextData)
    local debugMenu = ISContextMenu:getNew(menu)
    local snapshot
    local actionSquare = entry.zombie and entry.zombie.getSquare and entry.zombie:getSquare() or contextData and contextData.square or nil
    local heldItem = player and player.getPrimaryHandItem and player:getPrimaryHandItem() or nil
    local orderMenu
    local weaponMenu

    menu:addSubMenu(menu:addOption(tr("UI_PNC_Debug", "Debug")), debugMenu)
    menu = debugMenu

    menu:addOption("Force Live", nil, function()
        sendDebug("force_live", { id = entry.id })
    end)
    menu:addOption("Force Abstract", nil, function()
        sendDebug("force_abstract", { id = entry.id })
    end)
    menu:addOption("Heal", nil, function()
        sendDebug("heal", { id = entry.id })
    end)
    menu:addOption("Damage 25", nil, function()
        sendDebug("damage", { id = entry.id, amount = 25 })
    end)
    menu:addOption(isRecording(entry) and "Stop Recording Debug" or "Record Debug", nil, function()
        sendDebug("toggle_debug", { id = entry.id })
    end)
    menu:addOption("View Character", nil, function()
        if PNC.CharacterWindow and PNC.CharacterWindow.Toggle then
            PNC.CharacterWindow.Toggle(entry.id)
        end
    end)
    menu:addOption("Dump Snapshot", nil, function()
        local snapshotText
        snapshot = ClientState.snapshots and ClientState.snapshots[entry.id] or nil
        snapshotText = PNC.Nameplates and PNC.Nameplates.DebugDescribeSnapshot
            and PNC.Nameplates.DebugDescribeSnapshot(snapshot)
            or tostring(snapshot and snapshot.aiState or "No snapshot")
        print("[PNC] " .. snapshotText)
    end)

    snapshot = ClientState.snapshots and ClientState.snapshots[entry.id] or nil
    if snapshot and snapshot.healthState == "incapacitated" and snapshot.canRevive == true then
        menu:addOption(tr("UI_PNC_DebugRevive", "Debug Revive (Free)"), nil, function()
            sendDebug("revive", { id = entry.id })
        end)
    end

    orderMenu = ISContextMenu:getNew(menu)
    menu:addSubMenu(menu:addOption("Orders"), orderMenu)
    orderMenu:addOption("Follow Me", nil, function()
        sendDebug("set_order", {
            id = entry.id,
            orderSpec = {
                kind = Const.ORDER_FOLLOW,
                ownerUsername = player and player:getUsername() or nil,
                ownerOnlineID = player and player:getOnlineID() or nil,
            },
        })
    end)
    orderMenu:addOption("Guard Here", nil, function()
        if not actionSquare then
            return
        end
        sendDebug("set_order", {
            id = entry.id,
            orderSpec = { kind = Const.ORDER_GUARD, x = actionSquare:getX(), y = actionSquare:getY(), z = actionSquare:getZ() },
        })
    end)
    orderMenu:addOption("Patrol Nearby", nil, function()
        if not actionSquare then
            return
        end
        sendDebug("set_order", {
            id = entry.id,
            orderSpec = {
                kind = Const.ORDER_PATROL,
                points = {
                    { x = actionSquare:getX(), y = actionSquare:getY(), z = actionSquare:getZ() },
                    { x = actionSquare:getX() + 4, y = actionSquare:getY(), z = actionSquare:getZ() },
                },
            },
        })
    end)
    orderMenu:addOption(tr("UI_PNC_OrderRoamNearby", "Roam Nearby"), nil, function()
        if not actionSquare then
            return
        end
        sendDebug("set_order", {
            id = entry.id,
            orderSpec = {
                kind = Const.ORDER_ROAM,
                roamMode = Const.ROAM_MODE_AREA,
                x = actionSquare:getX(),
                y = actionSquare:getY(),
                z = actionSquare:getZ(),
                radius = Const.ROAM_DEFAULT_RADIUS,
                targetRadius = Const.ROAM_TARGET_RADIUS,
            },
        })
    end)
    orderMenu:addOption("Hostile Hunt", nil, function()
        if not actionSquare then
            return
        end
        sendDebug("set_order", {
            id = entry.id,
            orderSpec = { kind = Const.ORDER_HOSTILE_HUNT, x = actionSquare:getX(), y = actionSquare:getY(), z = actionSquare:getZ() },
        })
        sendDebug("set_hostility", {
            id = entry.id,
            modeSpec = { mode = "hostile_any_player", attackPlayers = true, attackNPCs = true },
        })
    end)

    weaponMenu = ISContextMenu:getNew(menu)
    menu:addSubMenu(menu:addOption("Combat"), weaponMenu)
    weaponMenu:addOption("Set Melee", nil, function()
        sendDebug("set_weapon_mode", { id = entry.id, weaponMode = "melee" })
    end)
    weaponMenu:addOption("Set Ranged", nil, function()
        sendDebug("set_weapon_mode", { id = entry.id, weaponMode = "ranged" })
    end)
    weaponMenu:addOption("Set Mixed", nil, function()
        sendDebug("set_weapon_mode", { id = entry.id, weaponMode = "mixed" })
    end)
    if heldItem and heldItem.getFullType then
        weaponMenu:addOption("Use My Held Weapon", nil, function()
            sendDebug("copy_held_weapon", { id = entry.id, weaponFullType = heldItem:getFullType() })
        end)
    end
    weaponMenu:addOption("Use My Full Loadout", nil, function()
        sendDebug("copy_player_loadout", { id = entry.id })
    end)
end

ContextHub.RegisterProvider(Provider)
