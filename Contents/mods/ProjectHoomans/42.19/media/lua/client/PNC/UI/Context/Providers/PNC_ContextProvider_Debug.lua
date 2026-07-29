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
    local infectionMenu
    local treatmentMenu

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
    menu:addOption("Dump Snapshot", nil, function()
        local snapshotText
        snapshot = ClientState.snapshots and ClientState.snapshots[entry.id] or nil
        snapshotText = PNC.Nameplates and PNC.Nameplates.DebugDescribeSnapshot
            and PNC.Nameplates.DebugDescribeSnapshot(snapshot)
            or tostring(snapshot and snapshot.aiState or "No snapshot")
        print("[PNC] " .. snapshotText)
    end)
    menu:addOption("Animation Debug Player", nil, function()
        -- Keep the 511-node generated catalog and its UI out of the normal
        -- client startup path. Debuggers pay this load cost only on first use.
        if not PNC.AnimationDebugWindow then
            require "PNC/UI/PNC_AnimationDebugWindow"
        end
        if PNC.AnimationDebugWindow
            and PNC.AnimationDebugWindow.Open
        then
            PNC.AnimationDebugWindow.Open(entry)
        end
    end)

    snapshot = ClientState.snapshots and ClientState.snapshots[entry.id] or nil
    if snapshot and snapshot.healthState == "incapacitated" and snapshot.canRevive == true then
        menu:addOption(tr("UI_PNC_DebugBandageAll", "Debug Bandage All (Free)"), nil, function()
            sendDebug("revive", { id = entry.id })
        end)
    end

    infectionMenu = ISContextMenu:getNew(menu)
    menu:addSubMenu(menu:addOption(tr("UI_PNC_DebugInfection", "Infection")), infectionMenu)
    infectionMenu:addOption(tr("UI_PNC_DebugInfectionForce", "Force Infected Bite"), nil, function()
        sendDebug("infection", { id = entry.id, stage = "incubating" })
    end)
    infectionMenu:addOption(tr("UI_PNC_DebugInfectionFever", "Advance to Fever"), nil, function()
        sendDebug("infection", { id = entry.id, stage = "fever" })
    end)
    infectionMenu:addOption(tr("UI_PNC_DebugInfectionTerminal", "Advance to Terminal"), nil, function()
        sendDebug("infection", { id = entry.id, stage = "terminal" })
    end)
    infectionMenu:addOption(tr("UI_PNC_DebugInfectionFatal", "Trigger Infection Death"), nil, function()
        sendDebug("infection", { id = entry.id, stage = "fatal" })
    end)
    local infection = snapshot and snapshot.bodyHealth
        and snapshot.bodyHealth.infection or nil
    local infected = infection
        and (infection.active == true
            or infection.fatal == true
            or infection.pendingFatal == true)
    local clearInfection = infectionMenu:addOption(
        tr("UI_PNC_DebugInfectionClear", "Clear Knox Infection"),
        nil,
        function()
            sendDebug("clear_infection", { id = entry.id })
        end
    )
    clearInfection.notAvailable = not infected

    treatmentMenu = ISContextMenu:getNew(menu)
    menu:addSubMenu(
        menu:addOption(tr("UI_PNC_DebugBandageState", "Bandage State")),
        treatmentMenu
    )
    local hasBandage = false
    for partId, wound in pairs(
        snapshot and snapshot.bodyHealth and snapshot.bodyHealth.wounds or {}
    ) do
        if wound and wound.bandaged == true then
            local selectedPartId = partId
            hasBandage = true
            local part = PNC.NPCWounds and PNC.NPCWounds.Parts
                and PNC.NPCWounds.Parts[partId] or nil
            local option = treatmentMenu:addOption(
                tr("UI_PNC_DebugBandageAlmostDirty", "Make Almost Dirty")
                    .. ": " .. tostring(part and part.label or partId),
                nil,
                function()
                    sendDebug("bandage_almost_dirty", {
                        id = entry.id,
                        partId = selectedPartId,
                    })
                end
            )
            option.notAvailable = wound.bandageDirty == true
        end
    end
    if not hasBandage then
        local status = treatmentMenu:addOption("No bandaged wounds", nil)
        status.notAvailable = true
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
