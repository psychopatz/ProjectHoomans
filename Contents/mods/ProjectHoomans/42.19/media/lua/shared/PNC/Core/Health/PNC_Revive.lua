-- Server-authoritative player interaction for reviving incapacitated NPCs.

PNC = PNC or {}
PNC.Revive = PNC.Revive or {}

local Revive = PNC.Revive
local Const = PNC.Const
local Core = PNC.Core
local Registry = PNC.Registry
local Health = PNC.Health
local Network = PNC.Network

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
    if not player or not record then
        return false
    end
    x, y, z = targetPosition(record)
    if math.abs((tonumber(player:getZ()) or 0) - z) >= 1 then
        return false
    end
    return Core.DistanceSq(player:getX(), player:getY(), x, y)
        <= (Const.REVIVE_RANGE * Const.REVIVE_RANGE)
end

local function collectBandages(player)
    local inventory = player and player.getInventory and player:getInventory() or nil
    local found = inventory and inventory.getAllTypeRecurse
        and inventory:getAllTypeRecurse(Const.REVIVE_BANDAGE_TYPE) or nil
    local selected = {}
    local item
    local container
    local i
    if not found or found:size() < Const.REVIVE_BANDAGE_COUNT then
        return nil
    end
    for i = 0, Const.REVIVE_BANDAGE_COUNT - 1 do
        item = found:get(i)
        container = item and item.getContainer and item:getContainer() or nil
        if not item or not container then
            return nil
        end
        selected[#selected + 1] = { item = item, container = container }
    end
    return selected
end

local function consumeBandages(selected)
    local i
    local entry
    for i = 1, #selected do
        entry = selected[i]
        entry.container:Remove(entry.item)
        if sendRemoveItemFromContainer then
            sendRemoveItemFromContainer(entry.container, entry.item)
        end
    end
end

function Revive.CountBandages(player)
    local inventory = player and player.getInventory and player:getInventory() or nil
    if not inventory or not inventory.getItemCount then
        return 0
    end
    return tonumber(inventory:getItemCount(Const.REVIVE_BANDAGE_TYPE, true)) or 0
end

function Revive.Try(player, npcId)
    local record = npcId and Registry.Get(npcId) or nil
    local selected
    local zombie
    if not Core.IsAuthority() then
        return false, "not_authority"
    end
    if not player or (player.isDead and player:isDead()) then
        return false, "invalid_player"
    end
    if not record then
        return false, "npc_missing"
    end
    if not Health.CanRevive(record) then
        return false, "not_incapacitated"
    end
    if not isPlayerInRange(player, record) then
        return false, "too_far"
    end
    selected = collectBandages(player)
    if not selected then
        return false, "missing_bandages"
    end

    consumeBandages(selected)
    zombie = Registry.GetLiveZombie(record.id)
    Health.Revive(record, zombie)
    Network.BroadcastRecord(record, "revive")
    return true, "revived"
end
