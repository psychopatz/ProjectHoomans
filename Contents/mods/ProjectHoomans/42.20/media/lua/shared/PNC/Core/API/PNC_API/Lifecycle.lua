PNC = PNC or {}
PNC.API = PNC.API or {}

local API = PNC.API
API.Internal = API.Internal or {}

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

local function hasAnyEntries(map)
    local _
    for _, _ in pairs(map or {}) do
        return true
    end
    return false
end

local function hasExplicitEquipment(equipment)
    return equipment
        and (
            equipment.primaryFullType ~= nil
            or equipment.secondaryFullType ~= nil
            or hasAnyEntries(equipment.worn)
            or hasAnyEntries(equipment.attached)
        )
end

function Internal.RefreshEquipmentRuntime(record)
    local equipmentInfo
    equipmentInfo = Equipment.Describe(record)
    record.runtime.combatModeResolved = equipmentInfo.combatModeResolved
    record.runtime.weaponStatus = equipmentInfo.weaponStatus
    return equipmentInfo
end

function Internal.ApplyLiveEquipment(record, reason, scope)
    local zombie = Registry.GetLiveZombie(record.id)
    local applied = true
    local applyReason = "no_live_body"
    if zombie then
        if scope ~= "hands" and PNC.Visuals and PNC.Visuals.ApplyHumanVisuals then
            PNC.Visuals.ApplyHumanVisuals(zombie, record)
        end
        if scope == "hands" and Equipment.ApplyHands then
            applied, applyReason = Equipment.ApplyHands(zombie, record)
        else
            applied, applyReason = Equipment.Apply(zombie, record)
        end
        Core.LogRecordDebug(record, "NPC " .. tostring(record.id) .. " equipment apply live=" .. tostring(applied) .. " reason=" .. tostring(applyReason))
    else
        Core.LogRecordDebug(record, "NPC " .. tostring(record.id) .. " has no live body during equipment update; stored for later materialize")
    end
    Internal.RefreshEquipmentRuntime(record)
    Network.BroadcastRecord(record, reason or "equipment")
    return applied, applyReason
end

local function finalizeNewRecord(record, definition)
    if Inventory then
        if definition.inventory and Inventory.Deserialize then
            Inventory.Deserialize(record, definition.inventory)
        elseif hasExplicitEquipment(definition.equipment) and Inventory.SyncFromEquipment then
            Inventory.SyncFromEquipment(record, "spawn_definition_equipment")
        elseif Inventory.EnsureRecordInventory then
            Inventory.EnsureRecordInventory(record)
        end
    end
    OrderSystem.SetOrder(record, definition.orderSpec)
    OrderSystem.SetHostility(record, definition.hostility or Types.DefaultHostility(definition.tacticalClass))
    Registry.AddRecord(record)
    if definition.factionID
        and PNC.Factions
        and PNC.Factions.AddNPC
    then
        local assigned, reason = PNC.Factions.AddNPC(
            definition.factionID,
            record.id,
            {
                membershipStatus = definition.membershipStatus,
                role = definition.factionRole,
                rank = definition.factionRank,
                joinedAt = definition.factionJoinedAt,
            }
        )
        if not assigned then
            Core.LogWarn(
                "PNC organizational faction assignment rejected id="
                    .. tostring(record.id)
                    .. " factionID="
                    .. tostring(definition.factionID)
                    .. " reason=" .. tostring(reason)
            )
        end
    end
    if definition.forceLive == true then
        record.runtime.forceLive = true
        local materialized, materializeReason = Presence.Materialize(record, "force_live_spawn")
        if not materialized then
            record.runtime.lifecycle = record.runtime.lifecycle or {}
            record.runtime.lifecycle.lastError = tostring(materializeReason or "materialize_failed")
            Core.LogWarn("PNC spawn materialization failed id=" .. tostring(record.id)
                .. " tacticalClass=" .. tostring(record.tacticalClass) .. " reason=" .. tostring(materializeReason))
        else
            Core.LogInfo("PNC spawned id=" .. tostring(record.id) .. " tacticalClass=" .. tostring(record.tacticalClass)
                .. " presence=" .. tostring(record.presenceState))
        end
    end
    Network.BroadcastRecord(record, "spawn")
    return record
end

function API.Spawn(definition)
    local def
    local record
    if not Core.IsAuthority() then
        return nil
    end
    def = Types.NormalizeDefinition(definition)
    record = Types.NewRecord(def)
    return finalizeNewRecord(record, def)
end

function API.Despawn(npcId)
    local record = Registry.Get(npcId)
    if not Core.IsAuthority() or not record then
        return false
    end
    Presence.Abstract(record, "despawn")
    Registry.RemoveRecord(npcId)
    Network.BroadcastRemoval(npcId, "despawn")
    return true
end

function API.SetOrder(npcId, orderSpec)
    local record = Registry.Get(npcId)
    if not record then
        return false
    end
    OrderSystem.SetOrder(record, orderSpec)
    Network.BroadcastRecord(record, "order")
    return true
end

function API.SetHostility(npcId, modeSpec)
    local record = Registry.Get(npcId)
    if not record then
        return false
    end
    OrderSystem.SetHostility(record, modeSpec or {})
    Network.BroadcastRecord(record, "hostility")
    return true
end

function API.SetLoadout(npcId, equipmentSpec)
    local record = Registry.Get(npcId)
    if not record then
        return false
    end
    Equipment.SetLoadout(record, equipmentSpec)
    if Inventory and Inventory.SyncFromEquipment then
        Inventory.SyncFromEquipment(record, "set_loadout")
    end
    if record.equipment and record.equipment.primaryFullType then
        record.weaponMode = Equipment.ResolveWeaponMode(record.equipment.primaryFullType)
    else
        record.weaponMode = "melee"
    end
    Internal.ApplyLiveEquipment(record, "equipment")
    return true
end
