PNC = PNC or {}
PNC.API = PNC.API or {}
PNC.API.Internal = PNC.API.Internal or {}

local API = PNC.API
local Internal = API.Internal
local Core = PNC.Core
local Registry = PNC.Registry
local Presence = PNC.Presence
local Equipment = PNC.Equipment
local Health = PNC.Health
local Inventory = PNC.Inventory
local Network = PNC.Network

local function handlePresence(record, npcId, command)
    if command == "force_live" then
        record.runtime.forceLive = true
        record.runtime.forceAbstract = false
        Presence.Materialize(record, "debug_force_live")
        return true, true
    end
    if command == "force_abstract" then
        record.runtime.forceAbstract = true
        record.runtime.forceLive = false
        Presence.Abstract(record, "debug_force_abstract")
        return true, true
    end
    return false
end

local function handleHealth(record, npcId, command, args)
    local zombie
    if command == "heal" then
        zombie = Registry.GetLiveZombie(npcId)
        Health.Recover(record, zombie)
        Network.BroadcastRecord(record, "heal")
        return true, true
    end
    if command == "revive" then
        zombie = Registry.GetLiveZombie(npcId)
        if Health.CanRevive and not Health.CanRevive(record) then
            return true, false
        end
        Health.Revive(record, zombie)
        Network.BroadcastRecord(record, "bandaged_all")
        return true, true
    end
    if command == "damage" then
        return true, API.ApplyDamage(npcId, {
            amount = tonumber(args and args.amount or 10) or 10,
            type = "debug",
        })
    end
    if command == "damage_part" then
        return true, API.ApplyDebugWound(npcId, args or {})
    end
    if command == "infection" then
        return true, API.ApplyDebugInfection(npcId, args or {})
    end
    if command == "clear_infection" then
        return true, API.ClearKnoxInfection(
            npcId,
            "debug_infection_cleared"
        )
    end
    if command == "bandage_almost_dirty" then
        return true, API.DebugBandageAlmostDirty(
            npcId,
            args and args.partId
        )
    end
    return false
end

local function runAnimationCommand(record, zombie, command, args)
    if command == "animation_scene_play" then
        return PNC.AnimationSceneDebug.Play(record, zombie, args and args.sceneId, {
            durationMs = args and args.durationMs,
            reason = "debug_scene_command",
        })
    end
    if command == "animation_scene_pool_step" then
        return PNC.AnimationSceneDebug.PlayPoolOnce(
            record,
            zombie,
            args and args.pool,
            { reason = "debug_scene_pool_step" }
        )
    end
    if command == "animation_scene_pool_start" then
        return PNC.AnimationSceneDebug.StartPoolCycle(
            record,
            zombie,
            args and args.pool,
            { gapMs = args and args.gapMs }
        )
    end
    return PNC.AnimationSceneDebug.Stop(
        record,
        zombie,
        "debug_scene_command_stop"
    )
end

local function handleAnimation(record, npcId, command, args)
    local supported = command == "animation_scene_play"
        or command == "animation_scene_pool_step"
        or command == "animation_scene_pool_start"
        or command == "animation_scene_stop"
    local applied
    local reason
    if not supported then return false end
    applied, reason = runAnimationCommand(
        record,
        Registry.GetLiveZombie(npcId),
        command,
        args
    )
    Network.BroadcastRecord(record, "animation_scene_debug")
    return true, applied, reason
end

local function handleMap(record, npcId, command, args)
    if command == "set_map_presentation" then
        return true, API.MapPresentation.Set(npcId, args or {}) ~= nil
    end
    if command == "set_map_known" then
        return true, API.MapPresentation.SetKnown(
            npcId,
            args and args.playerKey,
            args and args.known == true
        ) ~= nil
    end
    return false
end

local function syncWeaponMode(record)
    record.weaponMode = record.equipment
        and record.equipment.primaryFullType
        and Equipment.ResolveWeaponMode(record.equipment.primaryFullType)
        or "melee"
