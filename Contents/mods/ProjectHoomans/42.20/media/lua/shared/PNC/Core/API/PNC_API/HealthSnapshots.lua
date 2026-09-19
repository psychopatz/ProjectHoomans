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

function API.ApplyDamage(npcId, damageEvent)
    local record = Registry.Get(npcId)
    local zombie
    local applied
    if not Core or not Core.IsAuthority or not Core.IsAuthority() then
        return false, "not_authority"
    end
    if not record then
        return false
    end
    zombie = Registry.GetLiveZombie(npcId)
    applied = Health.ApplyDamage(record, zombie, damageEvent or {})
    if not applied then
        return false, "damage_rejected"
    end
    Network.BroadcastRecord(record, "damage")
    if record.alive == false then
        Network.BroadcastRemoval(record.id, "death")
    end
    return true
end

function API.ApplyDebugWound(npcId, args)
    local record = Registry.Get(npcId)
    local zombie
    local applied
    local result
    if not Core or type(Core.IsAuthority) ~= "function"
        or Core.IsAuthority() ~= true
    then
        return false, "not_authority"
    end
    if not record or not PNC.NPCWounds or not PNC.NPCWounds.ApplyDebugWound then
        return false
    end
    zombie = Registry.GetLiveZombie(npcId)
    applied, result = PNC.NPCWounds.ApplyDebugWound(
        record,
        zombie,
        args and args.partId,
        args and args.woundType,
        args and args.amount
    )
    if not applied then
        return false
    end
    Network.BroadcastRecord(record, "debug_wound")
    if record.alive == false then
        Network.BroadcastRemoval(record.id, "death")
    end
    return true, result
end

function API.ApplyDebugInfection(npcId, args)
    local record = Registry.Get(npcId)
    local zombie
    local applied
    local result
    if not Core or type(Core.IsAuthority) ~= "function"
        or Core.IsAuthority() ~= true
    then
        return false, "not_authority"
    end
    if not record or not PNC.NPCWounds or not PNC.NPCWounds.ApplyDebugInfection then
        return false
    end
    zombie = Registry.GetLiveZombie(npcId)
    applied, result = PNC.NPCWounds.ApplyDebugInfection(
        record,
        zombie,
        args and args.partId,
        args and args.stage
    )
    if not applied then return false, result end
    Network.BroadcastRecord(record, "debug_infection")
    if record.alive == false then
        Network.BroadcastRemoval(record.id, "death")
    end
    return true, result
end

function API.ClearKnoxInfection(npcId, source)
    local record = Registry.Get(npcId)
    local cleared
    local reason
    if not record or not Core.IsAuthority()
        or not PNC.NPCWounds or not PNC.NPCWounds.ClearInfection
    then
        return false, "not_authority_or_missing"
    end
    cleared, reason = PNC.NPCWounds.ClearInfection(
        record,
        source or "knox_cured"
    )
    if not cleared then return false, reason end
    Network.BroadcastRecord(record, source or "knox_cured")
    return true, reason
end

function API.DebugBandageAlmostDirty(npcId, partId)
    local record = Registry.Get(npcId)
    local applied
    local reason
    if not record or not Core.IsAuthority()
        or not PNC.NPCWounds or not PNC.NPCWounds.DebugAlmostDirty
    then
        return false, "not_authority_or_missing"
    end
    applied, reason = PNC.NPCWounds.DebugAlmostDirty(record, partId)
    if not applied then return false, reason end
    Network.BroadcastRecord(record, "debug_bandage_almost_dirty")
    return true, reason
end

function API.GetSnapshot(npcId)
    local record = Registry.Get(npcId)
    if record then
        return Network.BuildSnapshot(record)
    end
    if PNC.Network and PNC.Network.ClientState and PNC.Network.ClientState.snapshots then
        return PNC.Network.ClientState.snapshots[npcId]
    end
    return nil
end

function API.GetCharacterPayload(npcId)
    local record = Registry.Get(npcId)
    if record and Network and Network.BuildCharacterPayload then
        return Network.BuildCharacterPayload(record)
    end
    if PNC.Network and PNC.Network.ClientState and PNC.Network.ClientState.characterPayloads then
        return PNC.Network.ClientState.characterPayloads[npcId]
    end
    return nil
end

function API.GetCharacterInventoryPayload(npcId)
    local record = Registry.Get(npcId)
    local networkState = PNC.Network and PNC.Network.ClientState or nil
    local cached = networkState and networkState.characterPayloads
        and networkState.characterPayloads[tostring(npcId)] or nil
    local cachedInventory = cached and cached.inventory or nil
    local inventoryPayload
    if cached and cached.inventoryFull == true
        and type(cachedInventory) == "table"
    then
        local liveInventory = record and record.inventory or nil
        local cachedRevision = tonumber(cachedInventory.revision
            or cachedInventory.summary
            and cachedInventory.summary.revision)
        local liveRevision = type(liveInventory) == "table"
            and tonumber(liveInventory.revision) or nil
        if not record or liveRevision ~= nil
            and cachedRevision == liveRevision
        then
            return {
                npcId = tostring(record and record.id or npcId),
                revision = record and record.presenceRevision
                    or cached.revision,
                inventory = cachedInventory,
                inventoryFull = true,
            }
        end
    end
    if record and Inventory and Inventory.BuildFullPayload then
        inventoryPayload = Inventory.BuildFullPayload(record)
        if not inventoryPayload then return nil end
        return {
            npcId = tostring(record.id or npcId),
            revision = record.presenceRevision,
            inventory = inventoryPayload,
            inventoryFull = true,
        }
    end
    if cached and cached.inventory and cached.inventoryFull == true then
        return {
            npcId = tostring(npcId),
            revision = cached.revision,
            inventory = cached.inventory,
            inventoryFull = true,
        }
    end
    return nil
end
