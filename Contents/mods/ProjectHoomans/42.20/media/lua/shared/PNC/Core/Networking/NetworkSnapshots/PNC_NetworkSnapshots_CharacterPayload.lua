--[[
    PNC Network Snapshots - Character Payload
    Builds the character-detail wrapper around a full NPC snapshot.
]]

local Network = PNC.Network
local Core = PNC.Core
local Inventory = PNC.Inventory
local Skills = PNC.Skills
local Stamina = PNC.Stamina
local Parts = Network.Internal.SnapshotParts

function Network.BuildCharacterPayload(record)
    local inventoryPayload = Inventory and Inventory.BuildFullPayload and Inventory.BuildFullPayload(record) or nil
    local snapshot = Network.BuildSnapshot(record,
        inventoryPayload and inventoryPayload.summary or nil)
    return {
        npcId = record.id,
        revision = record.presenceRevision,
        snapshot = snapshot,
        health = Core.DeepCopy(record.health or {}),
        needs = Core.DeepCopy(snapshot.needs or {}),
        stamina = Stamina and Stamina.BuildSnapshot and Stamina.BuildSnapshot(record) or {},
        inventory = inventoryPayload,
        -- A full snapshot is authoritative even when its revision equals the
        -- client's cache. Equal revisions can still carry different item
        -- state after a reconnect or a stale UI cache.
        inventoryFull = true,
        equipment = Core.DeepCopy(record.equipment or {}),
        progression = {
            recruited = record.recruited == true,
            skillLevels = Skills and Skills.BuildSnapshot and Skills.BuildSnapshot(record) or {},
            skillXP = Core.DeepCopy(record.progression and record.progression.skillXP or {}),
        },
    }
end

return Network