end

local function syncAndApplyEquipment(record, reason, scope)
    if Inventory and Inventory.SyncFromEquipment then
        Inventory.SyncFromEquipment(record, reason)
    end
    syncWeaponMode(record)
    return Internal.ApplyLiveEquipment(record, "equipment", scope)
end

local function setEquipmentSlot(record, args)
    local slotKind = tostring(args and args.slotKind or "")
    local slotName = tostring(args and args.slotName or "")
    local itemType = args and args.fullType or nil
    if itemType ~= nil and tostring(itemType) == "" then itemType = nil end
    if slotKind == "primary" then
        Equipment.SetPrimary(record, itemType)
    elseif slotKind == "secondary" then
        Equipment.SetSecondary(record, itemType)
    elseif slotKind == "attached" and slotName ~= "" then
        Equipment.SetAttached(record, slotName, itemType)
    elseif slotKind == "worn" and slotName ~= "" then
        Equipment.SetWorn(record, slotName, itemType)
    else
        return false
    end
    return true
end

local function handleEquipment(record, npcId, command, args)
    local copied
    local reason
    local applied
    if command == "set_weapon_mode" then
        record.weaponMode = tostring(
            args and args.weaponMode or record.weaponMode or "melee"
        )
        Internal.RefreshEquipmentRuntime(record)
        Registry.MarkDirty(record, "equipment")
        Network.BroadcastRecord(record, "weapon_mode")
        return true, true
    end
    if command == "copy_held_weapon" then
        local fullType = args and args.weaponFullType or nil
        Core.LogRecordDebug(record, "NPC " .. tostring(npcId)
            .. " copy_held_weapon requested fullType=" .. tostring(fullType))
        Equipment.SetPrimary(record, fullType)
        syncAndApplyEquipment(record, "copy_held_weapon", "hands")
        return true, true
    end
    if command == "copy_player_loadout" then
        copied, reason = Equipment.CopyCharacterLoadout(
            record,
            args and args.sourcePlayer or nil
        )
        Core.LogRecordDebug(record, "NPC " .. tostring(npcId)
            .. " copy_player_loadout copied=" .. tostring(copied)
            .. " reason=" .. tostring(reason))
        if not copied then return true, false end
        applied = syncAndApplyEquipment(record, "copy_player_loadout")
        return true, applied ~= false
    end
    if command == "set_equipment_slot" then
        if not setEquipmentSlot(record, args) then return true, false end
        applied = syncAndApplyEquipment(record, "debug_equipment_slot")
        Registry.MarkDirty(record, "equipment")
        Network.BroadcastRecord(record, "equipment")
        return true, applied ~= false
    end
    if command == "clear_equipment" then
        applied = API.SetLoadout(npcId, { worn = {}, attached = {} })
        if applied then
            Registry.MarkDirty(record, "equipment")
            Network.BroadcastRecord(record, "equipment")
        end
        return true, applied
    end
    return false
end

local function handleDebugToggle(record, _, command)
    if command ~= "toggle_debug" then return false end
    record.runtime = record.runtime or {}
    record.runtime.debug = record.runtime.debug ~= true
    Core.LogInfo("record_debug npc=" .. tostring(record.id)
        .. " name=" .. tostring(record.name or "Unknown NPC")
        .. " enabled=" .. tostring(record.runtime.debug == true))
    Network.BroadcastRecord(record, "debug_toggle")
    return true, true
end

local HANDLERS = {
    handlePresence,
    handleHealth,
    handleAnimation,
    handleMap,
    handleEquipment,
    handleDebugToggle,
}

function API.DebugCommand(npcId, command, args)
    local record = Registry.Get(npcId)
    local handled
    local result
    local reason
    local i
    if not record then return false end
    for i = 1, #HANDLERS do
        handled, result, reason = HANDLERS[i](record, npcId, command, args)
        if handled then return result, reason end
    end
    return false
end
