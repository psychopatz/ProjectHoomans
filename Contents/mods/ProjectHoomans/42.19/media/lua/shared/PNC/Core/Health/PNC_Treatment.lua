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

local function bandageTypes()
    return type(Const.BANDAGE_TYPES) == "table" and Const.BANDAGE_TYPES
        or { Const.BANDAGE_TYPE or "Base.Bandage" }
end

local function isBandageType(fullType)
    local types = bandageTypes()
    local i
    if not fullType then return true end
    for i = 1, #types do
        if tostring(types[i]) == tostring(fullType) then return true end
    end
    return false
end

local function findBandage(player, requestedType)
    local inventory = player and player.getInventory and player:getInventory() or nil
    local types = requestedType and { requestedType } or bandageTypes()
    local i
    local found
    local item
    local container
    if not isBandageType(requestedType) then return nil, nil end
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
    local types = bandageTypes()
    local count = 0
    local i
    for i = 1, #types do
        count = count + (tonumber(inventory:getItemCount(types[i], true)) or 0)
    end
    return count
end

function Treatment.ListBandages(player)
    local inventory = player and player.getInventory and player:getInventory() or nil
    local output = {}
    local types = bandageTypes()
    local i
    for i = 1, #types do
        local found = inventory and inventory.getAllTypeRecurse and inventory:getAllTypeRecurse(types[i]) or nil
        local count = found and found.size and tonumber(found:size()) or 0
        local item = count > 0 and found:get(0) or nil
        if count > 0 then
            output[#output + 1] = {
                fullType = types[i],
                count = count,
                item = item,
                name = item and item.getDisplayName and item:getDisplayName()
                    or item and item.getName and item:getName() or tostring(types[i]),
            }
        end
    end
    return output
end

function Treatment.TryBandage(player, npcId, partId, options)
    options = type(options) == "table" and options or {}
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
    if options.consumeItem ~= false then
        item, container = findBandage(player, options.bandageType)
        if not item then return false, "missing_bandage" end
    end
    applied, reason = PNC.NPCWounds.Bandage(record, partId, Core.Now())
    if not applied then return false, reason end
    if options.consumeItem ~= false then
        container:Remove(item)
        if sendRemoveItemFromContainer then sendRemoveItemFromContainer(container, item) end
    end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = "bandaged"
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(record, "bandaged")
    end
    return true, options.consumeItem == false and "bandaged_debug" or "bandaged"
end

return Treatment
