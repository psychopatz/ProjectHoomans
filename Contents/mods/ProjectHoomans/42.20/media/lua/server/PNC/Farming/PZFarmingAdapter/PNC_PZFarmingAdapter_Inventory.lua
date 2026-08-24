-- Native and compact farming-material discovery.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PZFarmingAdapter = PNC.PZFarmingAdapter or {}
local Adapter = PNC.PZFarmingAdapter
local Internal = Adapter.Internal
local call = Internal.Call

local function visitNativeInventory(container, visitor, visited)
    if not container or (visited and visited[container]) then return nil end
    visited = visited or {}
    visited[container] = true
    local items = call(container, "getItems")
    if not items or not items.size or not items.get then return nil end
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local value = visitor(item, container)
        if value ~= nil then return value end
        local nested = call(item, "getItemContainer")
        value = visitNativeInventory(nested, visitor, visited)
        if value ~= nil then return value end
    end
    return nil
end

local function nativeBody(record, body)
    return body or PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record and record.id) or nil
end

function Adapter.FindSeed(record, body, entry)
    body = nativeBody(record, body)
    if body and PNC.Inventory and PNC.Inventory.CaptureLooseInventory then
        PNC.Inventory.CaptureLooseInventory(record, body)
    end
    local inv = PNC.Inventory and PNC.Inventory.EnsureRecordInventory
        and PNC.Inventory.EnsureRecordInventory(record) or nil
    for id, item in pairs(inv and inv.items or {}) do
        for _, seedType in ipairs(entry and entry.seedTypes or {}) do
            if tostring(item.type or "") == tostring(seedType)
                and (tonumber(item.stack) or 0) > 0
            then
                return tostring(id), item
            end
        end
    end
    return nil, "SEED_MATERIAL_MISSING"
end

local function isWaterNative(item)
    if not item then return false end
    if call(item, "isWaterSource") == true then return true end
    local container = call(item, "getFluidContainer")
    if not container or call(container, "isEmpty") == true then return false end
    local primary = call(container, "getPrimaryFluid")
    local fluidType = tostring(call(primary, "getFluidTypeString") or "")
    return (fluidType == "Water" or fluidType == "TaintedWater")
        and (tonumber(call(container, "getAmount")) or 0) > 0
end

Adapter.IsWaterItem = isWaterNative

function Adapter.FindWater(record, body)
    body = nativeBody(record, body)
    local inventory = body and call(body, "getInventory") or nil
    return visitNativeInventory(inventory, function(item, container)
        if isWaterNative(item) then return { item = item, container = container } end
    end)
end

local function farmingSkill(body)
    if not body or not body.getPerkLevel or not Perks or not Perks.Farming then return 0 end
    return tonumber(call(body, "getPerkLevel", Perks.Farming)) or 0
end

Internal.VisitNativeInventory = visitNativeInventory
Internal.NativeBody = nativeBody
Internal.IsWaterNative = isWaterNative
Internal.FarmingSkill = farmingSkill

return Adapter
