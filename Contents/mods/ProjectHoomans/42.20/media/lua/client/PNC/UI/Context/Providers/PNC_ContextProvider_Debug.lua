PNC = PNC or {}
PNC.ContextHub = PNC.ContextHub or {}

local ContextHub = PNC.ContextHub
local Const = PNC.Const
local ClientState = PNC.Network.ClientState

local Provider = {
    id = "debug",
}

local function tr(key, fallback)
    local value = getText and PNC.Translation.GetKey(key) or nil
    if not value or value == "" or value == key then
        return fallback
    end
    return value
end

function Provider.isEnabled()
    return PNC.Client and PNC.Client.CanUseDebug and PNC.Client.CanUseDebug() == true
end

local function sendDebug(action, payload)
    if Provider.isEnabled() and PNC.Client.SendDebug then
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
    if not Provider.isEnabled() then
        return
    end
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

    menu:addOption(tr("UI_PNC_Debug_ForceLive", "Force Live"), nil, function()
        sendDebug("force_live", { id = entry.id })
    end)
    menu:addOption(tr("UI_PNC_Debug_ForceAbstract", "Force Abstract"), nil, function()
        sendDebug("force_abstract", { id = entry.id })
    end)
    menu:addOption(tr("UI_PNC_Debug_Heal", "Heal"), nil, function()
        sendDebug("heal", { id = entry.id })
    end)
    menu:addOption(tr("UI_PNC_Debug_Damage25", "Damage 25"), nil, function()
        sendDebug("damage", { id = entry.id, amount = 25 })
    end)
    menu:addOption(tr(isRecording(entry) and "UI_PNC_Debug_StopRecording"
        or "UI_PNC_Debug_RecordDebug",
        isRecording(entry) and "Stop Recording Debug" or "Record Debug"), nil, function()
        sendDebug("toggle_debug", { id = entry.id })
    end)
    menu:addOption(tr("UI_PNC_Debug_DumpSnapshot", "Dump Snapshot"), nil, function()
        local snapshotText
        snapshot = ClientState.snapshots and ClientState.snapshots[entry.id] or nil
        snapshotText = PNC.Nameplates and PNC.Nameplates.DebugDescribeSnapshot
            and PNC.Nameplates.DebugDescribeSnapshot(snapshot)
            or tostring(snapshot and snapshot.aiState or "No snapshot")
        print("[PNC] " .. snapshotText)
    end)
    menu:addOption(tr("UI_PNC_Debug_NPCPresentationLab", "NPC Presentation Lab"), nil, function()
        -- Keep the 511-node generated catalog and its UI out of the normal
        -- client startup path. Debuggers pay this load cost only on first use.
        if not PNC.NPCPresentationDebug
            or not PNC.NPCPresentationDebug.Open
        then
            require "PNC/UI/NPCPresentationDebug/PNC_NPCPresentationDebug"
        end
        if PNC.NPCPresentationDebug
            and PNC.NPCPresentationDebug.Open
        then
            PNC.NPCPresentationDebug.Open(entry)
        end
    end)
    menu:addOption(tr("UI_PNC_Debug_PlayerAnimationLab", "Player Animation Lab"), nil, function()
        -- The player debugger owns a separate timed-action preview and must not
        -- share the NPC presentation singleton or its selector state.
        if not PNC.PlayerAnimationDebugUI
            or not PNC.PlayerAnimationDebugUI.Open
        then
            require "PNC/UI/PNC_PlayerAnimationDebugWindow"
        end
        if PNC.PlayerAnimationDebugUI
            and PNC.PlayerAnimationDebugUI.Open
        then
            PNC.PlayerAnimationDebugUI.Open()
        end
    end)
    menu:addOption(tr("UI_PNC_Debug_AnimationSceneLab", "Animation Scene Lab"), nil, function()
        if not PNC.AnimationSceneDebugWindow then
            require "PNC/UI/PNC_AnimationSceneDebugWindow"
        end
        if PNC.AnimationSceneDebugWindow
            and PNC.AnimationSceneDebugWindow.Open
        then
            PNC.AnimationSceneDebugWindow.Open(entry)
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
        local status = treatmentMenu:addOption(
            tr("UI_PNC_Debug_NoBandagedWounds", "No bandaged wounds"), nil)
        status.notAvailable = true
    end

    orderMenu = ISContextMenu:getNew(menu)
    menu:addSubMenu(menu:addOption(tr("UI_PNC_Debug_Orders", "Orders")), orderMenu)
    orderMenu:addOption(tr("UI_PNC_Debug_FollowMe", "Follow Me"), nil, function()
        sendDebug("set_order", {
            id = entry.id,
            orderSpec = {
                kind = Const.ORDER_FOLLOW,
                ownerUsername = player and player:getUsername() or nil,
                ownerOnlineID = player and player:getOnlineID() or nil,
            },
        })
    end)
    orderMenu:addOption(tr("UI_PNC_Debug_GuardHere", "Guard Here"), nil, function()
        if not actionSquare then
            return
        end
        sendDebug("set_order", {
            id = entry.id,
            orderSpec = { kind = Const.ORDER_GUARD, x = actionSquare:getX(), y = actionSquare:getY(), z = actionSquare:getZ() },
        })
    end)
    orderMenu:addOption(tr("UI_PNC_Debug_PatrolNearby", "Patrol Nearby"), nil, function()
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
    orderMenu:addOption(tr("UI_PNC_Debug_HostileHunt", "Hostile Hunt"), nil, function()
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
    menu:addSubMenu(menu:addOption(tr("UI_PNC_Debug_Combat", "Combat")), weaponMenu)
    weaponMenu:addOption(tr("UI_PNC_Debug_SetMelee", "Set Melee"), nil, function()
        sendDebug("set_weapon_mode", { id = entry.id, weaponMode = "melee" })
    end)
    weaponMenu:addOption(tr("UI_PNC_Debug_SetRanged", "Set Ranged"), nil, function()
        sendDebug("set_weapon_mode", { id = entry.id, weaponMode = "ranged" })
    end)
    weaponMenu:addOption(tr("UI_PNC_Debug_SetMixed", "Set Mixed"), nil, function()
        sendDebug("set_weapon_mode", { id = entry.id, weaponMode = "mixed" })
    end)
    if heldItem and heldItem.getFullType then
        weaponMenu:addOption(tr("UI_PNC_Debug_UseHeldWeapon", "Use My Held Weapon"), nil, function()
            sendDebug("copy_held_weapon", { id = entry.id, weaponFullType = heldItem:getFullType() })
        end)
    end
    weaponMenu:addOption(tr("UI_PNC_Debug_UseFullLoadout", "Use My Full Loadout"), nil, function()
        sendDebug("copy_player_loadout", { id = entry.id })
    end)
end

ContextHub.RegisterProvider(Provider)
