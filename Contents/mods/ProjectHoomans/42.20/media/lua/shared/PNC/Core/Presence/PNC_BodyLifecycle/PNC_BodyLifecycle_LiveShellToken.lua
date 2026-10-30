-- Exact restart identity for live managed NPC shells.
--
-- IsoZombie ModData and persistent outfit/population identity can disappear
-- across PZ save/population restore. InventoryItem ModData is serialized by
-- the engine, so each authoritative live shell carries one lifecycle-only
-- Base.IDcard token containing the durable PNC NPC id. The token is never part
-- of logical NPC inventory and is stripped before corpse conversion.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}

local Lifecycle = PNC.BodyLifecycle
local Core = PNC.Core
local TOKEN_TYPE = "Base.IDcard"
local TOKEN_VERSION = 1
local MAX_SCAN = 256

local function itemFullType(item)
    if item and item.getFullType then
        local ok, value = pcall(item.getFullType, item)
        if ok and value then return tostring(value) end
    end
    return tostring(item and (item.fullType or item.type) or "")
end

local function itemData(item)
    if not item or not item.getModData then return nil end
    local ok, data = pcall(item.getModData, item)
    return ok and type(data) == "table" and data or nil
end

function Lifecycle.IsLiveShellIdentityToken(item)
    local data = itemData(item)
    return itemFullType(item) == TOKEN_TYPE
        and data ~= nil
        and data.PNC_LiveShellToken == true
end

local function tokenNPCId(item)
    local data = itemData(item)
    if not Lifecycle.IsLiveShellIdentityToken(item)
        or tonumber(data.PNC_LiveShellTokenVersion) ~= TOKEN_VERSION
    then
        return nil
    end
    local value = tostring(data.PNC_LiveShellTokenNPCId or "")
    return value ~= "" and value or nil
end

local function inventoryOf(body)
    return body and body.getInventory and body:getInventory() or nil
end

function Lifecycle.GetLiveShellTokenNPCId(body)
    local container = inventoryOf(body)
    local items = container and container.getItems and container:getItems() or nil
    local size
    local first
    local found
    if not items or not items.size or not items.get then
        return nil, "token_inventory_unavailable"
    end
    size = math.max(0, tonumber(items:size()) or 0)
    first = math.max(0, size - MAX_SCAN)
    for index = size - 1, first, -1 do
        local npcId = tokenNPCId(items:get(index))
        if npcId then
            if found and found ~= npcId then
                return nil, "ambiguous_live_shell_tokens"
            end
            found = npcId
        end
    end
    return found, found and "live_shell_token" or "live_shell_token_missing"
end

local function stampToken(item, record)
    local data
    if not item or not record or not item.getModData then return false end
    data = item:getModData()
    if type(data) ~= "table" then return false end
    data.PNC_LiveShellToken = true
    data.PNC_LiveShellTokenVersion = TOKEN_VERSION
    data.PNC_LiveShellTokenNPCId = tostring(record.id or "")
    data.PNC_LiveShellTokenNPCName = tostring(
        record.name or record.displayName or "Unknown NPC"
    )
    data.PNC_LiveShellLifecycleOnly = true
    if item.setName then
        pcall(item.setName, item, "PNC Live Shell Token")
    end
    return data.PNC_LiveShellTokenNPCId ~= ""
end

function Lifecycle.EnsureLiveShellIdentityToken(record, body)
    local container
    local items
    local keep
    local stale = {}
    local item
    if not record or not record.id or not body then
        return nil, false, "invalid_live_shell_token_target"
    end
    if Core and Core.IsAuthority and Core.IsAuthority() ~= true then
        return nil, false, "not_authority"
    end
    container = inventoryOf(body)
    items = container and container.getItems and container:getItems() or nil
    if not container or not items or not items.size or not items.get then
        return nil, false, "token_inventory_unavailable"
    end

    for index = 0, items:size() - 1 do
        local candidate = items:get(index)
        if Lifecycle.IsLiveShellIdentityToken(candidate) then
            if not keep
                and tokenNPCId(candidate) == tostring(record.id)
            then
                keep = candidate
            else
                stale[#stale + 1] = candidate
            end
        end
    end
    if container.Remove then
        for index = 1, #stale do
            pcall(container.Remove, container, stale[index])
        end
    end

    if keep then
        stampToken(keep, record)
        return keep, false, "existing"
    end

    if PNC.Equipment and PNC.Equipment.CreateItem then
        item = PNC.Equipment.CreateItem(TOKEN_TYPE)
    elseif InventoryItemFactory and InventoryItemFactory.CreateItem then
        local ok, value = pcall(InventoryItemFactory.CreateItem, TOKEN_TYPE)
        if ok then item = value end
    end
    if not item or not stampToken(item, record) then
        return nil, false, "token_create_failed"
    end
    if not container.AddItem then
        return nil, false, "token_container_add_unavailable"
    end
    local ok, added = pcall(container.AddItem, container, item)
    if not ok or added == nil then
        return nil, false, "token_container_add_failed"
    end
    return item, true, "created"
end

Lifecycle.LiveShellTokenVersion = TOKEN_VERSION

return Lifecycle
