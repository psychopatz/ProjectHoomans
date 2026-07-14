-- Server-authoritative treatment actions for individual NPC body parts.

PNC = PNC or {}
PNC.Treatment = PNC.Treatment or {}

local Treatment = PNC.Treatment
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry

local function targetPosition(record)
    local body = record and Registry.GetLiveZombie(record.id) or nil
    return body and body:getX() or tonumber(record and record.x) or 0,
        body and body:getY() or tonumber(record and record.y) or 0,
        body and body:getZ() or tonumber(record and record.z) or 0
end

local function isPlayerInRange(player, record)
    local x
    local y
    local z
    if not player or not record then return false end
    x, y, z = targetPosition(record)
    if math.abs((tonumber(player:getZ()) or 0) - z) >= 1 then return false end
    return Core.DistanceSq(player:getX(), player:getY(), x, y)
        <= ((tonumber(Const.BANDAGE_RANGE) or 3) ^ 2)
end

local function findBandage(player)
    local inventory = player and player.getInventory and player:getInventory() or nil
    local types = type(Const.BANDAGE_TYPES) == "table" and Const.BANDAGE_TYPES
        or { Const.BANDAGE_TYPE or "Base.Bandage" }
    local i
    local found
    local item
    local container
    for i = 1, #types do
        found = inventory and inventory.getAllTypeRecurse and inventory:getAllTypeRecurse(types[i]) or nil
        item = found and found.size and found:size() > 0 and found:get(0) or nil
        container = item and item.getContainer and item:getContainer() or nil
        if item and container then return item, container end
    end
    return nil, nil
end

function Treatment.CountBandages(player)
    local inventory = player and player.getInventory and player:getInventory() or nil
    if not inventory or not inventory.getItemCount then return 0 end
    local types = type(Const.BANDAGE_TYPES) == "table" and Const.BANDAGE_TYPES
        or { Const.BANDAGE_TYPE or "Base.Bandage" }
    local count = 0
    local i
    for i = 1, #types do
        count = count + (tonumber(inventory:getItemCount(types[i], true)) or 0)
    end
    return count
end

function Treatment.TryBandage(player, npcId, partId)
    local record = npcId and Registry.Get(npcId) or nil
    local item
    local container
    local applied
    local reason
    if not Core.IsAuthority() then return false, "not_authority" end
    if not player or (player.isDead and player:isDead()) then return false, "invalid_player" end
    if not record or record.alive == false then return false, "npc_missing" end
    if not PNC.NPCWounds or not PNC.NPCWounds.Bandage then return false, "wounds_unavailable" end
    if not isPlayerInRange(player, record) then return false, "too_far" end
    item, container = findBandage(player)
    if not item then return false, "missing_bandage" end
    applied, reason = PNC.NPCWounds.Bandage(record, partId, Core.Now())
    if not applied then return false, reason end
    container:Remove(item)
    if sendRemoveItemFromContainer then sendRemoveItemFromContainer(container, item) end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = "bandaged"
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(record, "bandaged")
    end
    return true, "bandaged"
end

return Treatment
