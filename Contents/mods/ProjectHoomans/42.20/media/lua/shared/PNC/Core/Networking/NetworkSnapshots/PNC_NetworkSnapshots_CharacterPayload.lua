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
local buildIdentitySummary = Parts.BuildIdentitySummary

function Network.BuildCharacterPayload(record)
    local snapshot = Network.BuildSnapshot(record)
    local inventoryPayload = Inventory and Inventory.BuildFullPayload and Inventory.BuildFullPayload(record) or nil
    local identity = buildIdentitySummary(record)
    return {
        npcId = record.id,
        revision = record.presenceRevision,
        snapshot = snapshot,
        identity = identity,
        health = Core.DeepCopy(record.health or {}),
        needs = Core.DeepCopy(snapshot.needs or {}),
        stamina = Stamina and Stamina.BuildSnapshot and Stamina.BuildSnapshot(record) or {},
        inventory = inventoryPayload,
        equipment = Core.DeepCopy(record.equipment or {}),
        progression = {
            recruited = record.recruited == true,
            skillLevels = Skills and Skills.BuildSnapshot and Skills.BuildSnapshot(record) or {},
            skillXP = Core.DeepCopy(record.progression and record.progression.skillXP or {}),
        },
    }
end

return Network
